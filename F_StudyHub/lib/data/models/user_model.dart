import 'dart:math';

class User {
  const User({required this.id, required this.name});

  factory User.generateLocal(String name) {
    final random = Random();
    final id = '${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999)}';
    return User(id: id, name: name);
  }

  final String id;
  final String name;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}