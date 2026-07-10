import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:mindlog/core/constants/notification_messages.dart';
import 'package:mindlog/core/services/notification_service.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';

import 'cheer_me_message_selector.dart';
import 'cheer_me_types.dart';

/// Builds Cheer Me queue plans, signatures, payloads, and rebuild checks.
class CheerMeQueuePlanner {
  CheerMeQueuePlanner._();

  static CheerMeQueuePlan buildPlan(
    NotificationSettings settings, {
    required List<SelfEncouragementMessage> messages,
    required int payloadVersion,
    String? userName,
    double? recentEmotionScore,
    List<PendingNotificationRequest> pendingNotifications = const [],
    tz.TZDateTime? now,
  }) {
    final sortedMessages = [...messages]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final signature = buildSignature(
      settings,
      sortedMessages,
      userName,
      payloadVersion: payloadVersion,
    );

    if (sortedMessages.isEmpty) {
      return CheerMeQueuePlan(
        notifications: const [],
        nextSequentialCursor: settings.lastDisplayedIndex,
        signature: signature,
      );
    }

    final currentTime = now ?? tz.TZDateTime.now(tz.local);
    final firstScheduledDate = nextReminderDate(settings, currentTime);
    final parsedPending = parsePendingCheerMeNotifications(
      pendingNotifications,
    );

    var rollingCursor = resolveSequentialStartCursor(
      settings,
      sortedMessages,
      parsedPending,
    );

    final notifications = <CheerMeScheduledNotification>[];
    for (var i = 0; i < NotificationService.cheerMeQueueLength; i++) {
      final scheduledDate = firstScheduledDate.add(Duration(days: i));
      final selection = CheerMeMessageSelector.selectForSchedule(
        settings,
        sortedMessages,
        scheduledDate: scheduledDate,
        signature: signature,
        recentEmotionScore: recentEmotionScore,
        sequentialCursor: rollingCursor,
      );

      final title = selectCheerMeTitle(
        userName,
        '${signature}_${scheduledDate.toIso8601String()}_${selection.index}',
      );
      final body = NotificationMessages.applyNamePersonalization(
        selection.message.content,
        userName,
      );
      final payload = buildPayload(
        scheduledDate: scheduledDate,
        sequenceCursor: selection.index,
        messageId: selection.message.id,
        signature: signature,
        payloadVersion: payloadVersion,
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

  static bool requiresRebuild(
    NotificationSettings settings, {
    required List<SelfEncouragementMessage> messages,
    required List<PendingNotificationRequest> pendingNotifications,
    required int payloadVersion,
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

    final expectedSignature = buildSignature(
      settings,
      [...messages]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
      userName,
      payloadVersion: payloadVersion,
    );

    for (final notification in cheerMePending) {
      if (notification.title?.contains('{name}') ?? false) {
        return true;
      }

      final parsed = parseCheerMePayload(notification);
      if (parsed == null ||
          parsed.version != payloadVersion ||
          parsed.signature != expectedSignature ||
          parsed.scheduledFor == null) {
        return true;
      }
    }

    return false;
  }

  static String buildSignature(
    NotificationSettings settings,
    List<SelfEncouragementMessage> messages,
    String? userName, {
    required int payloadVersion,
  }) {
    final payload = jsonEncode({
      'v': payloadVersion,
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

  static String buildPayload({
    required tz.TZDateTime scheduledDate,
    required int sequenceCursor,
    required String messageId,
    required String signature,
    required int payloadVersion,
  }) {
    return jsonEncode({
      'type': 'cheerme',
      'v': payloadVersion,
      'scheduledFor': scheduledDate.toIso8601String(),
      'sequenceCursor': sequenceCursor,
      'messageId': messageId,
      'signature': signature,
    });
  }

  static String selectCheerMeTitle(String? userName, String seed) {
    final templates = NotificationMessages.cheerMeTitles;
    final index = CheerMeMessageSelector.stableModulo(seed, templates.length);
    return NotificationMessages.applyNamePersonalization(
      templates[index],
      userName,
    );
  }

  static tz.TZDateTime nextReminderDate(
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

  static int resolveSequentialStartCursor(
    NotificationSettings settings,
    List<SelfEncouragementMessage> messages,
    List<ParsedCheerMePayload> pendingNotifications,
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

  static List<ParsedCheerMePayload> parsePendingCheerMeNotifications(
    List<PendingNotificationRequest> pendingNotifications,
  ) {
    final parsed =
        pendingNotifications
            .where(
              (notification) =>
                  NotificationService.isCheerMeId(notification.id),
            )
            .map(parseCheerMePayload)
            .whereType<ParsedCheerMePayload>()
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

  static ParsedCheerMePayload? parseCheerMePayload(
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

      return ParsedCheerMePayload(
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

  static CheerMeScheduledNotification? buildPreviewFromPending(
    List<PendingNotificationRequest> pendingNotifications,
  ) {
    final parsed = parsePendingCheerMeNotifications(pendingNotifications);
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
}
