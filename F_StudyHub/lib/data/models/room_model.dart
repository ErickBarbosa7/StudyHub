class Room {
  const Room({required this.roomId, required this.name, required this.hostId});

  final String roomId;
  final String name;
  final String hostId;

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['roomId'] as String,
      name: json['name'] as String,
      hostId: json['hostId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'name': name,
        'hostId': hostId,
      };

  Room copyWith({String? hostId}) {
    return Room(
      roomId: roomId,
      name: name,
      hostId: hostId ?? this.hostId,
    );
  }
}