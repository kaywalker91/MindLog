import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/self_encouragement_message.dart';
import '../constants/notification_messages.dart';
import 'analytics_service.dart';
import 'crashlytics_service.dart';
import 'fcm_service.dart';
import 'notification_permission_service.dart';
import 'notification_service.dart';

class CheerMeQueuePlan {
  const CheerMeQueuePlan({
    required this.notifications,
    required this.nextSequentialCursor,
    required this.signature,
  });

  final List<CheerMeScheduledNotification> notifications;
  final int nextSequentialCursor;
  final String signature;

  CheerMeScheduledNotification? get firstNotification =>
      notifications.isEmpty ? null : notifications.first;
}

class _IndexedMessage {
  const _IndexedMessage({required this.index, required this.message});

  final int index;
  final SelfEncouragementMessage message;
}

class _CheerMeSelection {
  const _CheerMeSelection({required this.index, required this.message});

  final int index;
  final SelfEncouragementMessage message;
}

class _ParsedCheerMePayload {
  const _ParsedCheerMePayload({
    required this.id,
    required this.payload,
    required this.title,
    required this.body,
    required this.version,
    required this.signature,
    required this.scheduledFor,
    required this.sequenceCursor,
    required this.messageId,
  });

  final int id;
  final String payload;
  final String? title;
  final String? body;
  final int? version;
  final String? signature;
  final DateTime? scheduledFor;
  final int? sequenceCursor;
  final String? messageId;
}

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

      final success = await _scheduleCheerMeQueue(
        plan.notifications,
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

  static Future<bool> _scheduleCheerMeQueue(
    List<CheerMeScheduledNotification> notifications, {
    required AndroidScheduleMode scheduleMode,
  }) async {
    if (scheduleCheerMeQueueOverride != null) {
      return scheduleCheerMeQueueOverride!(
        notifications: notifications,
        scheduleMode: scheduleMode,
      );
    }

    if (scheduleDailyReminderOverride != null) {
      var success = true;
      for (final notification in notifications) {
        final scheduled = await scheduleDailyReminderOverride!(
          hour: notification.scheduledDate.hour,
          minute: notification.scheduledDate.minute,
          title: notification.title,
          body: notification.body,
          payload: notification.payload,
          scheduleMode: scheduleMode,
        );
        success = success && scheduled;
      }
      return success;
    }

    return NotificationService.scheduleCheerMeQueue(
      notifications: notifications,
      scheduleMode: scheduleMode,
    );
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
    final sortedMessages = [...messages]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final signature = _buildCheerMeSignature(
      settings,
      sortedMessages,
      userName,
    );

    if (sortedMessages.isEmpty) {
      return CheerMeQueuePlan(
        notifications: const [],
        nextSequentialCursor: settings.lastDisplayedIndex,
        signature: signature,
      );
    }

    final currentTime = now ?? tz.TZDateTime.now(tz.local);
    final firstScheduledDate = _nextReminderDate(settings, currentTime);
    final parsedPending = _parsePendingCheerMeNotifications(
      pendingNotifications,
    );

    var rollingCursor = _resolveSequentialStartCursor(
      settings,
      sortedMessages,
      parsedPending,
    );

    final notifications = <CheerMeScheduledNotification>[];
    for (var i = 0; i < NotificationService.cheerMeQueueLength; i++) {
      final scheduledDate = firstScheduledDate.add(Duration(days: i));
      final selection = _selectMessageForSchedule(
        settings,
        sortedMessages,
        scheduledDate: scheduledDate,
        signature: signature,
        recentEmotionScore: recentEmotionScore,
        sequentialCursor: rollingCursor,
      );

      final title = _selectCheerMeTitle(
        userName,
        '${signature}_${scheduledDate.toIso8601String()}_${selection.index}',
      );
      final body = NotificationMessages.applyNamePersonalization(
        selection.message.content,
        userName,
      );
      final payload = _buildCheerMePayload(
        scheduledDate: scheduledDate,
        sequenceCursor: selection.index,
        messageId: selection.message.id,
        signature: signature,
      );

      notifications.add(
        CheerMeScheduledNotification(
          id: NotificationService.cheerMeNotificationIds[i],
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          payload: payload,
        ),
      );

      if (settings.rotationMode == MessageRotationMode.sequential) {
        rollingCursor = NotificationSettings.nextIndex(
          selection.index,
          sortedMessages.length,
        );
      }
    }

    return CheerMeQueuePlan(
      notifications: notifications,
      nextSequentialCursor:
          settings.rotationMode == MessageRotationMode.sequential
          ? rollingCursor
          : settings.lastDisplayedIndex,
      signature: signature,
    );
  }

  static bool requiresCheerMeQueueRebuild(
    NotificationSettings settings, {
    required List<SelfEncouragementMessage> messages,
    required List<PendingNotificationRequest> pendingNotifications,
    String? userName,
  }) {
    if (!settings.isReminderEnabled || messages.isEmpty) {
      return false;
    }

    final cheerMePending = pendingNotifications
        .where(
          (notification) => NotificationService.isCheerMeId(notification.id),
        )
        .toList();

    if (cheerMePending.length != NotificationService.cheerMeQueueLength) {
      return true;
    }

    if (cheerMePending.map((item) => item.id).toSet().length !=
        NotificationService.cheerMeQueueLength) {
      return true;
    }

    final expectedSignature = _buildCheerMeSignature(
      settings,
      [...messages]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
      userName,
    );

    for (final notification in cheerMePending) {
      if (notification.title?.contains('{name}') ?? false) {
        return true;
      }

      final parsed = _parseCheerMePayload(notification);
      if (parsed == null ||
          parsed.version != cheerMePayloadVersion ||
          parsed.signature != expectedSignature ||
          parsed.scheduledFor == null) {
        return true;
      }
    }

    return false;
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
      final pendingPreview = _buildPreviewFromPending(pendingNotifications);
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

  static CheerMeScheduledNotification? _buildPreviewFromPending(
    List<PendingNotificationRequest> pendingNotifications,
  ) {
    final parsed = _parsePendingCheerMeNotifications(pendingNotifications);
    if (parsed.isEmpty) return null;

    final earliest = parsed.firstWhere(
      (item) => item.scheduledFor != null,
      orElse: () => parsed.first,
    );

    if (earliest.scheduledFor == null ||
        earliest.title == null ||
        earliest.body == null) {
      return null;
    }

    return CheerMeScheduledNotification(
      id: earliest.id,
      title: earliest.title!,
      body: earliest.body!,
      scheduledDate: tz.TZDateTime.from(earliest.scheduledFor!, tz.local),
      payload: earliest.payload,
    );
  }

  static List<_ParsedCheerMePayload> _parsePendingCheerMeNotifications(
    List<PendingNotificationRequest> pendingNotifications,
  ) {
    final parsed =
        pendingNotifications
            .where(
              (notification) =>
                  NotificationService.isCheerMeId(notification.id),
            )
            .map(_parseCheerMePayload)
            .whereType<_ParsedCheerMePayload>()
            .toList()
          ..sort((a, b) {
            final aTime = a.scheduledFor;
            final bTime = b.scheduledFor;
            if (aTime == null && bTime == null) {
              return a.id.compareTo(b.id);
            }
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return aTime.compareTo(bTime);
          });
    return parsed;
  }

  static _ParsedCheerMePayload? _parseCheerMePayload(
    PendingNotificationRequest notification,
  ) {
    final rawPayload = notification.payload;
    if (rawPayload == null || rawPayload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['type']?.toString() != 'cheerme') return null;

      final version = decoded['v'] is int
          ? decoded['v'] as int
          : int.tryParse(decoded['v']?.toString() ?? '');
      final sequenceCursor = decoded['sequenceCursor'] is int
          ? decoded['sequenceCursor'] as int
          : int.tryParse(decoded['sequenceCursor']?.toString() ?? '');

      return _ParsedCheerMePayload(
        id: notification.id,
        payload: rawPayload,
        title: notification.title,
        body: notification.body,
        version: version,
        signature: decoded['signature']?.toString(),
        scheduledFor: DateTime.tryParse(
          decoded['scheduledFor']?.toString() ?? '',
        ),
        sequenceCursor: sequenceCursor,
        messageId: decoded['messageId']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  static int _resolveSequentialStartCursor(
    NotificationSettings settings,
    List<SelfEncouragementMessage> messages,
    List<_ParsedCheerMePayload> pendingNotifications,
  ) {
    if (settings.rotationMode != MessageRotationMode.sequential ||
        messages.isEmpty) {
      return settings.lastDisplayedIndex;
    }

    if (pendingNotifications.isNotEmpty) {
      final earliest = pendingNotifications.first;
      if (earliest.messageId != null) {
        final messageIndex = messages.indexWhere(
          (message) => message.id == earliest.messageId,
        );
        if (messageIndex >= 0) {
          return messageIndex;
        }
      }
    }

    return NotificationSettings.currentIndex(
      settings.lastDisplayedIndex,
      messages.length,
    );
  }

  static tz.TZDateTime _nextReminderDate(
    NotificationSettings settings,
    tz.TZDateTime now,
  ) {
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      settings.reminderHour,
      settings.reminderMinute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static _CheerMeSelection _selectMessageForSchedule(
    NotificationSettings settings,
    List<SelfEncouragementMessage> messages, {
    required tz.TZDateTime scheduledDate,
    required String signature,
    required int sequentialCursor,
    double? recentEmotionScore,
  }) {
    switch (settings.rotationMode) {
      case MessageRotationMode.random:
        return _selectDeterministicRandomMessage(
          messages,
          seed: 'random_${signature}_${scheduledDate.toIso8601String()}',
        );
      case MessageRotationMode.sequential:
        final index = NotificationSettings.currentIndex(
          sequentialCursor,
          messages.length,
        );
        return _CheerMeSelection(index: index, message: messages[index]);
      case MessageRotationMode.emotionAware:
        return _selectDeterministicEmotionAwareMessage(
          messages,
          recentEmotionScore,
          seed: 'emotion_${signature}_${scheduledDate.toIso8601String()}',
        );
      case MessageRotationMode.timeAware:
        return _selectDeterministicTimeAwareMessage(
          messages,
          scheduledDate,
          seed: 'time_${signature}_${scheduledDate.toIso8601String()}',
        );
    }
  }

  static _CheerMeSelection _selectDeterministicRandomMessage(
    List<SelfEncouragementMessage> messages, {
    required String seed,
  }) {
    final index = _stableModulo(seed, messages.length);
    return _CheerMeSelection(index: index, message: messages[index]);
  }

  static _CheerMeSelection _selectDeterministicTimeAwareMessage(
    List<SelfEncouragementMessage> messages,
    DateTime scheduledDate, {
    required String seed,
  }) {
    final category = _timeCategory(scheduledDate.hour);
    final filtered = <_IndexedMessage>[];

    for (var i = 0; i < messages.length; i++) {
      if (messages[i].timeCategory == category) {
        filtered.add(_IndexedMessage(index: i, message: messages[i]));
      }
    }

    final pool = filtered.isEmpty
        ? [
            for (var i = 0; i < messages.length; i++)
              _IndexedMessage(index: i, message: messages[i]),
          ]
        : filtered;

    final selected = pool[_stableModulo(seed, pool.length)];
    return _CheerMeSelection(index: selected.index, message: selected.message);
  }

  static _CheerMeSelection _selectDeterministicEmotionAwareMessage(
    List<SelfEncouragementMessage> messages,
    double? recentEmotionScore, {
    required String seed,
  }) {
    if (recentEmotionScore == null) {
      return _selectDeterministicRandomMessage(messages, seed: seed);
    }

    final weights = <int>[];
    for (final msg in messages) {
      if (msg.writtenEmotionScore == null) {
        weights.add(1);
      } else {
        final distance = (msg.writtenEmotionScore! - recentEmotionScore).abs();
        if (distance <= 1.0) {
          weights.add(3);
        } else if (distance <= 3.0) {
          weights.add(2);
        } else {
          weights.add(1);
        }
      }
    }

    final totalWeight = weights.fold(0, (sum, value) => sum + value);
    var pick = _stableModulo(seed, totalWeight);
    for (var i = 0; i < messages.length; i++) {
      if (pick < weights[i]) {
        return _CheerMeSelection(index: i, message: messages[i]);
      }
      pick -= weights[i];
    }

    return _CheerMeSelection(
      index: messages.length - 1,
      message: messages.last,
    );
  }

  static String _buildCheerMeSignature(
    NotificationSettings settings,
    List<SelfEncouragementMessage> messages,
    String? userName,
  ) {
    final payload = jsonEncode({
      'v': cheerMePayloadVersion,
      'queueLength': NotificationService.cheerMeQueueLength,
      'reminderHour': settings.reminderHour,
      'reminderMinute': settings.reminderMinute,
      'rotationMode': settings.rotationMode.name,
      'userName': userName ?? '',
      'timezone': tz.local.name,
      'messages': [
        for (final message in messages)
          {
            'id': message.id,
            'content': message.content,
            'displayOrder': message.displayOrder,
            'timeCategory': message.timeCategory,
            'writtenEmotionScore': message.writtenEmotionScore,
          },
      ],
    });
    return sha1.convert(utf8.encode(payload)).toString();
  }

  static String _buildCheerMePayload({
    required tz.TZDateTime scheduledDate,
    required int sequenceCursor,
    required String messageId,
    required String signature,
  }) {
    return jsonEncode({
      'type': 'cheerme',
      'v': cheerMePayloadVersion,
      'scheduledFor': scheduledDate.toIso8601String(),
      'sequenceCursor': sequenceCursor,
      'messageId': messageId,
      'signature': signature,
    });
  }

  static String _selectCheerMeTitle(String? userName, String seed) {
    final templates = NotificationMessages.cheerMeTitles;
    final index = _stableModulo(seed, templates.length);
    return NotificationMessages.applyNamePersonalization(
      templates[index],
      userName,
    );
  }

  static int _stableModulo(String seed, int length) {
    if (length <= 1) return 0;
    final digest = sha1.convert(utf8.encode(seed)).bytes;
    var value = 0;
    for (final byte in digest.take(4)) {
      value = (value << 8) + byte;
    }
    return value % length;
  }

  /// 설정에 따라 메시지 선택
  ///
  /// [messages]는 이미 displayOrder 순으로 정렬된 상태로 전달되어야 합니다.
  /// (SelfEncouragementController에서 정렬 후 전달)
  @visibleForTesting
  static SelfEncouragementMessage? selectMessage(
    NotificationSettings settings,
    List<SelfEncouragementMessage> messages, {
    double? recentEmotionScore,
    DateTime? now,
  }) {
    if (messages.isEmpty) return null;

    switch (settings.rotationMode) {
      case MessageRotationMode.random:
        return messages[Random().nextInt(messages.length)];
      case MessageRotationMode.sequential:
        final index = NotificationSettings.currentIndex(
          settings.lastDisplayedIndex,
          messages.length,
        );
        return messages[index];
      case MessageRotationMode.emotionAware:
        return _selectEmotionAwareMessage(messages, recentEmotionScore);
      case MessageRotationMode.timeAware:
        return _selectTimeAwareMessage(messages, now);
    }
  }

  /// 시간대 기반 메시지 선택
  ///
  /// morning(5-11), afternoon(12-17), evening(18-23, 0-4)
  /// 매칭 메시지 없으면 전체 풀 폴백
  static SelfEncouragementMessage _selectTimeAwareMessage(
    List<SelfEncouragementMessage> messages,
    DateTime? now,
  ) {
    final hour = (now ?? DateTime.now()).hour;
    final category = _timeCategory(hour);
    final filtered = messages
        .where((message) => message.timeCategory == category)
        .toList();
    final pool = filtered.isEmpty ? messages : filtered;
    return pool[Random().nextInt(pool.length)];
  }

  /// 시간(0-23)을 시간대 카테고리 문자열로 변환
  @visibleForTesting
  static String timeCategory(int hour) => _timeCategory(hour);

  static String _timeCategory(int hour) {
    if (hour >= 5 && hour <= 11) return 'morning';
    if (hour >= 12 && hour <= 17) return 'afternoon';
    return 'evening';
  }

  /// 감정 기반 가중치 메시지 선택
  ///
  /// writtenEmotionScore와 recentEmotionScore의 거리 기반 가중치:
  /// - 거리 ≤ 1.0 → 3배 (매우 유사한 감정)
  /// - 거리 ≤ 3.0 → 2배 (비슷한 감정)
  /// - 그 외 → 1배 (기본)
  /// - writtenEmotionScore 없는 메시지 → 1배
  /// - recentEmotionScore 없으면 → 랜덤 폴백
  static SelfEncouragementMessage _selectEmotionAwareMessage(
    List<SelfEncouragementMessage> messages,
    double? recentEmotionScore,
  ) {
    if (recentEmotionScore == null) {
      return messages[Random().nextInt(messages.length)];
    }

    final weights = <int>[];
    for (final msg in messages) {
      if (msg.writtenEmotionScore == null) {
        weights.add(1);
      } else {
        final distance = (msg.writtenEmotionScore! - recentEmotionScore).abs();
        if (distance <= 1.0) {
          weights.add(3);
        } else if (distance <= 3.0) {
          weights.add(2);
        } else {
          weights.add(1);
        }
      }
    }

    final totalWeight = weights.fold(0, (sum, value) => sum + value);
    var pick = Random().nextInt(totalWeight);
    for (var i = 0; i < messages.length; i++) {
      pick -= weights[i];
      if (pick < 0) return messages[i];
    }
    return messages.last;
  }
}
