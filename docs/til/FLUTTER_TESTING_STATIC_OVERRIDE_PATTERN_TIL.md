# Flutter 테스트: 플랫폼 서비스 정적 오버라이드 패턴

**생성일**: 2026-02-27
**분류**: Flutter Testing / CI Quality
**난이도**: 중급
**소요 시간**: 10분

---

## 문제: CI 로그 노이즈 (Side Effect Leakage)

위젯/프로바이더 테스트에서 탭이나 상태 변경이 플랫폼 서비스를 실제 호출할 때 두 가지 증상이 발생한다:

1. **`LateInitializationError`**: `FlutterLocalNotificationsPlugin`이 미초기화 상태에서 `showNotification()` 호출
2. **`UnknownFailure` 로그**: 실제 `NotificationSchedulerImpl`이 실행되어 플랫폼 채널 실패 → UseCase catch → debugPrint

이는 assertion failure가 아니므로 테스트는 **통과**하지만 CI 로그가 오염된다.

### 실제 발생 사례 (이 프로젝트)

| 로그 메시지 | 발생 횟수 | 원인 |
|------------|---------|------|
| `[NotificationSettingsController] applySettings failed: UnknownFailure` | 3회 | `NotificationSection` 위젯 탭 → `NotificationSettingsService` 실제 호출 |
| `[DiaryAnalysis] Emotion trend analysis failed: LateInitializationError` | 7회 | `analyzeDiary()` 성공 → `EmotionTrendNotificationService.notifyTrend()` 실제 호출 |

---

## 해결책: `@visibleForTesting static Function? override` 패턴

이 프로젝트의 플랫폼 서비스들은 **정적 오버라이드 필드** + **`resetForTesting()`** 메서드를 제공한다.

### 1. EmotionTrendNotificationService (단일 오버라이드)

```dart
// lib/core/services/emotion_trend_notification_service.dart
@visibleForTesting
static Future<void> Function({
  required String title,
  required String body,
  String? payload,
  String channel,
})? showNotificationOverride;

@visibleForTesting
static void resetForTesting() {
  showNotificationOverride = null;
  _random = Random();
}
```

**테스트 적용:**
```dart
setUp(() {
  EmotionTrendNotificationService.showNotificationOverride =
      ({required String title, required String body, String? payload, String channel = ''}) async {};
});

tearDown(() {
  EmotionTrendNotificationService.resetForTesting();
});
```

### 2. NotificationSettingsService (9개 오버라이드)

```dart
setUp(() {
  NotificationSettingsService.resetForTesting(); // 먼저 초기화
  NotificationSettingsService.areNotificationsEnabledOverride = () async => true;
  NotificationSettingsService.canScheduleExactAlarmsOverride = () async => true;
  NotificationSettingsService.isIgnoringBatteryOverride = () async => true;
  NotificationSettingsService.scheduleDailyReminderOverride = ({
    required int hour,
    required int minute,
    required String title,
    String? body,
    String? payload,
    dynamic scheduleMode,
  }) async => true;
  NotificationSettingsService.cancelDailyReminderOverride = () async {};
  NotificationSettingsService.subscribeToTopicOverride = (_) async {};
  NotificationSettingsService.unsubscribeFromTopicOverride = (_) async {};
  NotificationSettingsService.scheduleWeeklyInsightOverride =
      ({required bool enabled}) async => true;
  NotificationSettingsService.analyticsLog = [];
});

tearDown(() {
  NotificationSettingsService.resetForTesting();
});
```

---

## 핵심 교훈

### 1. 로그 노이즈도 실패다
CI 로그의 에러 메시지는 테스트 실패처럼 취급해야 한다. 통과해도 원인 불명 로그가 남으면 실제 문제를 숨긴다.

### 2. `resetForTesting()`은 반드시 tearDown에
`setUp`에서만 오버라이드를 설정하고 `tearDown`에서 리셋하지 않으면 다른 테스트 그룹에 leak된다.

### 3. 원인 추적 순서
```
로그 메시지 → 서비스 메서드 → 호출 경로 역추적 → 오버라이드 설정
```
표면 메시지(UnknownFailure)가 아닌 스택 트레이스 전체를 추적해야 실제 미오버라이드 서비스를 찾을 수 있다.

### 4. 새 서비스 추가 시 체크리스트
- 플랫폼 채널 호출이 있는 서비스: `@visibleForTesting static Function? override` 필드 추가
- `resetForTesting()` 메서드에 null 초기화 포함
- 관련 테스트의 setUp/tearDown에 즉시 적용

---

## 기존 오버라이드 목록 (이 프로젝트)

| 서비스 | 오버라이드 수 | 참조 파일 |
|--------|------------|---------|
| `NotificationSettingsService` | 9 | `lib/core/services/notification_settings_service.dart` |
| `EmotionTrendNotificationService` | 1 | `lib/core/services/emotion_trend_notification_service.dart` |

**참조 테스트 예시**: `test/data/datasources/local/notification_scheduler_impl_test.dart:51-78`

---

## 관련 TIL

- `FCM_IDEMPOTENCY_LOCK.md` — FCM 중복 발송 방지 (서버 측)
- `CLEAN_ARCHITECTURE_VIOLATION_FIX_TIL.md` — 레이어 분리 원칙

---

**버전**: 1.0
**작성자**: Claude Code
