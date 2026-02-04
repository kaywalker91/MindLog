import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/notification_messages.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const int _dailyReminderId = 1001;

  static Future<void> initialize({
    void Function(String? payload)? onNotificationResponse,
  }) async {
    tz.initializeTimeZones();

    // 기기의 로컬 타임존을 설정 (중요: 이 설정이 없으면 tz.local이 UTC로 남음)
    // flutter_timezone 5.0.1은 TimezoneInfo 객체를 반환하며, .identifier로 문자열 접근
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    if (kDebugMode) {
      debugPrint('[Notification] Timezone set to: $timeZoneName');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        onNotificationResponse?.call(response.payload);
        if (kDebugMode) {
          debugPrint('[Notification] Tapped: ${response.payload}');
        }
      },
    );

    await _createNotificationChannel();

    final launchDetails = await _notifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      onNotificationResponse?.call(
        launchDetails?.notificationResponse?.payload,
      );
    }
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'mindlog_reminders',
      '일기 작성 리마인더',
      description: '매일 일기 작성을 알려드립니다',
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
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

  /// 매일 반복 리마인더 스케줄링
  ///
  /// [hour] 시간 (0-23)
  /// [minute] 분 (0-59)
  /// [payload] 알림 클릭 시 전달할 데이터
  /// [scheduleMode] Android 스케줄 모드 (기본: exactAllowWhileIdle)
  ///
  /// Returns:
  /// - `true` 스케줄링 성공
  /// - `false` 스케줄링 실패 (크래시 없이 graceful 실패)
  static Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    String? payload,
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle,
  }) async {
    try {
      await cancelDailyReminder();

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // 매번 다른 메시지로 사용자 참여 유도
      final message = NotificationMessages.getRandomReminderMessage();

      await _notifications.zonedSchedule(
        _dailyReminderId,
        message.title,
        message.body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mindlog_reminders',
            '일기 작성 리마인더',
            channelDescription: '매일 일기 작성을 알려드립니다',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            // 잠금 화면에서도 표시
            visibility: NotificationVisibility.public,
            // 알림이 자동으로 사라지지 않도록
            autoCancel: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (kDebugMode) {
        debugPrint(
          '[Notification] Daily reminder scheduled for: $scheduledDate',
        );
        debugPrint(
          '[Notification] Message: "${message.title}" / "${message.body}"',
        );
        debugPrint('[Notification] Schedule mode: $scheduleMode');
        debugPrint('[Notification] Current time: $now');
        debugPrint('[Notification] Timezone: ${tz.local.name}');
      }
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Notification] Failed to schedule daily reminder: $e');
        debugPrint('[Notification] Stack trace: $stackTrace');
      }
      // 크래시 방지: 에러 시 false 반환
      return false;
    }
  }

  static Future<void> cancelDailyReminder() async {
    await _notifications.cancel(_dailyReminderId);
  }

  static Future<bool?> areNotificationsEnabled() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return androidPlugin?.areNotificationsEnabled();
  }

  static Future<bool?> requestAndroidPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return androidPlugin?.requestNotificationsPermission();
  }

  /// Android 12+ 정확한 알람 권한 확인
  static Future<bool?> canScheduleExactAlarms() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return androidPlugin?.canScheduleExactNotifications();
  }

  /// 정확한 알람 권한 요청 (설정 화면으로 이동)
  static Future<void> requestExactAlarmPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// 테스트 알림 즉시 표시 (디버깅용)
  /// 마음케어 메시지 형태로 표시하여 실제 알림 미리보기 제공
  static Future<void> showTestNotification() async {
    if (kDebugMode) {
      debugPrint('[Notification] Showing test notification...');
    }
    final message = NotificationMessages.getRandomMindcareMessage();
    await showNotification(
      title: '[테스트] ${message.title}',
      body: message.body,
      payload: '{"type":"test_mindcare"}',
    );
  }

  /// 예약된 알림 목록 확인 (디버깅용)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return _notifications.pendingNotificationRequests();
  }
}
