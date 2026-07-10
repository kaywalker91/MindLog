import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/self_encouragement_message.dart';
import '../observability/performance_traces.dart';
import 'analytics_service.dart';
import 'cheerme/cheer_me_message_selector.dart';
import 'cheerme/cheer_me_queue_planner.dart';
import 'cheerme/cheer_me_types.dart';
import 'crashlytics_service.dart';
import 'fcm_service.dart';
import 'notification_diff_planner.dart';
import 'notification_permission_service.dart';
import 'notification_service.dart';

export 'cheerme/cheer_me_types.dart' show CheerMeQueuePlan;

/// Facade: applySettings / permission / FCM + Cheer Me queue delegation.
///
/// Pure selection/queue algorithms live under `cheerme/`.
/// Keep `@visibleForTesting` static overrides for existing test adapters.
class NotificationSettingsService {
  NotificationSettingsService._();

  static const String mindcareTopic = 'mindlog_mindcare';
  static const String reminderPayload = '{"type":"cheerme"}';
  static const int cheerMePayloadVersion = 2;

  // ── 테스트 오버라이드 ──

  /// NotificationService.areNotificationsEnabled() 대체
  @visibleForTesting
  static Future<bool?> Function()? areNotificationsEnabledOverride;

  /// NotificationService.canScheduleExactAlarms() 대체
  @visibleForTesting
  static Future<bool?> Function()? canScheduleExactAlarmsOverride;

  /// NotificationPermissionService.isIgnoringBatteryOptimizations() 대체
  @visibleForTesting
  static Future<bool> Function()? isIgnoringBatteryOverride;

  /// NotificationService.scheduleCheerMeQueue() 대체
  @visibleForTesting
  static Future<bool> Function({
    required List<CheerMeScheduledNotification> notifications,
    required AndroidScheduleMode scheduleMode,
  })?
  scheduleCheerMeQueueOverride;

  /// NotificationService.cancelCheerMeQueue() 대체
  @visibleForTesting
  static Future<void> Function()? cancelCheerMeQueueOverride;

  /// NotificationService.cancelNotification(id) 대체 — diff 기반 cancel 검증용
  @visibleForTesting
  static Future<void> Function(int id)? cancelNotificationByIdOverride;

  /// NotificationService.getPendingNotifications() 대체
  @visibleForTesting
  static Future<List<PendingNotificationRequest>> Function()?
  getPendingNotificationsOverride;

  /// 구형 테스트 호환용: NotificationService.scheduleDailyReminder() 대체
  @visibleForTesting
  static Future<bool> Function({
    required int hour,
    required int minute,
    required String title,
    String? body,
    String? payload,
    AndroidScheduleMode? scheduleMode,
  })?
  scheduleDailyReminderOverride;

  /// 구형 테스트 호환용: NotificationService.cancelDailyReminder() 대체
  @visibleForTesting
  static Future<void> Function()? cancelDailyReminderOverride;

  /// FCMService.subscribeToTopic() 대체
  @visibleForTesting
  static Future<void> Function(String topic)? subscribeToTopicOverride;

  /// FCMService.unsubscribeFromTopic() 대체
  @visibleForTesting
  static Future<void> Function(String topic)? unsubscribeFromTopicOverride;

  /// NotificationService.scheduleWeeklyInsight() 대체
  @visibleForTesting
  static Future<bool> Function({required bool enabled})?
  scheduleWeeklyInsightOverride;

  /// AnalyticsService 호출 기록 (검증용)
  /// WARNING: Setting this to non-null disables production analytics/crashlytics
  @visibleForTesting
  static List<Map<String, dynamic>>? analyticsLog;

  /// 테스트 상태 리셋
  @visibleForTesting
  static void resetForTesting() {
    areNotificationsEnabledOverride = null;
    canScheduleExactAlarmsOverride = null;
    isIgnoringBatteryOverride = null;
    scheduleCheerMeQueueOverride = null;
    cancelCheerMeQueueOverride = null;
    cancelNotificationByIdOverride = null;
    getPendingNotificationsOverride = null;
    scheduleDailyReminderOverride = null;
    cancelDailyReminderOverride = null;
    subscribeToTopicOverride = null;
    unsubscribeFromTopicOverride = null;
    scheduleWeeklyInsightOverride = null;
    analyticsLog = null;
  }

  /// 권한 상태 확인 (platform channel 실패 시 안전한 기본값 사용)
  ///
  /// Returns: (notificationsEnabled, canScheduleExact, isIgnoringBattery)
  static Future<
    ({
      bool? notificationsEnabled,
      bool? canScheduleExact,
      bool isIgnoringBattery,
    })
  >
  _checkPermissions() async {
    bool? notificationsEnabled;
    bool? canScheduleExact;
    bool isIgnoringBattery = false;
    try {
      notificationsEnabled = areNotificationsEnabledOverride != null
          ? await areNotificationsEnabledOverride!()
          : await NotificationService.areNotificationsEnabled();
      canScheduleExact = canScheduleExactAlarmsOverride != null
          ? await canScheduleExactAlarmsOverride!()
          : await NotificationService.canScheduleExactAlarms();
      isIgnoringBattery = isIgnoringBatteryOverride != null
          ? await isIgnoringBatteryOverride!()
          : await NotificationPermissionService.isIgnoringBatteryOptimizations();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[NotificationSettings] Permission check failed: $e');
      }
      if (analyticsLog == null) {
        await CrashlyticsService.recordError(
          e,
          stackTrace,
          reason: 'notification_permission_check_failed',
        );
      } else {
        analyticsLog!.add({
          'event': 'permission_check_error',
          'error': e.toString(),
        });
      }
    }
    return (
      notificationsEnabled: notificationsEnabled,
      canScheduleExact: canScheduleExact,
      isIgnoringBattery: isIgnoringBattery,
    );
  }

  static Future<List<PendingNotificationRequest>>
  _loadPendingNotifications() async {
    if (getPendingNotificationsOverride != null) {
      return getPendingNotificationsOverride!();
    }
    if (scheduleCheerMeQueueOverride != null ||
        scheduleDailyReminderOverride != null ||
        analyticsLog != null) {
      return const [];
    }
    try {
      return await NotificationService.getPendingNotifications();
    } catch (_) {
      return const [];
    }
  }

  /// FCM 토픽 구독/해제 관리
  static Future<void> _manageFcmTopics(NotificationSettings settings) async {
    try {
      if (settings.isMindcareTopicEnabled) {
        if (subscribeToTopicOverride != null) {
          await subscribeToTopicOverride!(mindcareTopic);
        } else {
          await FCMService.subscribeToTopic(mindcareTopic);
        }
      } else {
        if (unsubscribeFromTopicOverride != null) {
          await unsubscribeFromTopicOverride!(mindcareTopic);
        } else {
          await FCMService.unsubscribeFromTopic(mindcareTopic);
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[NotificationSettings] FCM topic operation failed: $e');
      }
      if (analyticsLog == null) {
        await CrashlyticsService.recordError(
          e,
          stackTrace,
          reason: 'fcm_topic_subscription_error',
          fatal: false,
        );
        await AnalyticsService.logEvent(
          'fcm_topic_error',
          parameters: {
            'topic': mindcareTopic,
            'action': settings.isMindcareTopicEnabled
                ? 'subscribe'
                : 'unsubscribe',
            'error': e.toString(),
          },
        );
      } else {
        analyticsLog!.add({
          'event': 'fcm_topic_error',
          'topic': mindcareTopic,
          'action': settings.isMindcareTopicEnabled
              ? 'subscribe'
              : 'unsubscribe',
          'error': e.toString(),
        });
      }
    }
  }

  /// 알림 설정 적용
  ///
  /// [settings] 적용할 알림 설정
  /// [messages] 사용자가 작성한 응원 메시지 목록
  /// [source] 스케줄링 트리거 소스 ('user_toggle', 'app_start', 'time_change')
  ///
  /// Returns: 순차 모드에서 다음 미예약 커서
  static Future<int> applySettings(
    NotificationSettings settings, {
    List<SelfEncouragementMessage> messages = const [],
    String source = 'user_toggle',
    String? userName,
    double? recentEmotionScore,
  }) async {
    return PerformanceTraces.measure(
      PerformanceTraces.notificationApplySettings,
      () => _applySettingsInternal(
        settings,
        messages: messages,
        source: source,
        userName: userName,
        recentEmotionScore: recentEmotionScore,
      ),
      attributes: {'source': source},
    );
  }

  static Future<int> _applySettingsInternal(
    NotificationSettings settings, {
    required List<SelfEncouragementMessage> messages,
    required String source,
    String? userName,
    double? recentEmotionScore,
  }) async {
    var nextIndex = settings.lastDisplayedIndex;

    if (settings.isReminderEnabled && messages.isNotEmpty) {
      final pendingNotifications = await _loadPendingNotifications();
      final plan = buildCheerMeQueuePlan(
        settings,
        messages: messages,
        userName: userName,
        recentEmotionScore: recentEmotionScore,
        pendingNotifications: pendingNotifications,
      );
      nextIndex = plan.nextSequentialCursor;
      final diff = diffCheerMeQueue(
        pending: pendingNotifications,
        plan: plan.notifications,
      );

      if (diff.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[NotificationSettings] ✨ Queue unchanged — skipping platform calls (saved ${NotificationService.cheerMeQueueLength * 2} calls)',
          );
        }
        if (analyticsLog != null) {
          analyticsLog!.add({
            'event': 'reminder_unchanged',
            'source': source,
            'queue_size': plan.notifications.length,
          });
        }
        await _manageFcmTopics(settings);
        await _manageWeeklyInsight(settings);
        return nextIndex;
      }

      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] ═══════════════════════════════════════',
        );
        debugPrint('[NotificationSettings] 📅 Scheduling Cheer Me Queue');
        debugPrint(
          '[NotificationSettings] ═══════════════════════════════════════',
        );
        debugPrint(
          '[NotificationSettings] Time: ${settings.reminderHour}:${settings.reminderMinute.toString().padLeft(2, '0')}',
        );
        debugPrint('[NotificationSettings] Source: $source');
        debugPrint(
          '[NotificationSettings] First message: "${plan.firstNotification?.body ?? "none"}"',
        );
        debugPrint(
          '[NotificationSettings] Mode: ${settings.rotationMode.name}',
        );
        debugPrint('[NotificationSettings] Total messages: ${messages.length}');
        debugPrint(
          '[NotificationSettings] Queue size: ${plan.notifications.length}',
        );
      }

      final permissions = await _checkPermissions();
      final notificationsEnabled = permissions.notificationsEnabled;
      final canScheduleExact = permissions.canScheduleExact;
      final isIgnoringBattery = permissions.isIgnoringBattery;

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

      final scheduleMode = (canScheduleExact == true)
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings]   • Schedule Mode: ${canScheduleExact == true ? "EXACT" : "INEXACT (fallback)"}',
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings]   • Diff: cancel=${diff.idsToCancel.length}, schedule=${diff.toSchedule.length}',
        );
      }

      final success = await _applyCheerMeQueueDiff(
        diff,
        scheduleMode: scheduleMode,
      );

      final scheduleModeLabel = canScheduleExact == true ? 'exact' : 'inexact';

      if (success) {
        if (analyticsLog != null) {
          analyticsLog!.add({
            'event': 'reminder_scheduled',
            'hour': settings.reminderHour,
            'minute': settings.reminderMinute,
            'source': source,
            'schedule_mode': scheduleModeLabel,
            'timezone': tz.local.name,
            'queue_size': plan.notifications.length,
          });
        } else {
          await AnalyticsService.logReminderScheduled(
            hour: settings.reminderHour,
            minute: settings.reminderMinute,
            source: source,
            scheduleMode: scheduleModeLabel,
            timezoneName: tz.local.name,
          );
        }

        if (kDebugMode) {
          debugPrint('[NotificationSettings] ✅ Queue scheduled successfully');
        }
      } else {
        if (analyticsLog != null) {
          analyticsLog!.add({
            'event': 'reminder_schedule_failed',
            'errorType': 'schedule_returned_false',
          });
        } else {
          await AnalyticsService.logReminderScheduleFailed(
            errorType: 'schedule_returned_false',
          );
        }

        if (kDebugMode) {
          debugPrint('[NotificationSettings] ❌ Queue schedule failed');
        }
      }

      if (kDebugMode && analyticsLog == null) {
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
        if (messages.isEmpty && settings.isReminderEnabled) {
          debugPrint(
            '[NotificationSettings] 🔕 No messages to schedule - cancelling',
          );
        } else {
          debugPrint('[NotificationSettings] 🔕 Cancelling Cheer Me queue');
        }
      }
      await _cancelCheerMeQueue();

      if (analyticsLog != null) {
        analyticsLog!.add({'event': 'reminder_cancelled', 'source': source});
      } else {
        await AnalyticsService.logReminderCancelled(source: source);
      }
    }

    await _manageFcmTopics(settings);
    await _manageWeeklyInsight(settings);

    return nextIndex;
  }

  static Future<bool> _applyCheerMeQueueDiff(
    NotificationQueueDiff diff, {
    required AndroidScheduleMode scheduleMode,
  }) async {
    // Resilient cancel: per-item, continue on error (P1-4)
    for (final id in diff.idsToCancel) {
      try {
        if (cancelNotificationByIdOverride != null) {
          await cancelNotificationByIdOverride!(id);
        } else if (cancelDailyReminderOverride != null) {
          await cancelDailyReminderOverride!();
        } else {
          await NotificationService.cancelNotification(id);
        }
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('[NotificationSettings] Cancel failed for id=$id: $e');
        }
        if (analyticsLog == null) {
          await CrashlyticsService.recordError(
            e,
            stack,
            reason: 'cheerme_cancel_partial_failure',
            fatal: false,
          );
        }
      }
    }

    if (scheduleCheerMeQueueOverride != null) {
      return scheduleCheerMeQueueOverride!(
        notifications: diff.toSchedule,
        scheduleMode: scheduleMode,
      );
    }

    if (scheduleDailyReminderOverride != null) {
      var success = true;
      for (final notification in diff.toSchedule) {
        try {
          final scheduled = await scheduleDailyReminderOverride!(
            hour: notification.scheduledDate.hour,
            minute: notification.scheduledDate.minute,
            title: notification.title,
            body: notification.body,
            payload: notification.payload,
            scheduleMode: scheduleMode,
          );
          success = success && scheduled;
        } catch (e, stack) {
          if (kDebugMode) {
            debugPrint(
              '[NotificationSettings] Schedule failed for ${notification.id}: $e',
            );
          }
          success = false;
          if (analyticsLog == null) {
            await CrashlyticsService.recordError(
              e,
              stack,
              reason: 'cheerme_schedule_partial_failure',
              fatal: false,
            );
          }
        }
      }
      return success;
    }

    // Resilient schedule: per-item try, continue on error (P1-4)
    var success = true;
    for (final notification in diff.toSchedule) {
      try {
        final scheduled = await NotificationService.scheduleOneTimeNotification(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          scheduledDate: notification.scheduledDate,
          payload: notification.payload,
          channel: NotificationService.channelCheerMe,
          scheduleMode: scheduleMode,
        );
        success = success && scheduled;
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint(
            '[NotificationSettings] Schedule failed for ${notification.id}: $e',
          );
        }
        success = false;
        if (analyticsLog == null) {
          await CrashlyticsService.recordError(
            e,
            stack,
            reason: 'cheerme_schedule_partial_failure',
            fatal: false,
          );
        }
      }
    }
    return success;
  }

  static Future<void> _cancelCheerMeQueue() async {
    if (cancelCheerMeQueueOverride != null) {
      await cancelCheerMeQueueOverride!();
      return;
    }
    if (cancelDailyReminderOverride != null) {
      await cancelDailyReminderOverride!();
      return;
    }
    await NotificationService.cancelCheerMeQueue();
  }

  /// 주간 인사이트 알림 관리
  static Future<void> _manageWeeklyInsight(
    NotificationSettings settings,
  ) async {
    try {
      final success = scheduleWeeklyInsightOverride != null
          ? await scheduleWeeklyInsightOverride!(
              enabled: settings.isWeeklyInsightEnabled,
            )
          : await NotificationService.scheduleWeeklyInsight(
              enabled: settings.isWeeklyInsightEnabled,
            );

      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] Weekly insight: ${settings.isWeeklyInsightEnabled ? "enabled" : "disabled"}, success: $success',
        );
      }

      if (analyticsLog != null) {
        analyticsLog!.add({
          'event': settings.isWeeklyInsightEnabled
              ? 'weekly_insight_scheduled'
              : 'weekly_insight_cancelled',
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] Weekly insight operation failed: $e',
        );
      }
      if (analyticsLog == null) {
        await CrashlyticsService.recordError(
          e,
          stackTrace,
          reason: 'weekly_insight_schedule_error',
          fatal: false,
        );
      } else {
        analyticsLog!.add({
          'event': 'weekly_insight_error',
          'error': e.toString(),
        });
      }
    }
  }

  @visibleForTesting
  static CheerMeQueuePlan buildCheerMeQueuePlan(
    NotificationSettings settings, {
    required List<SelfEncouragementMessage> messages,
    String? userName,
    double? recentEmotionScore,
    List<PendingNotificationRequest> pendingNotifications = const [],
    tz.TZDateTime? now,
  }) {
    return CheerMeQueuePlanner.buildPlan(
      settings,
      messages: messages,
      payloadVersion: cheerMePayloadVersion,
      userName: userName,
      recentEmotionScore: recentEmotionScore,
      pendingNotifications: pendingNotifications,
      now: now,
    );
  }

  static bool requiresCheerMeQueueRebuild(
    NotificationSettings settings, {
    required List<SelfEncouragementMessage> messages,
    required List<PendingNotificationRequest> pendingNotifications,
    String? userName,
  }) {
    return CheerMeQueuePlanner.requiresRebuild(
      settings,
      messages: messages,
      pendingNotifications: pendingNotifications,
      payloadVersion: cheerMePayloadVersion,
      userName: userName,
    );
  }

  static Future<CheerMeScheduledNotification?> loadNextCheerMePreview(
    NotificationSettings settings, {
    required List<SelfEncouragementMessage> messages,
    String? userName,
    double? recentEmotionScore,
  }) async {
    if (!settings.isReminderEnabled || messages.isEmpty) {
      return null;
    }

    final pendingNotifications = await _loadPendingNotifications();
    if (!requiresCheerMeQueueRebuild(
      settings,
      messages: messages,
      pendingNotifications: pendingNotifications,
      userName: userName,
    )) {
      final pendingPreview = CheerMeQueuePlanner.buildPreviewFromPending(
        pendingNotifications,
      );
      if (pendingPreview != null) {
        return pendingPreview;
      }
    }

    final plan = buildCheerMeQueuePlan(
      settings,
      messages: messages,
      userName: userName,
      recentEmotionScore: recentEmotionScore,
      pendingNotifications: pendingNotifications,
    );
    return plan.firstNotification;
  }

  /// 설정에 따라 메시지 선택 (legacy Random 경로 — seed 사용 금지).
  ///
  /// [messages]는 이미 displayOrder 순으로 정렬된 상태로 전달되어야 합니다.
  @visibleForTesting
  static SelfEncouragementMessage? selectMessage(
    NotificationSettings settings,
    List<SelfEncouragementMessage> messages, {
    double? recentEmotionScore,
    DateTime? now,
  }) {
    return CheerMeMessageSelector.selectMessage(
      settings,
      messages,
      recentEmotionScore: recentEmotionScore,
      now: now,
    );
  }

  /// 시간(0-23)을 시간대 카테고리 문자열로 변환
  @visibleForTesting
  static String timeCategory(int hour) =>
      CheerMeMessageSelector.timeCategory(hour);
}
