import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_permission_service.dart';
import 'notification_service.dart';

/// Cheer Me 알림 진단 데이터
class NotificationDiagnosticData {
  final List<({int id, String? title})> pendingNotifications;
  final bool? canScheduleExact;
  final bool isIgnoringBattery;
  final bool? notificationsEnabled;
  final String timezoneName;
  final int? scheduledHour;
  final int? scheduledMinute;

  const NotificationDiagnosticData({
    required this.pendingNotifications,
    required this.canScheduleExact,
    required this.isIgnoringBattery,
    required this.notificationsEnabled,
    required this.timezoneName,
    this.scheduledHour,
    this.scheduledMinute,
  });

  /// Cheer Me 알림(ID 1001)이 예약되어 있는지
  bool get hasCheerMeScheduled =>
      pendingNotifications.any((n) => n.id == 1001);

  /// 정확한 알람 권한에 문제가 있는지
  bool get hasExactAlarmIssue => canScheduleExact != true;

  /// 배터리 최적화가 문제인지
  bool get hasBatteryIssue => !isIgnoringBattery;

  /// 알림 권한에 문제가 있는지
  bool get hasNotificationIssue => notificationsEnabled != true;

  /// 하나라도 문제가 있는지
  bool get hasAnyIssue =>
      hasExactAlarmIssue || hasBatteryIssue || hasNotificationIssue;
}

/// 알림 진단 데이터 수집 서비스
class NotificationDiagnosticService {
  NotificationDiagnosticService._();

  /// 테스트 오버라이드
  @visibleForTesting
  static Future<NotificationDiagnosticData> Function()? collectOverride;

  @visibleForTesting
  static void resetForTesting() {
    collectOverride = null;
  }

  /// 진단 데이터 수집
  static Future<NotificationDiagnosticData> collect() async {
    if (collectOverride != null) return collectOverride!();

    // 예약된 알림 목록
    final pending = await NotificationService.getPendingNotifications();
    final pendingList = pending
        .map((n) => (id: n.id, title: n.title))
        .toList();

    // 권한 상태
    bool? canScheduleExact;
    bool isIgnoringBattery = false;
    bool? notificationsEnabled;
    try {
      canScheduleExact =
          await NotificationPermissionService.canScheduleExactAlarms();
      isIgnoringBattery =
          await NotificationPermissionService.isIgnoringBatteryOptimizations();
      notificationsEnabled =
          await NotificationService.areNotificationsEnabled();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Diagnostic] Permission check failed: $e');
      }
    }

    // 설정된 알림 시간
    int? hour;
    int? minute;
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminderEnabled =
          prefs.getBool('notification_reminder_enabled') ?? false;
      if (reminderEnabled) {
        hour = prefs.getInt('notification_reminder_hour') ?? 21;
        minute = prefs.getInt('notification_reminder_minute') ?? 0;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Diagnostic] SharedPreferences read failed: $e');
      }
    }

    return NotificationDiagnosticData(
      pendingNotifications: pendingList,
      canScheduleExact: canScheduleExact,
      isIgnoringBattery: isIgnoringBattery,
      notificationsEnabled: notificationsEnabled,
      timezoneName: tz.local.name,
      scheduledHour: hour,
      scheduledMinute: minute,
    );
  }
}
