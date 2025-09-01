import 'package:hive/hive.dart';
import 'chat_message.dart';

part 'chat_room.g.dart';

@HiveType(typeId: 5)
enum RoomType {
  @HiveField(0)
  public,
  @HiveField(1)
  private,
  @HiveField(2)
  direct,
}

@HiveType(typeId: 6)
class ChatRoom extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  RoomType type;

  @HiveField(4)
  List<String> members;

  @HiveField(5)
  List<String> admins;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime lastActivity;

  @HiveField(8)
  int messageCount;

  @HiveField(9)
  String? lastMessageId;

  @HiveField(10)
  ChatMessage? lastMessage;

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    this.type = RoomType.public,
    List<String>? members,
    List<String>? admins,
    required this.createdAt,
    required this.lastActivity,
    this.messageCount = 0,
    this.lastMessageId,
    this.lastMessage,
  })  : members = members ?? [],
        admins = admins ?? [];

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: RoomType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => RoomType.public,
      ),
      members: List<String>.from(json['members'] ?? []),
      admins: List<String>.from(json['admins'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActivity: DateTime.parse(json['lastActivity'] ?? DateTime.now().toIso8601String()),
      messageCount: json['messageCount'] ?? 0,
      lastMessageId: json['lastMessageId'],
      lastMessage: json['lastMessage'] != null 
          ? ChatMessage.fromJson(json['lastMessage']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'members': members,
      'admins': admins,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'messageCount': messageCount,
      'lastMessageId': lastMessageId,
      'lastMessage': lastMessage?.toJson(),
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    String? description,
    RoomType? type,
    List<String>? members,
    List<String>? admins,
    DateTime? createdAt,
    DateTime? lastActivity,
    int? messageCount,
    String? lastMessageId,
    ChatMessage? lastMessage,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      messageCount: messageCount ?? this.messageCount,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  bool get isMember => members.isNotEmpty;
  bool get isAdmin => admins.isNotEmpty;
  bool get isDirect => type == RoomType.direct;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatRoom && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatRoom(id: $id, name: $name, type: $type, members: ${members.length})';
  }
}
