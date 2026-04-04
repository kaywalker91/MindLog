import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../constants/notification_messages.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/self_encouragement_message.dart';
import 'analytics_service.dart';
import 'crashlytics_service.dart';
import 'fcm_service.dart';
import 'notification_permission_service.dart';
import 'notification_service.dart';

class NotificationSettingsService {
  NotificationSettingsService._();

  static const String mindcareTopic = 'mindlog_mindcare';
  static const String reminderPayload = '{"type":"cheerme"}';

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

  /// NotificationService.scheduleDailyReminder() 대체
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

  /// NotificationService.cancelDailyReminder() 대체
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
  /// Returns: 순차 모드에서 다음 표시할 메시지 인덱스 (랜덤 모드에서는 현재값 유지)
  static Future<int> applySettings(
    NotificationSettings settings, {
    List<SelfEncouragementMessage> messages = const [],
    String source = 'user_toggle',
    String? userName,
    double? recentEmotionScore,
  }) async {
    var nextIndex = settings.lastDisplayedIndex;
    if (settings.isReminderEnabled && messages.isNotEmpty) {
      // 메시지 선택
      final selectedMessage = selectMessage(
        settings,
        messages,
        recentEmotionScore: recentEmotionScore,
      );
      if (selectedMessage != null) {
        // 순차 모드에서 다음 인덱스 계산
        if (settings.rotationMode == MessageRotationMode.sequential) {
          nextIndex = NotificationSettings.nextIndex(
            settings.lastDisplayedIndex,
            messages.length,
          );
        }
      }

      // 상세 로깅 (항상 출력)
      if (kDebugMode) {
        debugPrint(
          '[NotificationSettings] ═══════════════════════════════════════',
        );
        debugPrint('[NotificationSettings] 📅 Scheduling Self Encouragement');
        debugPrint(
          '[NotificationSettings] ═══════════════════════════════════════',
        );
        debugPrint(
          '[NotificationSettings] Time: ${settings.reminderHour}:${settings.reminderMinute.toString().padLeft(2, '0')}',
        );
        debugPrint('[NotificationSettings] Source: $source');
        debugPrint(
          '[NotificationSettings] Message: "${selectedMessage?.content ?? "none"}"',
        );
        debugPrint(
          '[NotificationSettings] Mode: ${settings.rotationMode.name}',
        );
        debugPrint('[NotificationSettings] Total messages: ${messages.length}');
      }

      // 권한 상태 확인
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

      // 이름 개인화 적용
      final personalizedBody = selectedMessage?.content != null
          ? NotificationMessages.applyNamePersonalization(
              selectedMessage!.content,
              userName,
            )
          : null;

      // 알림 제목 개인화 (Cheer Me 전용 제목 템플릿 사용)
      final cheerMeTitle = NotificationMessages.getCheerMeTitle(userName);

      // 스케줄링 실행 (사용자 메시지 사용)
      final success = scheduleDailyReminderOverride != null
          ? await scheduleDailyReminderOverride!(
              hour: settings.reminderHour,
              minute: settings.reminderMinute,
              title: cheerMeTitle,
              body: personalizedBody,
              payload: reminderPayload,
              scheduleMode: scheduleMode,
            )
          : await NotificationService.scheduleDailyReminder(
              hour: settings.reminderHour,
              minute: settings.reminderMinute,
              title: cheerMeTitle,
              body: personalizedBody,
              payload: reminderPayload,
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
          debugPrint(
            '[NotificationSettings] ✅ Schedule call completed successfully',
          );
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
          debugPrint(
            '[NotificationSettings] ❌ Schedule failed (returned false)',
          );
        }
      }

      // 예약된 알림 확인 (테스트 모드에서는 skip)
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
          debugPrint('[NotificationSettings] 🔕 Cancelling daily reminder');
        }
      }
      if (cancelDailyReminderOverride != null) {
        await cancelDailyReminderOverride!();
      } else {
        await NotificationService.cancelDailyReminder();
      }

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

    // Note: messages는 이미 정렬된 상태 (Controller에서 displayOrder 순 정렬)
    // 불필요한 리스트 복사 및 재정렬 제거
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
    final filtered =
        messages.where((m) => m.timeCategory == category).toList();
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
    // 최근 감정 점수가 없으면 랜덤 폴백
    if (recentEmotionScore == null) {
      return messages[Random().nextInt(messages.length)];
    }

    // 가중치 계산
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

    // 가중치 기반 랜덤 선택
    final totalWeight = weights.fold(0, (sum, w) => sum + w);
    var pick = Random().nextInt(totalWeight);
    for (var i = 0; i < messages.length; i++) {
      pick -= weights[i];
      if (pick < 0) return messages[i];
    }
    return messages.last;
  }
}
