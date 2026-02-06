import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase_options.dart';
import '../constants/notification_messages.dart';
import 'crashlytics_service.dart';
import 'emotion_score_service.dart';
import 'notification_service.dart';

/// Firebase Cloud Messaging 서비스
class FCMService {
  FCMService._();

  static FirebaseMessaging? _messaging;
  static String? _fcmToken;
  static void Function(Map<String, dynamic> data)? _onMessageOpened;
  static bool _initialized = false;
  static bool _handlersSetup = false;

  /// 테스트용: 사용자 이름 조회 함수 오버라이드
  @visibleForTesting
  static Future<String?> Function()? userNameProvider;

  /// 테스트용: 감정 점수 조회 함수 오버라이드
  @visibleForTesting
  static Future<double?> Function()? emotionScoreProvider;

  /// 테스트용: 상태 리셋
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _handlersSetup = false;
    _messaging = null;
    _fcmToken = null;
    _onMessageOpened = null;
    userNameProvider = null;
    emotionScoreProvider = null;
  }

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
            debugPrint(
              '[FCM] Waiting for APNS token... (attempt ${retryCount + 1}/$maxRetries)',
            );
          }
          await Future.delayed(const Duration(milliseconds: 500));
          retryCount++;
        }
      }

      if (apnsToken == null) {
        if (kDebugMode) {
          debugPrint(
            '[FCM] APNS token not available after $maxRetries attempts. FCM token will be retrieved later.',
          );
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

    final result = await buildPersonalizedMessage(
      serverTitle: message.notification?.title,
      serverBody: message.notification?.body,
    );

    await NotificationService.showNotification(
      title: result.title,
      body: result.body,
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }

  /// FCM 메시지를 감정 기반으로 개인화
  ///
  /// [serverTitle] 서버에서 전송된 원본 제목
  /// [serverBody] 서버에서 전송된 원본 본문
  ///
  /// 반환:
  /// - 감정 데이터 있음: 감정 기반 메시지 + 이름 개인화
  /// - 감정 데이터 없음: 서버 메시지 + 이름 개인화
  @visibleForTesting
  static Future<({String title, String body})> buildPersonalizedMessage({
    required String? serverTitle,
    required String? serverBody,
  }) async {
    // 테스트 주입 또는 실제 조회
    final userName = userNameProvider != null
        ? await userNameProvider!()
        : await _getUserName();
    final avgScore = emotionScoreProvider != null
        ? await emotionScoreProvider!()
        : await EmotionScoreService.getRecentAverageScore();

    String title;
    String body;

    if (avgScore != null) {
      // 감정 기반 메시지 재선택 (서버 메시지 무시, 개인화된 메시지 사용)
      if (kDebugMode) {
        debugPrint('[FCM] Using emotion-based message (avgScore: $avgScore)');
      }
      final emotionMessage = NotificationMessages.getMindcareMessageByEmotion(
        avgScore,
      );
      // 이름 개인화 적용
      final personalizedMessage = NotificationMessages.applyNameToMessage(
        emotionMessage,
        userName,
      );
      title = personalizedMessage.title;
      body = personalizedMessage.body;
    } else {
      // 감정 데이터 없음: 서버 메시지에 이름 개인화만 적용
      if (kDebugMode) {
        debugPrint('[FCM] No emotion data, using server message');
      }
      title = NotificationMessages.applyNamePersonalization(
        serverTitle ?? 'MindLog',
        userName,
      );
      body = NotificationMessages.applyNamePersonalization(
        serverBody ?? '',
        userName,
      );
    }

    return (title: title, body: body);
  }

  /// SharedPreferences에서 사용자 이름 조회
  static Future<String?> _getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_name');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Failed to get user name: $e');
      }
      return null;
    }
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

  try {
    final result = await FCMService.buildPersonalizedMessage(
      serverTitle: message.notification?.title,
      serverBody: message.notification?.body,
    );

    await NotificationService.showNotification(
      title: result.title,
      body: result.body,
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[FCM] Background personalization failed: $e');
    }
    // 폴백: 원본 서버 메시지 표시
    await NotificationService.showNotification(
      title: message.notification?.title ?? 'MindLog',
      body: message.notification?.body ?? '',
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }
}
