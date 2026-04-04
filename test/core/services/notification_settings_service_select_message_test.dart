import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/notification_settings_service.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';

void main() {
  SelfEncouragementMessage createMessage(
    int order, {
    String? timeCategory,
    double? writtenEmotionScore,
  }) {
    return SelfEncouragementMessage(
      id: 'msg_$order',
      content: '메시지 $order',
      createdAt: DateTime(2026, 1, 1),
      displayOrder: order,
      timeCategory: timeCategory,
      writtenEmotionScore: writtenEmotionScore,
    );
  }

  NotificationSettings createSettings({
    MessageRotationMode mode = MessageRotationMode.timeAware,
    int lastDisplayedIndex = 0,
  }) {
    return NotificationSettings(
      isReminderEnabled: true,
      reminderHour: 19,
      reminderMinute: 0,
      isMindcareTopicEnabled: false,
      rotationMode: mode,
      lastDisplayedIndex: lastDisplayedIndex,
    );
  }

  group('timeAware 모드', () {
    test('morning(hour=8) 시간대 메시지를 필터링해야 한다', () {
      final messages = [
        createMessage(0, timeCategory: 'morning'),
        createMessage(1, timeCategory: 'afternoon'),
        createMessage(2, timeCategory: 'evening'),
      ];
      final settings = createSettings();
      final now = DateTime(2026, 4, 5, 8, 0); // 8시 = morning

      for (var i = 0; i < 50; i++) {
        final result = NotificationSettingsService.selectMessage(
          settings,
          messages,
          now: now,
        );
        expect(result, equals(messages[0]));
      }
    });

    test('매칭 메시지 없으면 전체 풀에서 폴백해야 한다', () {
      final messages = [
        createMessage(0, timeCategory: 'afternoon'),
        createMessage(1, timeCategory: 'evening'),
      ];
      final settings = createSettings();
      final now = DateTime(2026, 4, 5, 8, 0); // morning — 매칭 없음

      for (var i = 0; i < 50; i++) {
        final result = NotificationSettingsService.selectMessage(
          settings,
          messages,
          now: now,
        );
        expect(result, isNotNull);
        expect(messages, contains(result));
      }
    });

    test('경계값: hour=5는 morning이어야 한다', () {
      final messages = [
        createMessage(0, timeCategory: 'morning'),
        createMessage(1, timeCategory: 'evening'),
      ];
      final settings = createSettings();
      final now = DateTime(2026, 4, 5, 5, 0);

      for (var i = 0; i < 50; i++) {
        final result = NotificationSettingsService.selectMessage(
          settings,
          messages,
          now: now,
        );
        expect(result, equals(messages[0]));
      }
    });

    test('경계값: hour=4는 evening이어야 한다', () {
      final messages = [
        createMessage(0, timeCategory: 'morning'),
        createMessage(1, timeCategory: 'evening'),
      ];
      final settings = createSettings();
      final now = DateTime(2026, 4, 5, 4, 0);

      for (var i = 0; i < 50; i++) {
        final result = NotificationSettingsService.selectMessage(
          settings,
          messages,
          now: now,
        );
        expect(result, equals(messages[1]));
      }
    });

    test('timeCategory가 모두 null이면 전체 풀 폴백해야 한다', () {
      final messages = [
        createMessage(0),
        createMessage(1),
        createMessage(2),
      ];
      final settings = createSettings();
      final now = DateTime(2026, 4, 5, 10, 0);

      for (var i = 0; i < 50; i++) {
        final result = NotificationSettingsService.selectMessage(
          settings,
          messages,
          now: now,
        );
        expect(result, isNotNull);
        expect(messages, contains(result));
      }
    });
  });

  group('emotionAware 모드', () {
    test('recentScore 없으면 랜덤 폴백해야 한다', () {
      final messages = [
        createMessage(0, writtenEmotionScore: 3.0),
        createMessage(1, writtenEmotionScore: 7.0),
      ];
      final settings = createSettings(mode: MessageRotationMode.emotionAware);

      final selectedIds = <String>{};
      for (var i = 0; i < 200; i++) {
        final result = NotificationSettingsService.selectMessage(
          settings,
          messages,
          recentEmotionScore: null,
        );
        expect(result, isNotNull);
        selectedIds.add(result!.id);
      }
      // 랜덤이므로 2종류 모두 선택되어야 함
      expect(selectedIds.length, equals(2));
    });

    test('거리 ≤1 메시지가 3x 가중치로 우선 선택되어야 한다', () {
      final messages = [
        createMessage(0, writtenEmotionScore: 5.0), // 거리=0 → 3x
        createMessage(1, writtenEmotionScore: 9.0), // 거리=4 → 1x
      ];
      final settings = createSettings(mode: MessageRotationMode.emotionAware);

      var closeCount = 0;
      const trials = 400;
      for (var i = 0; i < trials; i++) {
        final result = NotificationSettingsService.selectMessage(
          settings,
          messages,
          recentEmotionScore: 5.0,
        );
        if (result!.id == 'msg_0') closeCount++;
      }
      // 기대 비율: 3/4 = 75%. 허용 범위: 60-90%
      expect(
        closeCount,
        greaterThan(trials * 0.6),
        reason: '거리≤1 메시지(3x)가 60% 이상 선택되어야 함 (실제: $closeCount/$trials)',
      );
    });

    test('모든 메시지 writtenScore=null이면 균등 가중치여야 한다', () {
      final messages = [
        createMessage(0),
        createMessage(1),
        createMessage(2),
      ];
      final settings = createSettings(mode: MessageRotationMode.emotionAware);

      final counts = <String, int>{};
      const trials = 600;
      for (var i = 0; i < trials; i++) {
        final result = NotificationSettingsService.selectMessage(
          settings,
          messages,
          recentEmotionScore: 5.0,
        );
        counts[result!.id] = (counts[result.id] ?? 0) + 1;
      }
      // 균등 분포: 각 메시지가 최소 100회(~16%) 이상 선택
      for (final entry in counts.entries) {
        expect(
          entry.value,
          greaterThan(100),
          reason: '${entry.key}가 균등 분포에서 최소 100회 이상이어야 함 (실제: ${entry.value})',
        );
      }
    });
  });

  group('timeCategory 헬퍼', () {
    test('시간대별 올바른 카테고리를 반환해야 한다', () {
      expect(NotificationSettingsService.timeCategory(5), 'morning');
      expect(NotificationSettingsService.timeCategory(11), 'morning');
      expect(NotificationSettingsService.timeCategory(12), 'afternoon');
      expect(NotificationSettingsService.timeCategory(17), 'afternoon');
      expect(NotificationSettingsService.timeCategory(18), 'evening');
      expect(NotificationSettingsService.timeCategory(23), 'evening');
      expect(NotificationSettingsService.timeCategory(0), 'evening');
      expect(NotificationSettingsService.timeCategory(4), 'evening');
    });
  });
}
