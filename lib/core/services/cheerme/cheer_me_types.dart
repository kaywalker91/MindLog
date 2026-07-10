import 'package:mindlog/core/services/notification_service.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';

/// Planned Cheer Me notification queue (signature + items + sequential cursor).
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

/// Indexed message used by time-aware pools.
class CheerMeIndexedMessage {
  const CheerMeIndexedMessage({required this.index, required this.message});

  final int index;
  final SelfEncouragementMessage message;
}

/// Selection result with original list index (needed for sequential cursor).
class CheerMeSelection {
  const CheerMeSelection({required this.index, required this.message});

  final int index;
  final SelfEncouragementMessage message;
}

/// Parsed pending Cheer Me payload fields.
class ParsedCheerMePayload {
  const ParsedCheerMePayload({
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
