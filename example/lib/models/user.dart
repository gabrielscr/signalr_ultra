import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 3)
enum UserStatus {
  @HiveField(0)
  online,
  @HiveField(1)
  away,
  @HiveField(2)
  busy,
  @HiveField(3)
  offline,
}

@HiveType(typeId: 4)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String avatar;

  @HiveField(4)
  UserStatus status;

  @HiveField(5)
  DateTime lastSeen;

  @HiveField(6)
  List<String> connectedRooms;

  @HiveField(7)
  Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    this.status = UserStatus.offline,
    required this.lastSeen,
    List<String>? connectedRooms,
    Map<String, dynamic>? preferences,
  })  : connectedRooms = connectedRooms ?? [],
        preferences = preferences ?? {};

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      status: UserStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => UserStatus.offline,
      ),
      lastSeen: DateTime.parse(json['lastSeen'] ?? DateTime.now().toIso8601String()),
      connectedRooms: List<String>.from(json['connectedRooms'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'status': status.toString().split('.').last,
      'lastSeen': lastSeen.toIso8601String(),
      'connectedRooms': connectedRooms,
      'preferences': preferences,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    UserStatus? status,
    DateTime? lastSeen,
    List<String>? connectedRooms,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      connectedRooms: connectedRooms ?? this.connectedRooms,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, status: $status)';
  }
}
