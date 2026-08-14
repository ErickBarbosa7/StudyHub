import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/legacy.dart' show StateNotifier, StateNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/room_model.dart';
import '../data/models/user_model.dart';
import '../data/services/api_service.dart';
import '../data/services/websocket_service.dart';
import 'chat_provider.dart';
import 'socket_provider.dart';

class RoomState {
  const RoomState({
    this.room,
    this.localUser,
    this.users = const [],
    this.isCreating = false,
    this.isRestoring = false,
  });

  final Room? room;
  final User? localUser;
  final List<User> users;
  final bool isCreating;
  final bool isRestoring;

  RoomState copyWith({
    Room? room,
    User? localUser,
    List<User>? users,
    bool? isCreating,
    bool? isRestoring,
  }) {
    return RoomState(
      room: room ?? this.room,
      localUser: localUser ?? this.localUser,
      users: users ?? this.users,
      isCreating: isCreating ?? this.isCreating,
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }
}

class RoomNotifier extends StateNotifier<RoomState> {
  RoomNotifier(this._ref, this._apiService, this._socketService)
      : super(const RoomState()) {
    _socketService.on('room_users_update', (data) {
      final users = (data as List)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
      state = state.copyWith(users: users);
    });

    _socketService.onConnected = _rejoinRoomIfNeeded;
  }

  void _rejoinRoomIfNeeded() {
    final room = state.room;
    final user = state.localUser;
    if (room == null || user == null) return;
    debugPrint('[room] Reconectado, re-uniéndose a ${room.roomId}');
    _joinRoom(room.roomId, user);
  }

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();

  Future<void> _saveSession(Room room, User user) async {
    final prefs = await _getPrefs();
    await prefs.setString('session_room_id', room.roomId);
    await prefs.setString('session_user_id', user.id);
    await prefs.setString('session_user_name', user.name);
  }

  Future<void> _clearSession() async {
    final prefs = await _getPrefs();
    await prefs.remove('session_room_id');
    await prefs.remove('session_user_id');
    await prefs.remove('session_user_name');
  }

  /// Restaura la sesión guardada tras recargar la página (F5).
  /// Devuelve true si había una sala y se logró volver a entrar.
  Future<bool> restoreSavedSession() async {
    final prefs = await _getPrefs();
    final roomId = prefs.getString('session_room_id');
    final userId = prefs.getString('session_user_id');
    final userName = prefs.getString('session_user_name');

    if (roomId == null || userId == null || userName == null) {
      return false;
    }

    if (state.room != null) {
      return true;
    }

    state = state.copyWith(isRestoring: true);
    try {
      final room = await _apiService.getRoom(roomId);
      final user = User(id: userId, name: userName);
      state = state.copyWith(room: room, localUser: user, isRestoring: false);
      if (_socketService.isConnected) {
        _joinRoom(room.roomId, user);
      }
      debugPrint('[room] Sesión restaurada en ${room.roomId}');
      return true;
    } catch (error) {
      debugPrint('[room] No se pudo restaurar la sesión: $error');
      await _clearSession();
      state = state.copyWith(isRestoring: false);
      return false;
    }
  }

  final riverpod.Ref _ref;
  final ApiService _apiService;
  final WebSocketService _socketService;

  Future<bool> createAndJoinRoom({
    required String roomName,
    required String userName,
  }) async {
    final user = User.generateLocal(userName);
    state = state.copyWith(localUser: user, isCreating: true);

    try {
      final room = await _apiService.createRoom(name: roomName, hostId: user.id);
      state = state.copyWith(room: room);
      await _saveSession(room, user);
      _joinRoom(room.roomId, user);
      return true;
    } catch (error) {
      debugPrint('[room] Error al crear la sala: $error');
      return false;
    } finally {
      state = state.copyWith(isCreating: false);
    }
  }

  void joinRoom(Room room, User user) {
    state = state.copyWith(room: room, localUser: user);
    _saveSession(room, user);
    _joinRoom(room.roomId, user);
  }

  Future<bool> joinRoomByCode({
    required String roomCode,
    required String userName,
  }) async {
    final user = User.generateLocal(userName);
    state = state.copyWith(localUser: user, isCreating: true);

    try {
      final room = await _apiService.getRoom(roomCode.trim());
      state = state.copyWith(room: room);
      await _saveSession(room, user);
      _joinRoom(room.roomId, user);
      return true;
    } catch (error) {
      debugPrint('[room] Error al unirse a la sala: $error');
      return false;
    } finally {
      state = state.copyWith(isCreating: false);
    }
  }

  void _joinRoom(String roomId, User user) {
    _ref.read(chatProvider);
    _socketService.emit('join_room', {
      'roomId': roomId,
      'user': {'id': user.id, 'name': user.name},
    });
    _ref.read(chatProvider.notifier).requestHistory(roomId);
  }

  void leaveRoom() {
    final room = state.room;
    final user = state.localUser;
    if (room != null && user != null) {
      _socketService.emit('leave_room', {
        'roomId': room.roomId,
        'userId': user.id,
      });
    }
    _clearSession();
    state = const RoomState();
  }
}

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  return RoomNotifier(
    ref,
    ref.watch(apiServiceProvider),
    ref.watch(socketServiceProvider),
  );
});

final apiServiceProvider = riverpod.Provider<ApiService>((_) => const ApiService());