import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/entities/notification_settings.dart';
import 'analytics_service.dart';
import 'fcm_service.dart';
import 'notification_permission_service.dart';
import 'notification_service.dart';

class NotificationSettingsService {
  NotificationSettingsService._();

  static const String mindcareTopic = 'mindlog_mindcare';
  static const String reminderPayload = '{"type":"reminder"}';

  /// 알림 설정 적용
  ///
  /// [settings] 적용할 알림 설정
  /// [source] 스케줄링 트리거 소스 ('user_toggle', 'app_start', 'time_change')
  static Future<void> applySettings(
    NotificationSettings settings, {
    String source = 'user_toggle',
  }) async {
    if (settings.isReminderEnabled) {
      // 상세 로깅 (항상 출력)
      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] ═══════════════════════════════════════',
        );
        debugPrint('[NotificationSettings] 📅 Scheduling Daily Reminder');
        debugPrint(
          '[NotificationSettings] ═══════════════════════════════════════',
        );
        debugPrint(
          '[NotificationSettings] Time: ${settings.reminderHour}:${settings.reminderMinute.toString().padLeft(2, '0')}',
        );
        debugPrint('[NotificationSettings] Source: $source');
      }

      // 권한 상태 확인
      final notificationsEnabled =
          await NotificationService.areNotificationsEnabled();
      final canScheduleExact =
          await NotificationService.canScheduleExactAlarms();
      final isIgnoringBattery =
          await NotificationPermissionService.isIgnoringBatteryOptimizations();

      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] ─────────────────────────────────────────',
        );
        debugPrint('[NotificationSettings] 🔐 Permission Status:');
        debugPrint(
          '[NotificationSettings]   • POST_NOTIFICATIONS: ${notificationsEnabled == true ? "✅" : "❌"} ($notificationsEnabled)',
        );
        debugPrint(
          '[NotificationSettings]   • SCHEDULE_EXACT_ALARM: ${canScheduleExact == true ? "✅" : "❌"} ($canScheduleExact)',
        );
        debugPrint(
          '[NotificationSettings]   • Battery Optimization Ignored: ${isIgnoringBattery ? "✅" : "❌"} ($isIgnoringBattery)',
        );
        debugPrint(
          '[NotificationSettings] ─────────────────────────────────────────',
        );
      }

      // 경고 출력
      if (kDebugMode) {
        if (notificationsEnabled != true) {
          debugPrint(
            '[NotificationSettings] ⚠️ WARNING: Notifications are disabled!',
          );
        }
        if (canScheduleExact != true) {
          debugPrint(
            '[NotificationSettings] ⚠️ WARNING: Exact alarm permission denied - alarm may be delayed!',
          );
        }
        if (!isIgnoringBattery) {
          debugPrint(
            '[NotificationSettings] ⚠️ WARNING: Battery optimization active - alarm may be suppressed!',
          );
        }
      }

      // 권한 기반 스케줄 모드 자동 선택 (Android 14+ 대응)
      // exact alarm 권한이 없으면 inexact 모드로 fallback (최대 15분 지연)
      final scheduleMode = (canScheduleExact == true)
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings]   • Schedule Mode: ${canScheduleExact == true ? "EXACT" : "INEXACT (fallback)"}',
        );
      }

      // 스케줄링 실행
      final success = await NotificationService.scheduleDailyReminder(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
        payload: reminderPayload,
        scheduleMode: scheduleMode,
      );

      if (success) {
        // Analytics 이벤트: 스케줄링 성공
        await AnalyticsService.logReminderScheduled(
          hour: settings.reminderHour,
          minute: settings.reminderMinute,
          source: source,
        );

        if (kDebugMode) {
          debugPrint(
            '[NotificationSettings] ✅ Schedule call completed successfully',
          );
        }
      } else {
        // Analytics 이벤트: 스케줄링 실패
        await AnalyticsService.logReminderScheduleFailed(
          errorType: 'schedule_returned_false',
        );

        if (kDebugMode) {
          debugPrint(
            '[NotificationSettings] ❌ Schedule failed (returned false)',
          );
        }
        // 크래시 방지: rethrow 제거 - 설정은 저장됨, 스케줄링만 실패
      }

      // 예약된 알림 확인
      if (kDebugMode) {
        final pending = await NotificationService.getPendingNotifications();
        debugPrint(
          '[NotificationSettings] ─────────────────────────────────────────',
        );
        debugPrint(
          '[NotificationSettings] 📋 Pending Notifications: ${pending.length}',
        );
        for (final notification in pending) {
          debugPrint(
            '[NotificationSettings]   • ID: ${notification.id}, Title: ${notification.title}',
          );
        }
        debugPrint(
          '[NotificationSettings] ═══════════════════════════════════════',
        );
      }
    } else {
      if (kDebugMode) {
        debugPrint('[NotificationSettings] 🔕 Cancelling daily reminder');
      }
      await NotificationService.cancelDailyReminder();

      // Analytics 이벤트: 리마인더 취소
      await AnalyticsService.logReminderCancelled(source: source);
    }

    if (settings.isMindcareTopicEnabled) {
      await FCMService.subscribeToTopic(mindcareTopic);
    } else {
      await FCMService.unsubscribeFromTopic(mindcareTopic);
    }
  }
}
