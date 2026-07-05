import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mindlog/core/services/emotion_trend_notification_service.dart';
import 'package:mindlog/core/services/notification_settings_service.dart';
import 'package:mindlog/core/services/safety_followup_service.dart';

/// 플랫폼 알림 서비스 mock — provider/위젯 테스트 side-effect 차단용.
///
/// 참조: `docs/til/FLUTTER_TESTING_STATIC_OVERRIDE_PATTERN_TIL.md`
void setupNotificationServiceMocks() {
  NotificationSettingsService.resetForTesting();
  NotificationSettingsService.areNotificationsEnabledOverride = () async =>
      true;
  NotificationSettingsService.canScheduleExactAlarmsOverride = () async =>
      true;
  NotificationSettingsService.isIgnoringBatteryOverride = () async => true;
  NotificationSettingsService.getPendingNotificationsOverride = () async => [];
  NotificationSettingsService.scheduleDailyReminderOverride =
      ({
        required int hour,
        required int minute,
        required String title,
        String? body,
        String? payload,
        AndroidScheduleMode? scheduleMode,
      }) async => true;
  NotificationSettingsService.cancelDailyReminderOverride = () async {};
  NotificationSettingsService.subscribeToTopicOverride = (_) async {};
  NotificationSettingsService.unsubscribeFromTopicOverride = (_) async {};
  NotificationSettingsService.scheduleWeeklyInsightOverride =
      ({required bool enabled}) async => true;
  NotificationSettingsService.analyticsLog = [];
}

void setupEmotionTrendNotificationMock() {
  EmotionTrendNotificationService.showNotificationOverride =
      ({
        required String title,
        required String body,
        String? payload,
        String channel = '',
      }) async {};
}

void setupSafetyFollowupMock() {
  SafetyFollowupService.scheduleOneTimeOverride =
      ({
        required int id,
        required String title,
        required String body,
        required scheduledDate,
        String? payload,
        String channel = '',
      }) async => true;
}

/// DiaryAnalysisNotifier post-analysis hook 테스트용 일괄 mock.
void setupDiaryAnalysisSideEffectMocks() {
  setupNotificationServiceMocks();
  setupEmotionTrendNotificationMock();
  setupSafetyFollowupMock();
}

void teardownDiaryAnalysisSideEffectMocks() {
  NotificationSettingsService.resetForTesting();
  EmotionTrendNotificationService.resetForTesting();
  SafetyFollowupService.resetForTesting();
}

/// `unawaited(_triggerPostAnalysisNotifications)` 완료 대기.
///
/// tearDown에서 container.dispose() 전에 호출해야
/// ProviderContainer disposed 로그를 방지한다.
Future<void> drainPostAnalysisSideEffects() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  await Future<void>.delayed(const Duration(milliseconds: 50));
}