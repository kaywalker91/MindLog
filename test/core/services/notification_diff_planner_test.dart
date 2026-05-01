import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/notification_diff_planner.dart';
import 'package:mindlog/core/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  });

  CheerMeScheduledNotification createPlanItem(
    int idOffset, {
    String suffix = '',
  }) {
    final id = NotificationService.dailyReminderId + idOffset;
    return CheerMeScheduledNotification(
      id: id,
      title: '응원 제목 $idOffset$suffix',
      body: '본문 $idOffset$suffix',
      scheduledDate: tz.TZDateTime(tz.local, 2026, 5, 1 + idOffset, 19, 0),
      payload: '{"id":$id,"sig":"abc$suffix"}',
    );
  }

  PendingNotificationRequest pendingFrom(CheerMeScheduledNotification n) {
    return PendingNotificationRequest(n.id, n.title, n.body, n.payload);
  }

  group('diffCheerMeQueue', () {
    test('plan과 동일한 pending 7건이면 빈 diff를 반환해야 한다', () {
      // Arrange
      final plan = [for (var i = 0; i < 7; i++) createPlanItem(i)];
      final pending = plan.map(pendingFrom).toList();

      // Act
      final diff = diffCheerMeQueue(pending: pending, plan: plan);

      // Assert
      expect(diff.isEmpty, isTrue);
      expect(diff.idsToCancel, isEmpty);
      expect(diff.toSchedule, isEmpty);
    });

    test('pending이 비어있으면 plan 전부를 toSchedule로 반환해야 한다', () {
      // Arrange
      final plan = [for (var i = 0; i < 7; i++) createPlanItem(i)];

      // Act
      final diff = diffCheerMeQueue(pending: const [], plan: plan);

      // Assert
      expect(diff.idsToCancel, isEmpty);
      expect(diff.toSchedule, hasLength(7));
      expect(
        diff.toSchedule.map((n) => n.id).toList(),
        equals(plan.map((n) => n.id).toList()),
      );
    });

    test('payload가 변경된 항목만 cancel + reschedule 해야 한다', () {
      // Arrange
      final plan = [for (var i = 0; i < 7; i++) createPlanItem(i)];
      const changedId = NotificationService.dailyReminderId + 3;
      final pending = [
        for (var i = 0; i < 7; i++)
          if (i == 3)
            PendingNotificationRequest(
              plan[i].id,
              plan[i].title,
              plan[i].body,
              '{"id":${plan[i].id},"sig":"old"}',
            )
          else
            pendingFrom(plan[i]),
      ];

      // Act
      final diff = diffCheerMeQueue(pending: pending, plan: plan);

      // Assert
      expect(diff.idsToCancel, equals([changedId]));
      expect(diff.toSchedule, hasLength(1));
      expect(diff.toSchedule.first.id, changedId);
    });

    test('plan에 포함되지 않은 cheerMe pending은 cancel 해야 한다', () {
      // Arrange: pending 7건, plan은 처음 6건만 포함 → id 1006은 cancel
      final fullPlan = [for (var i = 0; i < 7; i++) createPlanItem(i)];
      final partialPlan = fullPlan.sublist(0, 6);
      final pending = fullPlan.map(pendingFrom).toList();

      // Act
      final diff = diffCheerMeQueue(pending: pending, plan: partialPlan);

      // Assert
      expect(
        diff.idsToCancel,
        equals([NotificationService.dailyReminderId + 6]),
      );
      expect(diff.toSchedule, isEmpty);
    });

    test('cheerMe ID 범위 밖 pending은 무시해야 한다', () {
      // Arrange
      final plan = [for (var i = 0; i < 7; i++) createPlanItem(i)];
      final pending = [
        ...plan.map(pendingFrom),
        const PendingNotificationRequest(
          NotificationService.fcmMindcareId,
          'FCM',
          'mindcare',
          null,
        ),
      ];

      // Act
      final diff = diffCheerMeQueue(pending: pending, plan: plan);

      // Assert
      expect(diff.isEmpty, isTrue);
    });

    test('title만 변경되어도 reschedule 해야 한다', () {
      // Arrange
      final plan = [createPlanItem(0)];
      final pending = [
        PendingNotificationRequest(
          plan[0].id,
          '다른 제목',
          plan[0].body,
          plan[0].payload,
        ),
      ];

      // Act
      final diff = diffCheerMeQueue(pending: pending, plan: plan);

      // Assert
      expect(diff.idsToCancel, equals([plan[0].id]));
      expect(diff.toSchedule, hasLength(1));
    });

    test('body만 변경되어도 reschedule 해야 한다', () {
      // Arrange
      final plan = [createPlanItem(0)];
      final pending = [
        PendingNotificationRequest(
          plan[0].id,
          plan[0].title,
          '다른 본문',
          plan[0].payload,
        ),
      ];

      // Act
      final diff = diffCheerMeQueue(pending: pending, plan: plan);

      // Assert
      expect(diff.idsToCancel, equals([plan[0].id]));
      expect(diff.toSchedule, hasLength(1));
    });

    test('idsToCancel과 toSchedule은 ID 오름차순으로 정렬되어야 한다', () {
      // Arrange: 변경된 항목을 일부러 역순으로 배치
      final plan = [for (var i = 0; i < 7; i++) createPlanItem(i)];
      final changeIndices = [5, 2, 4]; // 임의 순서
      final pending = [
        for (var i = 0; i < 7; i++)
          if (changeIndices.contains(i))
            PendingNotificationRequest(
              plan[i].id,
              plan[i].title,
              plan[i].body,
              '{"sig":"changed"}',
            )
          else
            pendingFrom(plan[i]),
      ];

      // Act
      final diff = diffCheerMeQueue(pending: pending, plan: plan);

      // Assert
      final expectedIds = changeIndices
          .map((i) => NotificationService.dailyReminderId + i)
          .toList()
        ..sort();
      expect(diff.idsToCancel, equals(expectedIds));
      expect(
        diff.toSchedule.map((n) => n.id).toList(),
        equals(expectedIds),
      );
    });
  });
}
