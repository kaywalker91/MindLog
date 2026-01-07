# crashlytics-setup

Firebase Crashlytics를 프로젝트에 설정하고 에러 리포팅을 구성하는 스킬

## 목표
- Crashlytics 에러 리포팅 설정
- 에러 핸들링 표준화
- 프로덕션 안정성 모니터링

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "Crashlytics 설정", "crashlytics setup" 요청
- `/crashlytics-setup` 명령어
- Firebase 초기 설정 시
- 에러 리포팅 구현 시

## 현재 구현 상태
참조: `lib/core/services/crashlytics_service.dart`

```dart
/// Firebase Crashlytics 서비스
class CrashlyticsService {
  CrashlyticsService._();

  static FirebaseCrashlytics? _crashlytics;

  /// 초기화
  static Future<void> initialize() async {
    _crashlytics ??= FirebaseCrashlytics.instance;
    await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);
  }

  /// 에러 기록
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    // ...
  }
}
```

## 프로세스

### Step 1: 패키지 설치 확인
```yaml
# pubspec.yaml
dependencies:
  firebase_crashlytics: ^4.2.0
```

### Step 2: CrashlyticsService 구현
파일: `lib/core/services/crashlytics_service.dart`

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

    // 디버그 모드에서는 수집 비활성화
    await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Flutter 프레임워크 에러 핸들링
    FlutterError.onError = (errorDetails) {
      _crashlytics!.recordFlutterFatalError(errorDetails);
    };

    // 비동기 에러 핸들링
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
      debugPrint('[Crashlytics] Recording error: $exception');
    }

    try {
      final crashlytics = _crashlytics ?? FirebaseCrashlytics.instance;
      await crashlytics.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Crashlytics] Failed to record error: $error');
      }
    }
  }

  /// 사용자 ID 설정
  static Future<void> setUserId(String userId) async {
    await _crashlytics?.setUserIdentifier(userId);
  }

  /// 커스텀 키 설정
  static Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics?.setCustomKey(key, value);
  }

  /// 로그 메시지 추가
  static Future<void> log(String message) async {
    await _crashlytics?.log(message);
  }

  /// 테스트 크래시 발생
  static void testCrash() {
    _crashlytics?.crash();
  }
}
```

### Step 3: main.dart에 초기화 추가
```dart
void main() {
  ErrorBoundary.runAppWithErrorHandling(
    onEnsureInitialized: () async {
      // ... 기존 초기화 ...
      await FirebaseService.initialize(); // Crashlytics 포함
    },
    onError: (error, stack) {
      CrashlyticsService.recordError(error, stack);
    },
  );
}
```

### Step 4: ErrorBoundary 연동
파일: `lib/core/errors/error_boundary.dart`

```dart
static void _logError(Object error, StackTrace stack) {
  if (kDebugMode) {
    debugPrint('[ErrorBoundary] Uncaught error: $error');
  }
  // Crashlytics로 에러 전송
  CrashlyticsService.recordError(error, stack);
}
```

## 출력 형식

```
🔥 Crashlytics 설정 완료

✅ lib/core/services/crashlytics_service.dart

기능:
├── initialize() - Crashlytics 초기화
├── recordError() - 에러 기록
├── setUserId() - 사용자 ID 설정
├── setCustomKey() - 커스텀 키 설정
├── log() - 로그 메시지 추가
└── testCrash() - 테스트 크래시

연동:
├── main.dart - ErrorBoundary 연동
├── FlutterError.onError - Flutter 에러 핸들링
└── PlatformDispatcher.onError - 비동기 에러 핸들링

📊 Firebase Console:
   └─ Crashlytics 대시보드에서 에러 확인
```

## 에러 핸들링 패턴

### Try-Catch 블록
```dart
try {
  await riskyOperation();
} catch (e, stack) {
  CrashlyticsService.recordError(
    e,
    stack,
    reason: 'Failed to perform risky operation',
  );
  rethrow;
}
```

### UseCase에서 사용
```dart
Future<Result> execute(Params params) async {
  try {
    return await _repository.doSomething(params);
  } catch (e, stack) {
    CrashlyticsService.recordError(e, stack);
    if (e is Failure) rethrow;
    throw UnknownFailure(message: e.toString());
  }
}
```

### 커스텀 키 활용
```dart
// 사용자 컨텍스트 추가
CrashlyticsService.setCustomKey('current_screen', 'DiaryScreen');
CrashlyticsService.setCustomKey('diary_count', 10);
CrashlyticsService.setCustomKey('ai_character', 'Luna');
```

## Firebase Console 확인

### 크래시 리포트 보기
```
1. Firebase Console → Crashlytics
2. 앱 선택
3. 크래시 목록 확인
4. 스택 트레이스 분석
```

### 커스텀 키 필터링
```
1. 크래시 상세 페이지
2. "Keys" 탭 확인
3. 커스텀 키로 필터링
```

## 테스트

### 테스트 크래시 발생
```dart
// 디버그 모드에서만 사용
if (kDebugMode) {
  ElevatedButton(
    onPressed: () => CrashlyticsService.testCrash(),
    child: Text('Test Crash'),
  );
}
```

### 에러 기록 테스트
```dart
CrashlyticsService.recordError(
  Exception('Test error'),
  StackTrace.current,
  reason: 'Manual test',
);
```

## 사용 예시

```
> "/crashlytics-setup"

AI 응답:
1. 패키지 확인: firebase_crashlytics 설치됨
2. CrashlyticsService 구현 확인
3. main.dart 연동 확인
4. ErrorBoundary 연동 확인
5. 설정 완료

테스트:
   CrashlyticsService.testCrash()
```

## 연관 스킬
- `/fcm-setup` - Firebase Cloud Messaging 설정
- `/analytics-event` - Firebase Analytics 이벤트

## 주의사항
- 디버그 모드에서는 수집 비활성화 (`!kDebugMode`)
- 개인정보는 커스텀 키에 포함하지 않음
- dSYM 파일 업로드 필요 (iOS)
- ProGuard 매핑 파일 업로드 필요 (Android, obfuscation 사용 시)
- 테스트 크래시는 프로덕션에서 호출하지 않음
