import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';

class InAppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic> data;
  bool isRead;

  InAppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.data,
    required this.isRead,
  });

  factory InAppNotificationItem.fromRemoteMessage(RemoteMessage m) {
    final title = m.notification?.title ?? 'SkillShare';
    final body = m.notification?.body ?? '';

    return InAppNotificationItem(
      id: m.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      receivedAt: DateTime.now(),
      data: Map<String, dynamic>.from(m.data),
      isRead: false,
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final List<InAppNotificationItem> _items = [];

  StreamSubscription<RemoteMessage>? _sub;

  List<InAppNotificationItem> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> bootstrap() async {
    if (_sub != null) return;

    final persisted =
        await NotificationService.loadPersistedInAppNotifications();
    _items
      ..clear()
      ..addAll(persisted.map(_fromPersistedMap));
    notifyListeners();

    _sub = NotificationService.instance.onForegroundMessage.listen((m) {
      addRemoteMessage(m);
    });
  }

  InAppNotificationItem _fromPersistedMap(Map<String, dynamic> m) {
    DateTime receivedAt;
    try {
      receivedAt = DateTime.parse(m['receivedAt']?.toString() ?? '');
    } catch (_) {
      receivedAt = DateTime.now();
    }

    final dataRaw = m['data'];
    final data = dataRaw is Map
        ? Map<String, dynamic>.from(dataRaw)
        : <String, dynamic>{};

    return InAppNotificationItem(
      id: m['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: m['title']?.toString() ?? 'SkillShare',
      body: m['body']?.toString() ?? '',
      receivedAt: receivedAt,
      data: data,
      isRead: (m['isRead'] == true),
    );
  }

  Map<String, dynamic> _toPersistedMap(InAppNotificationItem n) {
    return {
      'id': n.id,
      'title': n.title,
      'body': n.body,
      'receivedAt': n.receivedAt.toIso8601String(),
      'data': n.data,
      'isRead': n.isRead,
    };
  }

  Future<void> _persist() async {
    final list = _items.map(_toPersistedMap).toList();
    await NotificationService.overwritePersistedInAppNotifications(list);
  }

  void addRemoteMessage(RemoteMessage message) {
    final item = InAppNotificationItem.fromRemoteMessage(message);
    _items.insert(0, item);
    _persist();
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _items) {
      n.isRead = true;
    }
    _persist();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _persist();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
