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
  });

  final List<Message> messages;
  final bool isLoadingHistory;
  final String? error;
  final int unreadCount;

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoadingHistory,
    String? error,
    bool clearError = false,
    int? unreadCount,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: clearError ? null : (error ?? this.error),
      unreadCount: unreadCount ?? this.unreadCount,
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
      state = ChatState(messages: messages);
    });

    _socketService.on('new_message', (data) {
      final message = Message.fromJson(data as Map<String, dynamic>);
      state = state.copyWith(
        messages: [...state.messages, message],
        unreadCount: state.unreadCount + 1,
      );
    });
  }

  final WebSocketService _socketService;
  final riverpod.Ref _roomProvider;

  String? get _roomId => _roomProvider.read(roomProvider).room?.roomId;
  String? get _senderId =>
      _roomProvider.read(roomProvider).localUser?.id;

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearUnread() {
    state = state.copyWith(unreadCount: 0);
  }

  void sendMessage(String text) {
    final roomId = _roomId;
    final senderId = _senderId;
    if (roomId == null || senderId == null) {
      state = state.copyWith(error: 'No se pudo enviar el mensaje. Verifica que estés conectado a una sala.');
      return;
    }
    if (text.trim().isEmpty) return;

    _socketService.emit('send_message', {
      'roomId': roomId,
      'senderId': senderId,
      'text': text.trim(),
    });
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
