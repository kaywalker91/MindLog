# fcm-setup

Firebase Cloud Messaging을 설정하고 푸시 알림을 구성하는 스킬

## 목표
- FCM 푸시 알림 설정
- 포그라운드/백그라운드 메시지 핸들링
- 로컬 알림 통합

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "FCM 설정", "push notification setup" 요청
- `/fcm-setup` 명령어
- Firebase 초기 설정 시
- 푸시 알림 기능 추가 시

## 현재 구현 상태
참조: `lib/core/services/fcm_service.dart`

```dart
/// Firebase Cloud Messaging 서비스
class FCMService {
  static FirebaseMessaging? _messaging;
  static String? _fcmToken;

  /// 초기화
  static Future<void> initialize({
    void Function(Map<String, dynamic> data)? onMessageOpened,
  }) async {
    _messaging = FirebaseMessaging.instance;
    // 권한 요청, 토큰 획득, 메시지 핸들러 설정
  }
}
```

## 프로세스

### Step 1: 패키지 설치 확인
```yaml
# pubspec.yaml
dependencies:
  firebase_messaging: ^15.2.0
  flutter_local_notifications: ^18.0.0
```

### Step 2: FCMService 구현
파일: `lib/core/services/fcm_service.dart`

```dart
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import 'notification_service.dart';

/// Firebase Cloud Messaging 서비스
class FCMService {
  FCMService._();

  static FirebaseMessaging? _messaging;
  static String? _fcmToken;
  static void Function(Map<String, dynamic> data)? _onMessageOpened;

  static String? get fcmToken => _fcmToken;

  /// 초기화
  static Future<void> initialize({
    void Function(Map<String, dynamic> data)? onMessageOpened,
  }) async {
    _messaging = FirebaseMessaging.instance;
    _onMessageOpened = onMessageOpened;

    // 알림 권한 요청
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _getToken();
      _messaging!.onTokenRefresh.listen(_onTokenRefresh);
      _setupMessageHandlers();
    }
  }

  static Future<void> _getToken() async {
    // iOS APNS 토큰 대기
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      String? apnsToken;
      int retryCount = 0;
      while (apnsToken == null && retryCount < 10) {
        apnsToken = await _messaging?.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(milliseconds: 500));
          retryCount++;
        }
      }
    }

    _fcmToken = await _messaging?.getToken();
    if (kDebugMode) debugPrint('[FCM] Token: $_fcmToken');
  }

  static void _onTokenRefresh(String token) {
    _fcmToken = token;
    if (kDebugMode) debugPrint('[FCM] Token refreshed: $token');
  }

  static void _setupMessageHandlers() {
    // 포그라운드 메시지
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    // 백그라운드 → 앱 열림
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    // 종료 상태 → 앱 열림
    _checkInitialMessage();
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
      _onMessageOpened?.call(initialMessage.data);
    }
  }

  /// 토픽 구독
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging?.subscribeToTopic(topic);
    if (kDebugMode) debugPrint('[FCM] Subscribed: $topic');
  }

  /// 토픽 구독 해제
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging?.unsubscribeFromTopic(topic);
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
```

### Step 3: NotificationService 구현
파일: `lib/core/services/notification_service.dart`

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'mindlog_reminders',
      '일기 작성 리마인더',
      importance: Importance.high,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mindlog_reminders',
        '일기 작성 리마인더',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      0,
      '오늘 하루는 어떠셨나요?',
      '마음을 기록해보세요 💙',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mindlog_reminders',
          '일기 작성 리마인더',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
```

### Step 4: main.dart에 초기화 추가
```dart
void main() {
  ErrorBoundary.runAppWithErrorHandling(
    onEnsureInitialized: () async {
      // ... 기존 초기화 ...
      await FirebaseService.initialize();

      // 백그라운드 핸들러 등록
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // FCM 및 로컬 알림 초기화
      await FCMService.initialize(
        onMessageOpened: (data) {
          // 메시지 클릭 시 처리
        },
      );
      await NotificationService.initialize();
    },
  );
}
```

### Step 5: 플랫폼별 설정

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<manifest ...>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />

    <application ...>
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
</manifest>
```

#### iOS (Xcode)
1. **Capabilities** 추가:
   - Push Notifications
   - Background Modes → Remote notifications

2. **Info.plist**:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## 출력 형식

```
🔔 FCM 설정 완료

✅ lib/core/services/fcm_service.dart
✅ lib/core/services/notification_service.dart

기능:
├── FCMService
│   ├── initialize() - FCM 초기화
│   ├── fcmToken - FCM 토큰 조회
│   ├── subscribeToTopic() - 토픽 구독
│   └── unsubscribeFromTopic() - 토픽 구독 해제
└── NotificationService
    ├── initialize() - 로컬 알림 초기화
    ├── showNotification() - 알림 표시
    └── scheduleDailyReminder() - 일일 리마인더 예약

메시지 핸들링:
├── Foreground - 로컬 알림으로 표시
├── Background - 시스템 알림
└── Terminated - 앱 열기 시 콜백

📱 플랫폼 설정:
   ├── Android: POST_NOTIFICATIONS 권한
   └── iOS: Push Notifications capability
```

## 메시지 유형

### Data Message
```json
{
  "to": "FCM_TOKEN",
  "data": {
    "type": "reminder",
    "title": "일기 작성 시간이에요",
    "body": "오늘의 감정을 기록해보세요"
  }
}
```

### Notification Message
```json
{
  "to": "FCM_TOKEN",
  "notification": {
    "title": "MindLog",
    "body": "새로운 AI 분석이 완료되었습니다"
  }
}
```

## 토픽 구독 활용

```dart
// 모든 사용자에게 공지
await FCMService.subscribeToTopic('announcements');

// 특정 기능 사용자
await FCMService.subscribeToTopic('premium_users');

// 구독 해제
await FCMService.unsubscribeFromTopic('announcements');
```

## 테스트

### Firebase Console에서 테스트
```
1. Firebase Console → Cloud Messaging
2. "새 캠페인" 또는 "첫 번째 메시지 보내기"
3. 앱 선택 → 테스트 메시지 전송
```

### curl로 테스트
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN",
    "notification": {
      "title": "Test",
      "body": "Test message"
    }
  }'
```

## 사용 예시

```
> "/fcm-setup"

AI 응답:
1. 패키지 확인: firebase_messaging, flutter_local_notifications 설치됨
2. FCMService 구현 확인
3. NotificationService 구현 확인
4. main.dart 연동 확인
5. 플랫폼 설정 확인
6. 설정 완료

테스트:
   Firebase Console → Cloud Messaging → 테스트 메시지 전송
```

## 연관 스킬
- `/crashlytics-setup` - Firebase Crashlytics 설정
- `/analytics-event` - Firebase Analytics 이벤트

## 주의사항
- iOS APNS 토큰 획득 대기 필요
- Android 13+ POST_NOTIFICATIONS 권한 요청 필수
- 백그라운드 핸들러는 Top-level 함수로 정의
- `@pragma('vm:entry-point')` 어노테이션 필수
- 디버그 모드에서 FCM 토큰 확인 권장
- 프로덕션에서는 서버에 토큰 저장 필요
