import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

import 'api_client.dart';
import 'token_storage.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final ApiClient _api = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  final StreamController<RemoteMessage> _foregroundMessagesController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onForegroundMessage =>
      _foregroundMessagesController.stream;

  static const String _channelId = 'default_channel';
  static const String _channelName = 'Notifications';
  static const String _prefsLastSentTokenKey = 'last_fcm_token_sent';

  static const String _prefsInAppNotificationsKey = 'in_app_notifications';
  static const int _maxStoredNotifications = 50;

  static Map<String, dynamic> _serializeRemoteMessage(RemoteMessage m) {
    return {
      'id': m.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      'title': m.notification?.title ?? 'SkillShare',
      'body': m.notification?.body ?? '',
      'receivedAt': DateTime.now().toIso8601String(),
      'data': m.data,
      'isRead': false,
    };
  }

  static Future<void> persistInAppNotification(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsInAppNotificationsKey);
      final List<dynamic> list = raw == null ? <dynamic>[] : jsonDecode(raw);

      list.insert(0, _serializeRemoteMessage(message));
      if (list.length > _maxStoredNotifications) {
        list.removeRange(_maxStoredNotifications, list.length);
      }

      await prefs.setString(_prefsInAppNotificationsKey, jsonEncode(list));
    } catch (_) {
      // ignore persistence errors
    }
  }

  static Future<List<Map<String, dynamic>>>
      loadPersistedInAppNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsInAppNotificationsKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> overwritePersistedInAppNotifications(
      List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsInAppNotificationsKey, jsonEncode(items));
    } catch (_) {
      // ignore persistence errors
    }
  }

  bool get _isSupportedMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  FirebaseMessaging get _messagingOrThrow {
    final m = _messaging;
    if (m == null) {
      throw StateError('FirebaseMessaging is not initialized');
    }
    return m;
  }

  Future<void> init() async {
    if (!_isSupportedMobile) return;

    _messaging ??= FirebaseMessaging.instance;

    await _initLocalNotifications();
    await _requestPermissionIfNeeded();

    await _messagingOrThrow.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      _foregroundMessagesController.add(message);
      persistInAppNotification(message);
      _showLocalForRemoteMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        debugPrint(
            'Notification opened: ${message.messageId} data=${message.data}');
      }
    });

    _messagingOrThrow.onTokenRefresh.listen((token) {
      syncTokenWithBackend(token: token);
    });

    final initial = await _messagingOrThrow.getInitialMessage();
    if (initial != null && kDebugMode) {
      debugPrint(
          'App opened from terminated via notification: ${initial.messageId} data=${initial.data}');
    }

    final token = await _messagingOrThrow.getToken();
    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }

    await syncTokenWithBackend(token: token);
  }

  Future<void> syncTokenWithBackend({String? token}) async {
    if (!_isSupportedMobile) return;
    _messaging ??= FirebaseMessaging.instance;

    try {
      final hasJwt = await _tokenStorage.getToken();
      if (hasJwt == null || hasJwt.isEmpty) return;

      final t = token ?? await _messagingOrThrow.getToken();
      if (t == null || t.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString(_prefsLastSentTokenKey);
      if (last == t) return;

      await _api.post('/notifications/token', body: {'token': t});
      await prefs.setString(_prefsLastSentTokenKey, t);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('syncTokenWithBackend failed: $e');
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        if (kDebugMode) {
          debugPrint('Local notification tapped: payload=${resp.payload}');
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Default channel for SkillShare notifications',
      importance: Importance.high,
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  Future<void> _requestPermissionIfNeeded() async {
    if (kIsWeb) return;

    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMobile) return;

    _messaging ??= FirebaseMessaging.instance;

    final settings = await _messagingOrThrow.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('Notification permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _showLocalForRemoteMessage(RemoteMessage message) async {
    final n = message.notification;
    final title = n?.title ?? 'SkillShare';
    final body = n?.body ?? '';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }
}
