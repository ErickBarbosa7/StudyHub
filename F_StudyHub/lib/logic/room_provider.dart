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
    this.sessionEnded = false,
    this.error,
  });

  final Room? room;
  final User? localUser;
  final List<User> users;
  final bool isCreating;
  final bool isRestoring;

  /// Marca que la sesión fue terminada (conexión perdida sin recuperarse).
  final bool sessionEnded;
  final String? error;

  RoomState copyWith({
    Room? room,
    User? localUser,
    List<User>? users,
    bool? isCreating,
    bool? isRestoring,
    bool? sessionEnded,
    String? error,
    bool clearError = false,
  }) {
    return RoomState(
      room: room ?? this.room,
      localUser: localUser ?? this.localUser,
      users: users ?? this.users,
      isCreating: isCreating ?? this.isCreating,
      isRestoring: isRestoring ?? this.isRestoring,
      sessionEnded: sessionEnded ?? this.sessionEnded,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Tiempo máximo de vida de una sesión guardada antes de considerarla expirada.
const Duration _sessionTtl = Duration(hours: 6);

/// Maceta elegida a mano. Vive en el dispositivo y viaja con el `join_room`, así
/// que el servidor no necesita guardarla.
const String _kAvatarSeedPref = 'avatar_seed';

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
  
  // Clean up "Exception: " prefix and pass through backend error messages
  final stringError = error.toString();
  if (stringError.startsWith('Exception: ')) {
    return stringError.substring(11);
  }
  
  return stringError;
}

class RoomNotifier extends StateNotifier<RoomState> {
  RoomNotifier(this._ref, this._apiService, this._socketService)
    : super(const RoomState()) {
    _socketService.on('room_users_update', (data) {
      final users = (data as List)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
      // La lista viene con la seed de todos, incluida la nuestra. Sin copiarla
      // al local, el usuario local nunca vería su propio avatar.
      final localId = state.localUser?.id;
      User? local;
      for (final user in users) {
        if (user.id == localId) {
          local = user;
          break;
        }
      }
      state = state.copyWith(users: users, localUser: local);
    });

    _socketService.on('host_transferred', (data) {
      final newHostId =
          (data as Map<String, dynamic>)['newHostId'] as String;
      final room = state.room;
      if (room == null) return;
      state = state.copyWith(room: room.copyWith(hostId: newHostId));
      debugPrint('[room] Nuevo dueño de la sala: $newHostId');
    });

    _socketService.on('kicked', (_) {
      debugPrint('[room] Expulsado de la sala');
      _clearSession();
      state = const RoomState();
    });

    _socketService.on('room_not_found', (_) {
      debugPrint('[room] La sala ya no existe en el servidor');
      endSession(message: 'La sala ya no existe o ha expirado.');
    });

    _socketService.addOnGaveUp(() {
      debugPrint('[room] Conexión perdida sin recuperarse');
      if (state.room != null || state.localUser != null) {
        endSession();
      }
    });

    _socketService.addOnConnected(_rejoinRoomIfNeeded);
  }

  bool _isSessionExpired(SharedPreferences prefs) {
    final savedAt = prefs.getInt('session_saved_at');
    if (savedAt == null) return false;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(savedAt),
    );
    return age > _sessionTtl;
  }

  Future<void> _rejoinRoomIfNeeded() async {
    final room = state.room;
    final user = state.localUser;
    if (room == null || user == null) return;

    final prefs = await _getPrefs();
    if (_isSessionExpired(prefs)) {
      debugPrint('[room] Sesión expirada, no se re-une a la sala');
      await _clearSession();
      state = const RoomState();
      return;
    }

    debugPrint('[room] Reconectado, re-uniéndose a ${room.roomId}');
    _joinRoom(room.roomId, user);
  }

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();

  Future<String?> _savedAvatarSeed() async {
    final prefs = await _getPrefs();
    return prefs.getString(_kAvatarSeedPref);
  }

  Future<void> _saveSession(Room room, User user) async {
    final prefs = await _getPrefs();
    await prefs.setString('session_room_id', room.roomId);
    await prefs.setString('session_user_id', user.id);
    await prefs.setString('session_user_name', user.name);
    await prefs.setInt(
      'session_saved_at',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _clearSession() async {
    final prefs = await _getPrefs();
    await prefs.remove('session_room_id');
    await prefs.remove('session_user_id');
    await prefs.remove('session_user_name');
    await prefs.remove('session_saved_at');
  }

  Future<void> _resetRoomUiState() async {
    final prefs = await _getPrefs();
    await prefs.remove('pomodoro_expanded');
    await prefs.remove('tasks_expanded');
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Termina la sesión local: limpia el token guardado, resetea el estado y
  /// marca `sessionEnded` para que la UI vuelva al inicio.
  Future<void> endSession({
    String message = 'Se perdió la conexión. Tu sesión se cerró; vuelve a entrar cuando tengas señal.',
  }) async {
    debugPrint('[room] Finalizando sesión local');
    await _clearSession();
    state = RoomState(sessionEnded: true, error: message);
  }

  void clearSessionEnded() {
    state = state.copyWith(sessionEnded: false);
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

    // Si la sesión superó el TTL se mata el "token" y se vuelve al inicio.
    if (_isSessionExpired(prefs)) {
      debugPrint('[room] Sesión expirada (TTL), limpiando token');
      await _clearSession();
      return false;
    }

    if (state.room != null) {
      return true;
    }

    state = state.copyWith(isRestoring: true, clearError: true);
    try {
      final room = await _apiService.getRoom(roomId);
      final user = User(
        id: userId,
        name: userName,
        avatarSeed: prefs.getString(_kAvatarSeedPref),
      );
      await _resetRoomUiState();
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
      await _resetRoomUiState();
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
      await _resetRoomUiState();
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
    // La seed elegida a mano viaja al entrar: si en esa sala ya la tiene otra
    // persona, el servidor asigna otra y lo avisa con room_users_update.
    final seed = user.avatarSeed ?? await _savedAvatarSeed();
    _socketService.emit('join_room', {
      'roomId': roomId,
      'user': {
        'id': user.id,
        'name': user.name,
        'avatarSeed': ?seed,
      },
    });
    _ref.read(chatProvider.notifier).requestHistory(roomId);
  }

  /// Elige la maceta del avatar local. Devuelve el nombre de quien ya la tiene
  /// si está ocupada (y en ese caso no se emite nada), o `null` si se aplicó.
  Future<String?> setAvatarSeed(String seed) async {
    final room = state.room;
    final localUser = state.localUser;
    if (room == null || localUser == null) return null;
    if (localUser.avatarSeed == seed) return null;

    for (final user in state.users) {
      if (user.id != localUser.id && user.avatarSeed == seed) {
        return user.name;
      }
    }

    state = state.copyWith(localUser: localUser.copyWith(avatarSeed: seed));
    _socketService.emit('set_avatar', {
      'roomId': room.roomId,
      'userId': localUser.id,
      'avatarSeed': seed,
    });
    final prefs = await _getPrefs();
    await prefs.setString(_kAvatarSeedPref, seed);
    return null;
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
