class MessageItem {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime createdAt;
  final bool read;

  const MessageItem({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.read,
  });

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: (json['id'] as num).toInt(),
      senderId: (json['senderId'] as num).toInt(),
      receiverId: (json['receiverId'] as num).toInt(),
      content: (json['content'] ?? '') as String,
      createdAt: DateTime.parse((json['createdAt'] ?? DateTime.now().toUtc().toIso8601String()) as String),
      read: (json['read'] ?? false) as bool,
    );
  }
}
