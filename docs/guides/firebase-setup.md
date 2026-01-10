# 1단계: Firebase 필수 기능 구체적 구현 계획

## 📋 구현 개요

| 기능 | 패키지 버전 | 소요 시간 | 난이도 |
| :--- | :--- | :--- | :--- |
| **Firebase Core** | `^3.8.0` | 0.5일 | ⭐ |
| **Firebase Analytics** | `^11.4.0` | 0.5일 | ⭐ |
| **Firebase Crashlytics** | `^4.2.0` | 0.5일 | ⭐ |
| **Firebase Cloud Messaging** | `^15.2.0` | 2일 | ⭐⭐ |
| **총합** | - | **3.5일** | - |

---

## 🗂️ Phase 0: 사전 준비 (30분)

### Step 0-1: Firebase 프로젝트 생성
1. **Firebase Console** ([console.firebase.google.com](https://console.firebase.google.com)) 접속
2. **"프로젝트 추가"** 클릭
3. 프로젝트 이름: `MindLog` 또는 `mindlog-app`
4. **Google Analytics 활성화** ✅
5. **Android 앱 등록**:
   - 패키지명: `com.mindlog.mindlog`
   - SHA-1 인증서 등록 (선택)
6. **iOS 앱 등록**:
   - Bundle ID: `com.mindlog.mindlog`

### Step 0-2: FlutterFire CLI 설정

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# 프로젝트 루트에서 실행
cd /Users/kaywalker/AndroidStudioProjects/mindlog
flutterfire configure

```

**자동 생성 파일:**

* `lib/firebase_options.dart`: Firebase 설정 옵션
* `android/app/google-services.json`: Android 설정
* `ios/Runner/GoogleService-Info.plist`: iOS 설정

---

## 📦 Phase 1: 패키지 설치 및 설정

### Step 1-1: pubspec.yaml 수정

```yaml
dependencies:
  # ... 기존 의존성 ...
  
  # Firebase
  firebase_core: ^3.8.0
  firebase_analytics: ^11.4.0
  firebase_crashlytics: ^4.2.0
  firebase_messaging: ^15.2.0
  
  # Local Notifications (FCM용)
  flutter_local_notifications: ^18.0.0

```

### Step 1-2: Android 설정 (`android/settings.gradle.kts`)

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // ✅ 추가
    id("com.google.gms.google-services") version "4.4.2" apply false
}

```

### Step 1-3: Android 앱 설정 (`android/app/build.gradle.kts`)

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // ✅ 추가
    id("com.google.gms.google-services")
}

```

### Step 1-4: iOS Podfile 수정

```ruby
# 주석 해제
platform :ios, '13.0'

# Firebase Crashlytics dSYM 업로드를 위한 설정
target 'Runner' do
  use_frameworks!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

```

---

## 🔧 Phase 2: Firebase 서비스 구현

### 📂 신규 파일 구조

```
lib/core/services/
├── firebase_service.dart       # Firebase 초기화
├── analytics_service.dart      # Analytics 이벤트
├── crashlytics_service.dart    # Crashlytics 래퍼
├── fcm_service.dart            # FCM 토큰/메시지 관리
└── notification_service.dart   # 로컬 알림 관리

lib/presentation/providers/
└── firebase_providers.dart     # Firebase Providers

```

### 📄 1. `lib/core/services/firebase_service.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import 'crashlytics_service.dart';
import 'analytics_service.dart';

/// Firebase 서비스 초기화 및 관리
class FirebaseService {
  FirebaseService._();
  
  static bool _initialized = false;
  
  /// Firebase 초기화
  static Future<void> initialize() async {
    if (_initialized) return;
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Crashlytics 초기화
    await CrashlyticsService.initialize();
    
    // Analytics 초기화
    await AnalyticsService.initialize();
    
    _initialized = true;
    
    if (kDebugMode) {
      debugPrint('🔥 [FirebaseService] Firebase initialized successfully');
    }
  }
  
  /// 초기화 여부
  static bool get isInitialized => _initialized;
}

```

### 📄 2. `lib/core/services/analytics_service.dart`

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics 서비스
class AnalyticsService {
  AnalyticsService._();
  
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;
  
  /// 초기화
  static Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
    
    // 디버그 모드에서는 Analytics 디버그 모드 활성화
    if (kDebugMode) {
      await _analytics!.setAnalyticsCollectionEnabled(true);
    }
  }
  
  /// Navigator Observer (자동 화면 추적)
  static FirebaseAnalyticsObserver? get observer => _observer;
  
  /// 화면 조회 이벤트
  static Future<void> logScreenView(String screenName) async {
    await _analytics?.logScreenView(screenName: screenName);
    _debugLog('screen_view', {'screen_name': screenName});
  }
  
  /// 앱 오픈 이벤트
  static Future<void> logAppOpen() async {
    await _analytics?.logAppOpen();
    _debugLog('app_open', {});
  }
  
  /// 일기 작성 이벤트
  static Future<void> logDiaryCreated({
    required int contentLength,
    String? aiCharacterId,
  }) async {
    await _analytics?.logEvent(
      name: 'diary_created',
      parameters: {
        'content_length': contentLength,
        'ai_character_id': aiCharacterId ?? 'default',
      },
    );
    _debugLog('diary_created', {
      'content_length': contentLength,
      'ai_character_id': aiCharacterId,
    });
  }
  
  /// 일기 분석 완료 이벤트
  static Future<void> logDiaryAnalyzed({
    required String aiCharacterId,
    required int sentimentScore,
    required int energyLevel,
  }) async {
    await _analytics?.logEvent(
      name: 'diary_analyzed',
      parameters: {
        'ai_character_id': aiCharacterId,
        'sentiment_score': sentimentScore,
        'energy_level': energyLevel,
      },
    );
    _debugLog('diary_analyzed', {
      'ai_character_id': aiCharacterId,
      'sentiment_score': sentimentScore,
    });
  }
  
  /// 행동 지침 완료 이벤트
  static Future<void> logActionItemCompleted({
    required String actionItemText,
  }) async {
    await _analytics?.logEvent(
      name: 'action_item_completed',
      parameters: {
        'action_item_preview': actionItemText.length > 50 
            ? actionItemText.substring(0, 50) 
            : actionItemText,
      },
    );
    _debugLog('action_item_completed', {});
  }
  
  /// AI 캐릭터 변경 이벤트
  static Future<void> logAiCharacterChanged({
    required String fromCharacterId,
    required String toCharacterId,
  }) async {
    await _analytics?.logEvent(
      name: 'ai_character_changed',
      parameters: {
        'from_character': fromCharacterId,
        'to_character': toCharacterId,
      },
    );
    _debugLog('ai_character_changed', {
      'from': fromCharacterId,
      'to': toCharacterId,
    });
  }
  
  /// 통계 화면 조회 이벤트
  static Future<void> logStatisticsViewed({
    required String period,
  }) async {
    await _analytics?.logEvent(
      name: 'statistics_viewed',
      parameters: {'period': period},
    );
    _debugLog('statistics_viewed', {'period': period});
  }
  
  /// 사용자 속성 설정
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics?.setUserProperty(name: name, value: value);
  }
  
  static void _debugLog(String event, Map<String, dynamic> params) {
    if (kDebugMode) {
      debugPrint('📊 [Analytics] $event: $params');
    }
  }
}

```

### 📄 3. `lib/core/services/crashlytics_service.dart`

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Crashlytics 서비스
class CrashlyticsService {
  CrashlyticsService._();
  
  static FirebaseCrashlytics? _crashlytics;
  
  /// 초기화
  static Future<void> initialize() async {
    _crashlytics = FirebaseCrashlytics.instance;
    
    // 디버그 모드에서는 크래시 수집 비활성화 (선택)
    await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);
    
    // Flutter 프레임워크 에러를 Crashlytics로 전달
    FlutterError.onError = (errorDetails) {
      _crashlytics!.recordFlutterFatalError(errorDetails);
    };
    
    // 비동기 에러 처리
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics!.recordError(error, stack, fatal: true);
      return true;
    };
  }
  
  /// 에러 기록
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      debugPrint('🚨 [Crashlytics] Recording error: $exception');
    }
    
    await _crashlytics?.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }
  
  // ... (커스텀 키, User ID 등 메서드 생략) ...
}

```

### 📄 4. `lib/core/services/fcm_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Firebase Cloud Messaging 서비스
class FCMService {
  FCMService._();
  
  static FirebaseMessaging? _messaging;
  static String? _fcmToken;
  
  /// FCM 토큰
  static String? get fcmToken => _fcmToken;
  
  /// 초기화
  static Future<void> initialize() async {
    _messaging = FirebaseMessaging.instance;
    
    // 알림 권한 요청
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (kDebugMode) {
      debugPrint('🔔 [FCM] Permission status: ${settings.authorizationStatus}');
    }
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // FCM 토큰 획득
      await _getToken();
      
      // 토큰 갱신 리스너
      _messaging!.onTokenRefresh.listen(_onTokenRefresh);
      
      // 메시지 핸들러 설정
      _setupMessageHandlers();
    }
  }
  
  static Future<void> _getToken() async {
    _fcmToken = await _messaging?.getToken();
    if (kDebugMode) debugPrint('🔔 [FCM] Token: $_fcmToken');
  }
  
  static void _onTokenRefresh(String token) {
    _fcmToken = token;
    if (kDebugMode) debugPrint('🔔 [FCM] Token refreshed: $token');
  }
  
  static void _setupMessageHandlers() {
    // 포그라운드 메시지
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    // 백그라운드 -> 앱 열림
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    // 종료 상태 -> 앱 열림
    _checkInitialMessage();
  }
  
  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) debugPrint('🔔 [FCM] Foreground: ${message.notification?.title}');
    await NotificationService.showNotification(
      title: message.notification?.title ?? 'MindLog',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }
  
  static void _onMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) debugPrint('🔔 [FCM] Opened App: ${message.notification?.title}');
  }
  
  static Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging?.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) debugPrint('🔔 [FCM] Initial: ${initialMessage.notification?.title}');
    }
  }
}

/// 백그라운드 핸들러 (Top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) debugPrint('🔔 [FCM] Background: ${message.notification?.title}');
}

```

### 📄 5. `lib/core/services/notification_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  NotificationService._();
  
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
         if (kDebugMode) debugPrint('🔔 [Noti] Tapped: ${response.payload}');
      },
    );
    
    await _createNotificationChannel();
  }
  
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'mindlog_reminders', '일기 작성 리마인더',
      description: '매일 일기 작성을 알려드립니다',
      importance: Importance.high,
    );
    await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  static Future<void> showNotification({
    required String title, required String body, String? payload
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mindlog_reminders', '일기 작성 리마인더',
        importance: Importance.high, priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title, body, details, payload: payload
    );
  }
  
  static Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    await _notifications.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));
    
    await _notifications.zonedSchedule(
      0, '오늘 하루는 어떠셨나요?', '마음을 기록해보세요 💙',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails('mindlog_reminders', '일기 작성 리마인더'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

```

---

## 🔄 Phase 3: 기존 파일 수정

### 수정 1: `lib/main.dart`

```dart
// ... imports ...
import 'core/services/firebase_service.dart';           // ✅
import 'core/services/fcm_service.dart';                // ✅
import 'core/services/notification_service.dart';       // ✅
import 'core/services/crashlytics_service.dart';        // ✅
import 'core/services/analytics_service.dart';          // ✅

void main() {
  ErrorBoundary.runAppWithErrorHandling(
    onEnsureInitialized: () async {
      await EnvironmentService.initialize();
      await initializeDateFormatting('ko_KR', null);
      
      // ✅ Firebase & Notification Services 초기화
      await FirebaseService.initialize();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FCMService.initialize();
      await NotificationService.initialize();
    },
    // ...
    onError: (error, stack) {
      // ✅ Crashlytics로 에러 전송
      CrashlyticsService.recordError(error, stack);
    },
  );
}

class MindLogApp extends ConsumerWidget {
  // ...
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      // ...
      // ✅ Analytics Observer 추가
      navigatorObservers: [
        if (AnalyticsService.observer != null) AnalyticsService.observer!,
      ],
      home: const SplashScreen(),
    );
  }
}

```

### 수정 2: `lib/core/errors/error_boundary.dart`

```dart
// _logError 메서드 내부
static void _logError(Object error, StackTrace stack) {
  if (kDebugMode) {
    debugPrint('🚨 [ErrorBoundary] Uncaught error: $error');
  }
  // ✅ Crashlytics로 전송
  CrashlyticsService.recordError(error, stack);
}

```

---

## 📊 Phase 4: Analytics 이벤트 적용 위치

| 화면/이벤트 | 메서드 | 위치 |
| --- | --- | --- |
| **앱 시작** | `logAppOpen()` | `SplashScreen.initState()` |
| **일기 목록 조회** | `logScreenView('diary_list')` | `DiaryListScreen` |
| **일기 작성 완료** | `logDiaryCreated()` | `DiaryScreen._saveDiary()` |
| **일기 분석 완료** | `logDiaryAnalyzed()` | `DiaryAnalysisController` |
| **행동 지침 완료** | `logActionItemCompleted()` | `ActionCheckItem.onChanged` |
| **AI 캐릭터 변경** | `logAiCharacterChanged()` | `SettingsScreen` |
| **통계 화면** | `logStatisticsViewed()` | `StatisticsScreen` |

---

## ⚙️ Phase 5: 추가 설정

### iOS (Xcode)

* **Capabilities 추가**: `Push Notifications`
* **Background Modes 활성화**:
* ✅ Background fetch
* ✅ Remote notifications



### Android (`AndroidManifest.xml`)

```xml
<manifest ...>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" /> <application ...>
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
</manifest>

```

---

## ✅ 검증 체크리스트

* [ ] **Phase 1**: Firebase Console에서 Analytics 데이터 수신 확인
* [ ] **Phase 1**: Crashlytics 대시보드에서 앱 등록 확인 (테스트 크래시 발생시켜보기)
* [ ] **Phase 2**: FCM 토큰이 로그에 정상적으로 출력되는지 확인
* [ ] **Phase 2**: 앱이 켜져있을 때(Foreground) 알림 표시 확인
* [ ] **Phase 2**: 앱이 꺼져있을 때(Background) 알림 수신 확인
* [ ] **Phase 2**: 일기 작성 리마인더가 지정된 시간에 울리는지 확인

---

## 📅 구현 일정 (3.5일)

| 일정 | 작업 내용 |
| --- | --- |
| **Day 1 오전** | Phase 0: 프로젝트 생성, CLI 설정 |
| **Day 1 오후** | Phase 1: 패키지 설치, Native 설정 |
| **Day 2 오전** | Phase 2: Core, Analytics Service 구현 |
| **Day 2 오후** | Phase 2: Crashlytics 구현, ErrorBoundary 연동 |
| **Day 3 전일** | Phase 3: FCM + NotificationService (로컬 알림 포함) 구현 |
| **Day 4 오전** | Phase 4: 각 화면에 Analytics 이벤트 심기 |
| **Day 4 오후** | Phase 5: 전체 기능 테스트 및 검증 |

> **💡 Note:**
> * `flutterfire configure` 명령어를 사용하면 설정 실수를 줄일 수 있습니다.
> * 개발 중에는 Crashlytics 리포트가 너무 많이 쌓이지 않도록 디버그 모드 분기 처리를 확인하세요.
> * Android 13+ 부터는 알림 권한 요청이 필수입니다.
> 
> 

```

```