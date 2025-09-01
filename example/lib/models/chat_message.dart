import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 0)
enum MessageType {
  @HiveField(0)
  text,
  @HiveField(1)
  image,
  @HiveField(2)
  file,
  @HiveField(3)
  audio,
  @HiveField(4)
  video,
  @HiveField(5)
  location,
  @HiveField(6)
  system,
  @HiveField(7)
  typing,
  @HiveField(8)
  readReceipt,
}

@HiveType(typeId: 1)
enum MessageStatus {
  @HiveField(0)
  sending,
  @HiveField(1)
  sent,
  @HiveField(2)
  delivered,
  @HiveField(3)
  read,
  @HiveField(4)
  failed,
}

@HiveType(typeId: 2)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String content;

  @HiveField(2)
  String senderId;

  @HiveField(3)
  String senderName;

  @HiveField(4)
  String senderAvatar;

  @HiveField(5)
  DateTime timestamp;

  @HiveField(6)
  MessageType type;

  @HiveField(7)
  String? roomId;

  @HiveField(8)
  bool isEdited;

  @HiveField(9)
  DateTime? editedAt;

  @HiveField(10)
  List<String> reactions;

  @HiveField(11)
  MessageStatus status;

  @HiveField(12)
  String? replyToMessageId;

  @HiveField(13)
  ChatMessage? replyToMessage;

  @HiveField(14)
  Map<String, dynamic> metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.timestamp,
    this.type = MessageType.text,
    this.roomId,
    this.isEdited = false,
    this.editedAt,
    List<String>? reactions,
    this.status = MessageStatus.sent,
    this.replyToMessageId,
    this.replyToMessage,
    Map<String, dynamic>? metadata,
  })  : reactions = reactions ?? [],
        metadata = metadata ?? {};

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderAvatar: json['senderAvatar'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      roomId: json['roomId'],
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      reactions: List<String>.from(json['reactions'] ?? []),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      replyToMessageId: json['replyToMessageId'],
      replyToMessage: json['replyToMessage'] != null 
          ? ChatMessage.fromJson(json['replyToMessage']) 
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'roomId': roomId,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'reactions': reactions,
      'status': status.toString().split('.').last,
      'replyToMessageId': replyToMessageId,
      'replyToMessage': replyToMessage?.toJson(),
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    DateTime? timestamp,
    MessageType? type,
    String? roomId,
    bool? isEdited,
    DateTime? editedAt,
    List<String>? reactions,
    MessageStatus? status,
    String? replyToMessageId,
    ChatMessage? replyToMessage,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, sender: $senderName, timestamp: $timestamp)';
  }
}
