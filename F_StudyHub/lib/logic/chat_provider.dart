import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

import '../data/models/message_model.dart';
import '../data/services/websocket_service.dart';
import 'room_provider.dart';
import 'socket_provider.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoadingHistory = false,
    this.error,
    this.unreadCount = 0,
    this.typingUsers = const {},
  });

  final List<Message> messages;
  final bool isLoadingHistory;
  final String? error;
  final int unreadCount;

  /// Quién está escribiendo ahora (id -> nombre), sin contar al usuario local.
  final Map<String, String> typingUsers;

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoadingHistory,
    String? error,
    bool clearError = false,
    int? unreadCount,
    Map<String, String>? typingUsers,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._socketService, this._roomProvider)
      : super(const ChatState()) {
    _socketService.on('chat_history', (data) {
      final messages = (data as List)
          .map((item) => Message.fromJson(item as Map<String, dynamic>))
          .toList();
      _clearTypingTimers();
      state = ChatState(messages: messages);
    });

    _socketService.on('new_message', (data) {
      final message = Message.fromJson(data as Map<String, dynamic>);
      _removeTyping(message.senderId);
      state = state.copyWith(
        messages: [...state.messages, message],
        unreadCount: _isChatVisible ? 0 : state.unreadCount + 1,
      );
    });

    _socketService.on('message_reactions', (data) {
      final map = data as Map<String, dynamic>;
      final messageId = map['messageId'] as String;
      final reactions = Message.reactionsFromJson(map['reactions']);
      state = state.copyWith(
        messages: [
          for (final m in state.messages)
            m.id == messageId ? m.copyWith(reactions: reactions) : m,
        ],
      );
    });

    _socketService.on('user_typing', (data) {
      final map = data as Map<String, dynamic>;
      final userId = map['userId'] as String;
      if (userId == _senderId) return;
      if (map['isTyping'] == true) {
        _markTyping(userId, map['userName'] as String? ?? '');
      } else {
        _removeTyping(userId);
      }
    });
  }

  /// Si un "escribiendo" no se renueva en este tiempo se da por terminado:
  /// cubre a quien se desconecta o cierra la app sin avisar.
  static const Duration typingExpiry = Duration(seconds: 5);

  /// Cada cuánto se reenvía "estoy escribiendo" mientras se sigue tecleando.
  static const Duration typingResend = Duration(seconds: 3);

  final WebSocketService _socketService;
  final riverpod.Ref _roomProvider;
  bool _isChatVisible = false;
  final Map<String, Timer> _typingTimers = {};
  DateTime? _lastTypingSent;
  bool _typingSent = false;

  String? get _roomId => _roomProvider.read(roomProvider).room?.roomId;
  String? get _senderId =>
      _roomProvider.read(roomProvider).localUser?.id;

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearUnread() {
    state = state.copyWith(unreadCount: 0);
  }

  void setChatVisible(bool visible) {
    _isChatVisible = visible;
    if (visible) state = state.copyWith(unreadCount: 0);
  }

  void sendMessage(String text) {
    final roomId = _roomId;
    final senderId = _senderId;
    if (roomId == null || senderId == null) {
      state = state.copyWith(error: 'No se pudo enviar el mensaje. Verifica que estés conectado a una sala.');
      return;
    }
    if (text.trim().isEmpty) return;

    notifyTyping(false);
    _socketService.emit('send_message', {
      'roomId': roomId,
      'senderId': senderId,
      'text': text.trim(),
    });
  }

  void toggleReaction(String messageId, String emoji) {
    final roomId = _roomId;
    final userId = _senderId;
    if (roomId == null || userId == null) return;
    if (!kReactionEmojis.contains(emoji)) return;

    _socketService.emit('toggle_reaction', {
      'roomId': roomId,
      'messageId': messageId,
      'userId': userId,
      'emoji': emoji,
    });
  }

  /// Avisa a la sala que el usuario local escribe (o dejó de hacerlo). Se llama
  /// en cada cambio del campo: solo emite al empezar, cada [typingResend]
  /// mientras sigue y al parar.
  void notifyTyping(bool isTyping) {
    final roomId = _roomId;
    final userId = _senderId;
    if (roomId == null || userId == null) return;

    if (!isTyping) {
      if (!_typingSent) return;
      _typingSent = false;
      _lastTypingSent = null;
    } else {
      final last = _lastTypingSent;
      final now = DateTime.now();
      if (_typingSent && last != null && now.difference(last) < typingResend) {
        return;
      }
      _typingSent = true;
      _lastTypingSent = now;
    }

    _socketService.emit('typing', {
      'roomId': roomId,
      'userId': userId,
      'isTyping': isTyping,
    });
  }

  void _markTyping(String userId, String name) {
    _typingTimers[userId]?.cancel();
    _typingTimers[userId] = Timer(typingExpiry, () => _removeTyping(userId));
    if (state.typingUsers[userId] == name) return;
    state = state.copyWith(typingUsers: {...state.typingUsers, userId: name});
  }

  void _removeTyping(String userId) {
    _typingTimers.remove(userId)?.cancel();
    if (!state.typingUsers.containsKey(userId)) return;
    state = state.copyWith(
      typingUsers: {...state.typingUsers}..remove(userId),
    );
  }

  void _clearTypingTimers() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
  }

  @override
  void dispose() {
    _clearTypingTimers();
    super.dispose();
  }

  void requestHistory(String roomId) {
    state = state.copyWith(isLoadingHistory: true, clearError: true);
    _socketService.emit('get_chat_history', {'roomId': roomId});
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    ref.watch(socketServiceProvider),
    ref,
  );
});
