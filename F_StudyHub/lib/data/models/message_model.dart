class Message {
  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      text: json['text'] as String,
      timestamp: DateTime.tryParse(json['timestamp'] as String) ??
          DateTime.now(),
    );
  }

  bool isOwn(String userId) => senderId == userId;
}