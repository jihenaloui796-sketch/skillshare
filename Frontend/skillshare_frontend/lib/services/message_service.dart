import '../models/conversation_item.dart';
import '../models/message_item.dart';
import 'api_client.dart';

class MessageService {
  final ApiClient _api;

  MessageService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<ConversationItem>> listConversations() async {
    final json = await _api.get('/messages/conversations');
    final raw = (json as List?) ?? const [];
    return raw.whereType<Map>().map((e) => ConversationItem.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<List<MessageItem>> conversationWith(int userId) async {
    final json = await _api.get('/messages/with/$userId');
    final raw = (json as List?) ?? const [];
    return raw.whereType<Map>().map((e) => MessageItem.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<MessageItem> send({required int receiverId, required String content}) async {
    final json = await _api.post('/messages', body: {
      'receiverId': receiverId,
      'content': content,
    });
    return MessageItem.fromJson((json as Map).cast<String, dynamic>());
  }

  Future<void> markRead(int userId) async {
    await _api.post('/messages/with/$userId/read');
  }
}
