import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/conversation_item.dart';
import '../models/message_item.dart';
import '../models/user_profile.dart';
import '../services/message_service.dart';
import '../services/profile_service.dart';

class MessagesProvider extends ChangeNotifier {
  final MessageService _messageService;
  final ProfileService _profileService;

  bool _isLoading = false;
  String? _error;

  UserProfile? _me;
  List<ConversationItem> _conversations = const [];

  int? _selectedUserId;
  List<MessageItem> _messages = const [];

  Timer? _pollTimer;

  MessagesProvider(
      {MessageService? messageService, ProfileService? profileService})
      : _messageService = messageService ?? MessageService(),
        _profileService = profileService ?? ProfileService();

  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProfile? get me => _me;
  List<ConversationItem> get conversations => _conversations;

  int get totalUnread {
    return _conversations.fold<int>(0, (acc, c) => acc + c.unreadCount);
  }

  void ensureConversation(
      {required int userId, required String fullName, required String email}) {
    final exists = _conversations.any((c) => c.userId == userId);
    if (exists) return;
    _conversations = [
      ConversationItem(
        userId: userId,
        fullName: fullName,
        email: email,
        lastMessageId: null,
        lastMessageContent: null,
        lastMessageCreatedAt: null,
        lastMessageSenderId: null,
        unreadCount: 0,
      ),
      ..._conversations,
    ];
    notifyListeners();
  }

  int? get selectedUserId => _selectedUserId;
  List<MessageItem> get messages => _messages;

  Future<void> bootstrap() async {
    _setLoading(true);
    _error = null;
    try {
      _me = await _profileService.me();
      _conversations = await _messageService.listConversations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshMe() async {
    try {
      _me = await _profileService.me();
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> refreshConversations() async {
    try {
      final previous = _conversations;
      final fetched = await _messageService.listConversations();

      final selectedId = _selectedUserId;
      if (selectedId != null && !fetched.any((c) => c.userId == selectedId)) {
        final existing = previous.where((c) => c.userId == selectedId).toList();
        if (existing.isNotEmpty) {
          _conversations = [...existing, ...fetched];
        } else {
          _conversations = fetched;
        }
      } else {
        _conversations = fetched;
      }

      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> selectConversation(int userId) async {
    _selectedUserId = userId;
    notifyListeners();

    await loadMessages(userId);

    try {
      await _messageService.markRead(userId);
      await refreshConversations();
    } catch (_) {
      // ignore
    }

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final selected = _selectedUserId;
      if (selected == null) return;
      await loadMessages(selected, silent: true);
      await refreshConversations();
    });
  }

  Future<void> loadMessages(int userId, {bool silent = false}) async {
    if (!silent) {
      _setLoading(true);
    }
    _error = null;

    try {
      _messages = await _messageService.conversationWith(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!silent) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
    }
  }

  Future<bool> sendMessage(String content) async {
    final me = _me;
    final otherId = _selectedUserId;
    if (me == null || otherId == null) return false;

    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    _error = null;
    notifyListeners();

    try {
      final sent =
          await _messageService.send(receiverId: otherId, content: trimmed);
      _messages = [..._messages, sent];
      await refreshConversations();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedUserId = null;
    _messages = const [];
    _pollTimer?.cancel();
    _pollTimer = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
