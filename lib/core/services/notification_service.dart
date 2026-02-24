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
  static const int dailyReminderId = 1001;
  static const int _dailyReminderId = dailyReminderId;
  static const int fcmMindcareId = 2001;

  // 알림 채널 ID
  static const String channelCheerMe = 'mindlog_cheerme';
  static const String channelMindcare = 'mindlog_mindcare';

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
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    // Cheer Me 채널: 사용자가 직접 쓴 자기 응원 메시지
    const cheerMeChannel = AndroidNotificationChannel(
      channelCheerMe,
      '나의 응원 (Cheer Me)',
      description: '내가 직접 쓴 응원 메시지를 매일 전달해드려요',
      importance: Importance.high,
    );

    // 마음케어 채널: 감정 분석 기반 전문 케어
    const mindcareChannel = AndroidNotificationChannel(
      channelMindcare,
      '마음케어',
      description: '감정 분석 기반 전문 마음 케어 메시지를 보내드려요',
      importance: Importance.high,
    );

    await androidPlugin.createNotificationChannel(cheerMeChannel);
    await androidPlugin.createNotificationChannel(mindcareChannel);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channel = channelMindcare,
    int? id,
  }) async {
    // 빈 알림 방지: title 또는 body가 비어있으면 기본 메시지 사용
    final safeTitle = title.isNotEmpty ? title : 'MindLog';
    final safeBody = body.isNotEmpty
        ? body
        : NotificationMessages.getRandomMindcareBody();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        channel == channelCheerMe ? '나의 응원 (Cheer Me)' : '마음케어',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _notifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      safeTitle,
      safeBody,
      details,
      payload: payload,
    );
  }

  /// 매일 반복 응원 메시지 스케줄링
  ///
  /// [hour] 시간 (0-23)
  /// [minute] 분 (0-59)
  /// [title] 알림 제목 (사용자 지정 또는 기본값)
  /// [body] 알림 본문 (사용자가 작성한 응원 메시지)
  /// [payload] 알림 클릭 시 전달할 데이터
  /// [scheduleMode] Android 스케줄 모드 (기본: exactAllowWhileIdle)
  ///
  /// Returns:
  /// - `true` 스케줄링 성공
  /// - `false` 스케줄링 실패 (크래시 없이 graceful 실패)
  static Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    String? title,
    String? body,
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

      // 사용자 메시지가 없으면 기본 메시지 사용 (하위 호환성)
      final notificationTitle = title ?? 'Cheer Me';
      final notificationBody =
          body ?? NotificationMessages.getRandomReminderMessage().body;

      await _notifications.zonedSchedule(
        _dailyReminderId,
        notificationTitle,
        notificationBody,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelCheerMe,
            '나의 응원 (Cheer Me)',
            channelDescription: '내가 직접 쓴 응원 메시지를 매일 전달해드려요',
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
          '[Notification] Message: "$notificationTitle" / "$notificationBody"',
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

  // ===== Phase 2: 공통 API =====

  /// 1회성 예약 알림 (SafetyFollowup, CognitivePattern용)
  ///
  /// [id] 알림 고유 ID
  /// [title] 알림 제목
  /// [body] 알림 본문
  /// [scheduledDate] 예약 시간 (TZDateTime)
  /// [payload] 알림 클릭 시 전달할 데이터
  /// [channel] 알림 채널 (기본: channelMindcare)
  ///
  /// Returns: true 성공, false 실패
  static Future<bool> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    String channel = channelMindcare,
  }) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channel == channelCheerMe ? '나의 응원 (Cheer Me)' : '마음케어',
            channelDescription: channel == channelCheerMe
                ? '내가 직접 쓴 응원 메시지를 매일 전달해드려요'
                : '감정 분석 기반 전문 마음 케어 메시지를 보내드려요',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            visibility: NotificationVisibility.public,
            autoCancel: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      if (kDebugMode) {
        debugPrint(
          '[Notification] One-time scheduled: id=$id at $scheduledDate',
        );
      }
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Notification] Failed to schedule one-time: $e');
        debugPrint('[Notification] Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// 예약 알림 취소 (테스트 오버라이드 지원)
  @visibleForTesting
  static Future<void> Function(int id)? cancelNotificationOverride;

  /// 테스트 상태 리셋
  @visibleForTesting
  static void resetForTesting() {
    cancelNotificationOverride = null;
  }

  /// 예약 알림 취소
  static Future<void> cancelNotification(int id) async {
    if (cancelNotificationOverride != null) {
      return cancelNotificationOverride!(id);
    }
    await _notifications.cancel(id);
    if (kDebugMode) {
      debugPrint('[Notification] Cancelled notification id=$id');
    }
  }

  /// 주간 인사이트 알림 스케줄링 (매주 일요일 20:00)
  ///
  /// [enabled] true이면 스케줄, false이면 취소
  ///
  /// Returns: true 성공, false 실패
  static Future<bool> scheduleWeeklyInsight({required bool enabled}) async {
    const weeklyInsightId = 2002;

    if (!enabled) {
      await cancelNotification(weeklyInsightId);
      return true;
    }

    try {
      final now = tz.TZDateTime.now(tz.local);
      // 다음 일요일 20:00 계산
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        20,
        0,
      );

      // 현재 요일에서 다음 일요일까지의 차이 계산
      final daysUntilSunday = (DateTime.sunday - scheduledDate.weekday) % 7;
      scheduledDate = scheduledDate.add(Duration(days: daysUntilSunday));

      // 이미 지났으면 다음 주 일요일
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      final message = NotificationMessages.getRandomWeeklyInsightMessage();

      await _notifications.zonedSchedule(
        weeklyInsightId,
        message.title,
        message.body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelMindcare,
            '마음케어',
            channelDescription: '감정 분석 기반 전문 마음 케어 메시지를 보내드려요',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            visibility: NotificationVisibility.public,
            autoCancel: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: '{"type":"mindcare","subtype":"weekly_insight"}',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      if (kDebugMode) {
        debugPrint(
          '[Notification] Weekly insight scheduled for: $scheduledDate',
        );
      }
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[Notification] Failed to schedule weekly insight: $e');
        debugPrint('[Notification] Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// 다음 날 아침 08:00 1회성 알림 스케줄링 (인지 패턴 CBT용)
  ///
  /// [patternName] 인지 패턴 이름 (동적 ID 생성용)
  /// [title] 알림 제목
  /// [body] 알림 본문
  ///
  /// Returns: true 성공, false 실패
  static Future<bool> scheduleNextMorning({
    required String patternName,
    required String title,
    required String body,
  }) async {
    final id = 3001 + patternName.hashCode.abs() % 1000;

    final now = tz.TZDateTime.now(tz.local);
    final tomorrow = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + 1,
      8,
      0,
    );

    return scheduleOneTimeNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: tomorrow,
      payload:
          '{"type":"mindcare","subtype":"cognitive_pattern","pattern":"$patternName"}',
    );
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
      payload: '{"type":"mindcare"}',
      channel: channelMindcare,
    );
  }

  /// 예약된 알림 목록 확인 (디버깅용)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return _notifications.pendingNotificationRequests();
  }
}
