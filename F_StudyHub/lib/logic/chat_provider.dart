import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;

import '../data/models/message_model.dart';
import '../data/services/websocket_service.dart';
import 'room_provider.dart';
import 'socket_provider.dart';

class ChatState {
  const ChatState({this.messages = const []});

  final List<Message> messages;

  ChatState copyWith({List<Message>? messages}) {
    return ChatState(messages: messages ?? this.messages);
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
      state = state.copyWith(messages: [...state.messages, message]);
    });
  }

  final WebSocketService _socketService;
  final riverpod.Ref _roomProvider;

  String? get _roomId => _roomProvider.read(roomProvider).room?.roomId;
  String? get _senderId =>
      _roomProvider.read(roomProvider).localUser?.id;

  void sendMessage(String text) {
    final roomId = _roomId;
    final senderId = _senderId;
    if (roomId == null || senderId == null || text.trim().isEmpty) return;

    _socketService.emit('send_message', {
      'roomId': roomId,
      'senderId': senderId,
      'text': text.trim(),
    });
  }

  void requestHistory(String roomId) {
    _socketService.emit('get_chat_history', {'roomId': roomId});
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    ref.watch(socketServiceProvider),
    ref,
  );
});