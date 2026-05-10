class ConversationItem {
  final int userId;
  final String fullName;
  final String email;
  final int? lastMessageId;
  final String? lastMessageContent;
  final DateTime? lastMessageCreatedAt;
  final int? lastMessageSenderId;
  final int unreadCount;

  const ConversationItem({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.lastMessageId,
    required this.lastMessageContent,
    required this.lastMessageCreatedAt,
    required this.lastMessageSenderId,
    required this.unreadCount,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      userId: (json['userId'] as num).toInt(),
      fullName: (json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      lastMessageId: (json['lastMessageId'] as num?)?.toInt(),
      lastMessageContent: json['lastMessageContent'] as String?,
      lastMessageCreatedAt: json['lastMessageCreatedAt'] == null
          ? null
          : DateTime.parse(json['lastMessageCreatedAt'] as String),
      lastMessageSenderId: (json['lastMessageSenderId'] as num?)?.toInt(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
