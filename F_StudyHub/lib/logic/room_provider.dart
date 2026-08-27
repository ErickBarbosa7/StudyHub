import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
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
    this.error,
  });

  final Room? room;
  final User? localUser;
  final List<User> users;
  final bool isCreating;
  final bool isRestoring;
  final String? error;

  RoomState copyWith({
    Room? room,
    User? localUser,
    List<User>? users,
    bool? isCreating,
    bool? isRestoring,
    String? error,
    bool clearError = false,
  }) {
    return RoomState(
      room: room ?? this.room,
      localUser: localUser ?? this.localUser,
      users: users ?? this.users,
      isCreating: isCreating ?? this.isCreating,
      isRestoring: isRestoring ?? this.isRestoring,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

String _translateError(Object error) {
  final msg = error.toString().toLowerCase();
  if (msg.contains('socket') ||
      msg.contains('connection') ||
      msg.contains('network') ||
      msg.contains('failed to host') ||
      msg.contains('connecting')) {
    return 'No se pudo conectar al servidor. Verifica tu conexión a internet e intenta de nuevo.';
  }
  if (msg.contains('timeout')) {
    return 'La conexión está tardando demasiado. Verifica tu internet e intenta de nuevo.';
  }
  if (msg.contains('404') ||
      msg.contains('not found') ||
      msg.contains('no encontr')) {
    return 'Código no válido. No se encontró una sala con ese código. Verifica que esté bien escrito e intenta de nuevo.';
  }
  if (msg.contains('400') ||
      msg.contains('bad request') ||
      msg.contains('invalid')) {
    return 'Los datos enviados no son válidos. Revisa la información e intenta de nuevo.';
  }
  if (msg.contains('500') ||
      msg.contains('server') ||
      msg.contains('internal')) {
    return 'El servidor no está disponible en este momento. Intenta de nuevo en unos segundos.';
  }
  return 'Ocurrió un error inesperado. Intenta de nuevo.';
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

    _socketService.on('kicked', (_) {
      debugPrint('[room] Expulsado de la sala');
      _clearSession();
      state = const RoomState();
    });

    _socketService.addOnConnected(_rejoinRoomIfNeeded);
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

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> _ensureConnected() async {
    if (_socketService.isConnected) return;
    final ok = await _ref.read(socketStateProvider.notifier).ensureConnected();
    if (!ok && !_socketService.isConnected) {
      state = state.copyWith(
        error:
            'No se pudo conectar con el servidor. Verifica tu conexión a internet e inténtalo de nuevo.',
      );
    }
  }

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

    state = state.copyWith(isRestoring: true, clearError: true);
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
      state = state.copyWith(
        isRestoring: false,
        error:
            'No se pudo recuperar tu sesión anterior. Puedes crear o unirte a una sala nuevamente.',
      );
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
    state = state.copyWith(localUser: user, isCreating: true, clearError: true);

    try {
      final room = await _apiService.createRoom(
        name: roomName,
        hostId: user.id,
      );
      state = state.copyWith(room: room);
      await _saveSession(room, user);
      await _joinRoom(room.roomId, user);
      if (!_socketService.isConnected) {
        state = state.copyWith(isCreating: false);
        return false;
      }
      return true;
    } catch (error) {
      debugPrint('[room] Error al crear la sala: $error');
      state = state.copyWith(error: _translateError(error));
      return false;
    } finally {
      state = state.copyWith(isCreating: false);
    }
  }

  void joinRoom(Room room, User user) {
    state = state.copyWith(room: room, localUser: user, clearError: true);
    _saveSession(room, user);
    _joinRoom(room.roomId, user);
  }

  Future<bool> joinRoomByCode({
    required String roomCode,
    required String userName,
  }) async {
    final user = User.generateLocal(userName);
    state = state.copyWith(localUser: user, isCreating: true, clearError: true);

    try {
      final room = await _apiService.getRoom(roomCode.trim());
      state = state.copyWith(room: room);
      await _saveSession(room, user);
      await _joinRoom(room.roomId, user);
      if (!_socketService.isConnected) {
        state = state.copyWith(isCreating: false);
        return false;
      }
      return true;
    } catch (error) {
      debugPrint('[room] Error al unirse a la sala: $error');
      state = state.copyWith(error: _translateError(error));
      return false;
    } finally {
      state = state.copyWith(isCreating: false);
    }
  }

  Future<void> _joinRoom(String roomId, User user) async {
    await _ensureConnected();
    if (!_socketService.isConnected) return;
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

  void kickUser(String userId) {
    final room = state.room;
    final localUser = state.localUser;
    if (room == null || localUser == null) return;
    if (room.hostId != localUser.id) return;

    _socketService.emit('kick_user', {
      'roomId': room.roomId,
      'hostId': localUser.id,
      'userId': userId,
    });
  }
}

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) {
  return RoomNotifier(
    ref,
    ref.watch(apiServiceProvider),
    ref.watch(socketServiceProvider),
  );
});

final apiServiceProvider = riverpod.Provider<ApiService>(
  (_) => const ApiService(),
);
