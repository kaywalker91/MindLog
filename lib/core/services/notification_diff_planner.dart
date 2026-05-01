import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

/// Cheer Me 알림 큐 변경분
///
/// 매 적용마다 7개를 cancel + 7개를 reschedule하는 platform channel 14회
/// 호출을 피하기 위해, 새 plan과 현재 pending 알림을 비교해 정말 변경된
/// 항목만 추려낸다.
class NotificationQueueDiff {
  const NotificationQueueDiff({
    required this.idsToCancel,
    required this.toSchedule,
  });

  final List<int> idsToCancel;
  final List<CheerMeScheduledNotification> toSchedule;

  bool get isEmpty => idsToCancel.isEmpty && toSchedule.isEmpty;

  int get totalOperations => idsToCancel.length + toSchedule.length;
}

/// 현재 pending 알림과 새 plan을 비교해 cancel/schedule 변경분을 계산한다.
///
/// - pending이지만 plan에 없는 cheerMe ID → cancel
/// - plan에 있지만 pending에 없는 ID → schedule
/// - 양쪽에 있고 title/body/payload가 모두 동일 → 변경 없음(no-op)
/// - 양쪽에 있지만 시그니처(title/body/payload)가 다름 → cancel + schedule
///
/// CheerMe ID 범위(`NotificationService.isCheerMeId`) 밖의 pending은 무시한다.
NotificationQueueDiff diffCheerMeQueue({
  required List<PendingNotificationRequest> pending,
  required List<CheerMeScheduledNotification> plan,
}) {
  final pendingById = <int, PendingNotificationRequest>{};
  for (final p in pending) {
    if (NotificationService.isCheerMeId(p.id)) {
      pendingById[p.id] = p;
    }
  }

  final planById = <int, CheerMeScheduledNotification>{};
  for (final n in plan) {
    planById[n.id] = n;
  }

  final idsToCancel = <int>[];
  final toSchedule = <CheerMeScheduledNotification>[];

  for (final id in pendingById.keys) {
    if (!planById.containsKey(id)) {
      idsToCancel.add(id);
    }
  }

  for (final entry in planById.entries) {
    final id = entry.key;
    final notification = entry.value;
    final existing = pendingById[id];

    if (existing == null) {
      toSchedule.add(notification);
      continue;
    }

    if (_isIdentical(existing, notification)) {
      continue;
    }

    idsToCancel.add(id);
    toSchedule.add(notification);
  }

  idsToCancel.sort();
  toSchedule.sort((a, b) => a.id.compareTo(b.id));

  return NotificationQueueDiff(
    idsToCancel: idsToCancel,
    toSchedule: toSchedule,
  );
}

bool _isIdentical(
  PendingNotificationRequest pending,
  CheerMeScheduledNotification plan,
) {
  return pending.title == plan.title &&
      pending.body == plan.body &&
      pending.payload == plan.payload;
}
