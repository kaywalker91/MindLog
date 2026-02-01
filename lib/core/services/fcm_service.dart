import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import 'crashlytics_service.dart';
import 'notification_service.dart';

/// Firebase Cloud Messaging 서비스
class FCMService {
  FCMService._();

  static FirebaseMessaging? _messaging;
  static String? _fcmToken;
  static void Function(Map<String, dynamic> data)? _onMessageOpened;
  static bool _initialized = false;
  static bool _handlersSetup = false;

  static String? get fcmToken => _fcmToken;

  /// 초기화
  static Future<void> initialize({
    void Function(Map<String, dynamic> data)? onMessageOpened,
  }) async {
    if (_initialized) return;

    final messaging = FirebaseMessaging.instance;
    _messaging = messaging;
    _onMessageOpened = onMessageOpened;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _getToken();

      messaging.onTokenRefresh.listen(
        _onTokenRefresh,
        onError: (error, stackTrace) async {
          await CrashlyticsService.recordError(
            error,
            stackTrace,
            reason: 'fcm_token_refresh_error',
            fatal: false,
          );
        },
      );
      _setupMessageHandlers();
      _initialized = true;
    }
  }

  static Future<void> _getToken() async {
    // iOS에서는 APNS 토큰이 준비될 때까지 대기해야 함
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      String? apnsToken;
      int retryCount = 0;
      const maxRetries = 3;

      while (apnsToken == null && retryCount < maxRetries) {
        apnsToken = await _messaging?.getAPNSToken();
        if (apnsToken == null) {
          if (kDebugMode) {
            debugPrint('[FCM] Waiting for APNS token... (attempt ${retryCount + 1}/$maxRetries)');
          }
          await Future.delayed(const Duration(milliseconds: 500));
          retryCount++;
        }
      }

      if (apnsToken == null) {
        if (kDebugMode) {
          debugPrint('[FCM] APNS token not available after $maxRetries attempts. FCM token will be retrieved later.');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('[FCM] APNS token ready');
      }
    }

    try {
      _fcmToken = await _messaging?.getToken();
      if (kDebugMode) debugPrint('[FCM] Token: $_fcmToken');
    } catch (e, stack) {
      await CrashlyticsService.recordError(
        e,
        stack,
        reason: 'fcm_gettoken_error',
        fatal: false,
      );
      if (kDebugMode) debugPrint('[FCM] Token retrieval failed: $e');
      // onTokenRefresh가 다음 앱 시작 시 복구
    }
  }

  static void _onTokenRefresh(String token) {
    _fcmToken = token;
    if (kDebugMode) debugPrint('[FCM] Token refreshed: $token');
  }

  static void _setupMessageHandlers() {
    if (_handlersSetup) return;
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    _checkInitialMessage();
    _handlersSetup = true;
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
    }
    await NotificationService.showNotification(
      title: message.notification?.title ?? 'MindLog',
      body: message.notification?.body ?? '',
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('[FCM] Opened App: ${message.notification?.title}');
    }
    _onMessageOpened?.call(message.data);
  }

  static Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging?.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        debugPrint('[FCM] Initial: ${initialMessage.notification?.title}');
      }
      _onMessageOpened?.call(initialMessage.data);
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    final messaging = _messaging ?? FirebaseMessaging.instance;
    await messaging.subscribeToTopic(topic);
    if (kDebugMode) debugPrint('[FCM] Subscribed: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    final messaging = _messaging ?? FirebaseMessaging.instance;
    await messaging.unsubscribeFromTopic(topic);
    if (kDebugMode) debugPrint('[FCM] Unsubscribed: $topic');
  }
}

/// 백그라운드 핸들러 (Top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  if (kDebugMode) {
    debugPrint('[FCM] Background: ${message.notification?.title}');
  }
}
