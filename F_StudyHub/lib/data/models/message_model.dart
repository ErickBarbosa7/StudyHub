/// Reacciones rápidas permitidas, en el orden en que se muestran. El servidor
/// valida contra la misma lista (`ALLOWED_REACTIONS` en `chatHandler.ts`).
const List<String> kReactionEmojis = ['🚀', '🔥', '🍅'];

class Message {
  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.reactions = const {},
  });

  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  /// Emoji -> ids de quienes reaccionaron con él. Sin entradas vacías.
  final Map<String, List<String>> reactions;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      text: json['text'] as String,
      timestamp: (DateTime.tryParse(json['timestamp'] as String) ??
          DateTime.now()).toLocal(),
      reactions: reactionsFromJson(json['reactions']),
    );
  }

  /// Tolera servidores sin reacciones (campo ausente) y descarta emojis vacíos.
  static Map<String, List<String>> reactionsFromJson(Object? raw) {
    if (raw is! List) return const {};
    final result = <String, List<String>>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final emoji = item['emoji'];
      final userIds = item['userIds'];
      if (emoji is! String || userIds is! List || userIds.isEmpty) continue;
      result[emoji] = userIds.whereType<String>().toList(growable: false);
    }
    return result;
  }

  Message copyWith({Map<String, List<String>>? reactions}) {
    return Message(
      id: id,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: timestamp,
      reactions: reactions ?? this.reactions,
    );
  }

  bool isOwn(String userId) => senderId == userId;
}
