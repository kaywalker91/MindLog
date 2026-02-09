import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/notification_diagnostic_service.dart';

void main() {
  group('NotificationDiagnosticData', () {
    group('hasCheerMeScheduled', () {
      test('ID 1001이 포함되어 있으면 true를 반환해야 한다', () {
        final data = _createData(
          pendingNotifications: [(id: 1001, title: 'Cheer Me')],
        );
        expect(data.hasCheerMeScheduled, isTrue);
      });

      test('ID 1001이 없으면 false를 반환해야 한다', () {
        final data = _createData(
          pendingNotifications: [(id: 2002, title: 'Weekly')],
        );
        expect(data.hasCheerMeScheduled, isFalse);
      });

      test('빈 목록이면 false를 반환해야 한다', () {
        final data = _createData(pendingNotifications: []);
        expect(data.hasCheerMeScheduled, isFalse);
      });

      test('여러 알림 중 1001이 포함되면 true를 반환해야 한다', () {
        final data = _createData(
          pendingNotifications: [
            (id: 2002, title: 'Weekly'),
            (id: 1001, title: 'Cheer Me'),
            (id: 3001, title: 'CBT'),
          ],
        );
        expect(data.hasCheerMeScheduled, isTrue);
      });
    });

    group('hasExactAlarmIssue', () {
      test('canScheduleExact가 true이면 문제 없음', () {
        final data = _createData(canScheduleExact: true);
        expect(data.hasExactAlarmIssue, isFalse);
      });

      test('canScheduleExact가 false이면 문제 있음', () {
        final data = _createData(canScheduleExact: false);
        expect(data.hasExactAlarmIssue, isTrue);
      });

      test('canScheduleExact가 null이면 문제 있음', () {
        final data = _createData(canScheduleExact: null);
        expect(data.hasExactAlarmIssue, isTrue);
      });
    });

    group('hasBatteryIssue', () {
      test('isIgnoringBattery가 true이면 문제 없음', () {
        final data = _createData(isIgnoringBattery: true);
        expect(data.hasBatteryIssue, isFalse);
      });

      test('isIgnoringBattery가 false이면 문제 있음', () {
        final data = _createData(isIgnoringBattery: false);
        expect(data.hasBatteryIssue, isTrue);
      });
    });

    group('hasNotificationIssue', () {
      test('notificationsEnabled가 true이면 문제 없음', () {
        final data = _createData(notificationsEnabled: true);
        expect(data.hasNotificationIssue, isFalse);
      });

      test('notificationsEnabled가 false이면 문제 있음', () {
        final data = _createData(notificationsEnabled: false);
        expect(data.hasNotificationIssue, isTrue);
      });

      test('notificationsEnabled가 null이면 문제 있음', () {
        final data = _createData(notificationsEnabled: null);
        expect(data.hasNotificationIssue, isTrue);
      });
    });

    group('hasAnyIssue', () {
      test('모든 권한이 정상이면 false를 반환해야 한다', () {
        final data = _createData(
          canScheduleExact: true,
          isIgnoringBattery: true,
          notificationsEnabled: true,
        );
        expect(data.hasAnyIssue, isFalse);
      });

      test('exactAlarm만 문제이면 true를 반환해야 한다', () {
        final data = _createData(
          canScheduleExact: false,
          isIgnoringBattery: true,
          notificationsEnabled: true,
        );
        expect(data.hasAnyIssue, isTrue);
      });

      test('battery만 문제이면 true를 반환해야 한다', () {
        final data = _createData(
          canScheduleExact: true,
          isIgnoringBattery: false,
          notificationsEnabled: true,
        );
        expect(data.hasAnyIssue, isTrue);
      });

      test('notification만 문제이면 true를 반환해야 한다', () {
        final data = _createData(
          canScheduleExact: true,
          isIgnoringBattery: true,
          notificationsEnabled: false,
        );
        expect(data.hasAnyIssue, isTrue);
      });

      test('모든 권한이 문제이면 true를 반환해야 한다', () {
        final data = _createData(
          canScheduleExact: false,
          isIgnoringBattery: false,
          notificationsEnabled: false,
        );
        expect(data.hasAnyIssue, isTrue);
      });

      test('null 값도 문제로 감지해야 한다', () {
        final data = _createData(
          canScheduleExact: null,
          isIgnoringBattery: true,
          notificationsEnabled: null,
        );
        expect(data.hasAnyIssue, isTrue);
      });
    });

    group('scheduledHour/scheduledMinute', () {
      test('설정된 시간이 있으면 값을 반환해야 한다', () {
        final data = _createData(scheduledHour: 9, scheduledMinute: 30);
        expect(data.scheduledHour, 9);
        expect(data.scheduledMinute, 30);
      });

      test('설정된 시간이 없으면 null을 반환해야 한다', () {
        final data = _createData();
        expect(data.scheduledHour, isNull);
        expect(data.scheduledMinute, isNull);
      });
    });
  });

  group('NotificationDiagnosticService', () {
    tearDown(() {
      NotificationDiagnosticService.resetForTesting();
    });

    group('collect', () {
      test('collectOverride가 설정되면 오버라이드 결과를 반환해야 한다', () async {
        final mockData = _createData(
          pendingNotifications: [(id: 1001, title: 'Test')],
          canScheduleExact: true,
          isIgnoringBattery: true,
          notificationsEnabled: true,
          timezoneName: 'Asia/Seoul',
          scheduledHour: 21,
          scheduledMinute: 0,
        );

        NotificationDiagnosticService.collectOverride = () async => mockData;

        final result = await NotificationDiagnosticService.collect();

        expect(result.pendingNotifications.length, 1);
        expect(result.pendingNotifications.first.id, 1001);
        expect(result.canScheduleExact, isTrue);
        expect(result.isIgnoringBattery, isTrue);
        expect(result.notificationsEnabled, isTrue);
        expect(result.timezoneName, 'Asia/Seoul');
        expect(result.scheduledHour, 21);
        expect(result.scheduledMinute, 0);
      });

      test('collectOverride로 문제 있는 상태를 시뮬레이션할 수 있어야 한다', () async {
        final mockData = _createData(
          pendingNotifications: [],
          canScheduleExact: false,
          isIgnoringBattery: false,
          notificationsEnabled: false,
          timezoneName: 'UTC',
        );

        NotificationDiagnosticService.collectOverride = () async => mockData;

        final result = await NotificationDiagnosticService.collect();

        expect(result.hasCheerMeScheduled, isFalse);
        expect(result.hasExactAlarmIssue, isTrue);
        expect(result.hasBatteryIssue, isTrue);
        expect(result.hasNotificationIssue, isTrue);
        expect(result.hasAnyIssue, isTrue);
      });
    });

    group('resetForTesting', () {
      test('collectOverride를 null로 리셋해야 한다', () {
        NotificationDiagnosticService.collectOverride = () async => _createData();
        NotificationDiagnosticService.resetForTesting();

        // resetForTesting 후 collectOverride는 null이므로
        // 실제 platform 호출이 일어남 (테스트에서는 이 시점에서 호출하지 않음)
        expect(NotificationDiagnosticService.collectOverride, isNull);
      });
    });
  });
}

/// 테스트 헬퍼: NotificationDiagnosticData 팩토리
NotificationDiagnosticData _createData({
  List<({int id, String? title})> pendingNotifications = const [],
  bool? canScheduleExact = true,
  bool isIgnoringBattery = true,
  bool? notificationsEnabled = true,
  String timezoneName = 'Asia/Seoul',
  int? scheduledHour,
  int? scheduledMinute,
}) {
  return NotificationDiagnosticData(
    pendingNotifications: pendingNotifications,
    canScheduleExact: canScheduleExact,
    isIgnoringBattery: isIgnoringBattery,
    notificationsEnabled: notificationsEnabled,
    timezoneName: timezoneName,
    scheduledHour: scheduledHour,
    scheduledMinute: scheduledMinute,
  );
}
