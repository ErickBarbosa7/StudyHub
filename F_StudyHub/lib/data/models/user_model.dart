import 'dart:math';

class User {
  const User({required this.id, required this.name, this.avatarSeed});

  factory User.generateLocal(String name) {
    final random = Random();
    final id = '${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999)}';
    return User(id: id, name: name);
  }

  final String id;
  final String name;

  /// Seed del avatar por defecto, asignada por el servidor para que nadie en la
  /// sala repita. Nula si el servidor no la envía (se dibujan las iniciales).
  final String? avatarSeed;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarSeed: json['avatarSeed'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (avatarSeed != null) 'avatarSeed': avatarSeed,
      };

  User copyWith({String? name, String? avatarSeed}) => User(
        id: id,
        name: name ?? this.name,
        avatarSeed: avatarSeed ?? this.avatarSeed,
      );
}
