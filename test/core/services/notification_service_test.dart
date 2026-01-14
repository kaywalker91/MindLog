import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/notification_messages.dart';
import 'package:mindlog/core/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Mock Android Platform Implementation
class MockAndroidNotificationPlatform extends AndroidFlutterLocalNotificationsPlugin {
  final List<MethodCall> calls = [];

  @override
  Future<bool> initialize(
    AndroidInitializationSettings initializationSettings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)? onDidReceiveBackgroundNotificationResponse,
  }) async {
    calls.add(const MethodCall('initialize', null));
    return true;
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body, {
    AndroidNotificationDetails? notificationDetails,
    String? payload,
  }) async {
    calls.add(MethodCall('show', {
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
    }));
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    AndroidNotificationDetails? notificationDetails, {
    required AndroidScheduleMode scheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    calls.add(MethodCall('zonedSchedule', {
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'scheduledDate': scheduledDate,
    }));
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {
    calls.add(MethodCall('cancel', id));
  }

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel notificationChannel,
  ) async {
    calls.add(MethodCall('createNotificationChannel', notificationChannel.id));
  }

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    calls.add(const MethodCall('getNotificationAppLaunchDetails', null));
    return const NotificationAppLaunchDetails(false);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    calls.add(const MethodCall('pendingNotificationRequests', null));
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAndroidNotificationPlatform mockPlatform;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    mockPlatform = MockAndroidNotificationPlatform();
    FlutterLocalNotificationsPlatform.instance = mockPlatform;

    // Timezone 초기화
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }

    // flutter_timezone 모킹
    const MethodChannel timezoneChannel = MethodChannel('flutter_timezone');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      timezoneChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getLocalTimezone') {
          return 'Asia/Seoul';
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      null,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  group('NotificationService', () {
    test('initialize 호출 시 플랫폼 initialize가 호출된다', () async {
      await NotificationService.initialize();

      expect(
        mockPlatform.calls.any((call) => call.method == 'initialize'),
        isTrue,
      );
    });

    test('scheduleDailyReminder 호출 시 zonedSchedule이 호출된다', () async {
      // Given
      const hour = 21;
      const minute = 0;
      const payload = 'test_payload';

      // When
      await NotificationService.scheduleDailyReminder(
        hour: hour,
        minute: minute,
        payload: payload,
      );

      // Then
      try {
        final call = mockPlatform.calls.firstWhere(
            (call) => call.method == 'zonedSchedule',
            orElse: () => throw Exception('zonedSchedule not called. Calls: ${mockPlatform.calls}'));
        final args = call.arguments as Map;

        expect(args['id'], 1001);
        // 랜덤 메시지이므로 유효한 목록 내 값인지 확인
        expect(
          NotificationMessages.reminderTitles,
          contains(args['title']),
          reason: 'title should be one of the reminder titles',
        );
        expect(args['payload'], payload);
      } catch (_) {
        rethrow;
      }
    });

    test('cancelDailyReminder 호출 시 cancel이 호출된다', () async {
      // When
      await NotificationService.cancelDailyReminder();

      // Then
      final call = mockPlatform.calls.firstWhere(
        (call) => call.method == 'cancel',
        orElse: () => throw Exception('cancel not called. Calls: ${mockPlatform.calls}'),
      );
      expect(call.arguments, 1001);
    });
    
    test('showTestNotification 호출 시 show가 호출된다', () async {
      await NotificationService.showTestNotification();

      final call = mockPlatform.calls.firstWhere((call) => call.method == 'show',
      orElse: () => throw Exception('show not called. Calls: ${mockPlatform.calls}'));
      final args = call.arguments as Map;
      expect(args['title'], '테스트 알림');
    });

    test('showNotification 호출 시 지정된 title과 body로 show가 호출된다', () async {
      // Given
      const title = '알림 제목';
      const body = '알림 본문';
      const payload = 'test_payload';

      // When
      await NotificationService.showNotification(
        title: title,
        body: body,
        payload: payload,
      );

      // Then
      final call = mockPlatform.calls.firstWhere(
        (call) => call.method == 'show',
        orElse: () => throw Exception('show not called'),
      );
      final args = call.arguments as Map;
      expect(args['title'], title);
      expect(args['body'], body);
      expect(args['payload'], payload);
    });

    test('getPendingNotifications 호출 시 pendingNotificationRequests가 호출된다', () async {
      // When
      final pending = await NotificationService.getPendingNotifications();

      // Then
      expect(
        mockPlatform.calls.any((call) => call.method == 'pendingNotificationRequests'),
        isTrue,
      );
      expect(pending, isEmpty);
    });

    test('scheduleDailyReminder 호출 시 오늘 시간이 지났으면 다음 날로 스케줄된다', () async {
      // Given - 현재 시간보다 이전 시간 설정
      final now = tz.TZDateTime.now(tz.local);
      final pastHour = (now.hour - 1 + 24) % 24;

      // When
      await NotificationService.scheduleDailyReminder(
        hour: pastHour,
        minute: 0,
      );

      // Then
      final call = mockPlatform.calls.firstWhere(
        (call) => call.method == 'zonedSchedule',
        orElse: () => throw Exception('zonedSchedule not called'),
      );
      final args = call.arguments as Map;
      final scheduledDate = args['scheduledDate'] as tz.TZDateTime;

      // 스케줄된 날짜가 오늘이거나 내일이어야 함
      expect(scheduledDate.isAfter(now) || scheduledDate.isAtSameMomentAs(now), isTrue);
    });

    test('cancelDailyReminder 호출 전 항상 cancel이 호출된다', () async {
      // When
      await NotificationService.scheduleDailyReminder(
        hour: 21,
        minute: 0,
      );

      // Then - scheduleDailyReminder 내부에서 cancelDailyReminder가 먼저 호출됨
      final cancelCalls = mockPlatform.calls.where((call) => call.method == 'cancel').toList();
      expect(cancelCalls.isNotEmpty, isTrue);
      expect(cancelCalls.first.arguments, 1001); // _dailyReminderId
    });
  });
}
