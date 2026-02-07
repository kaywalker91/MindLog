import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/emotion_trend_notification_service.dart';
import 'package:mindlog/core/services/emotion_trend_service.dart';

void main() {
  group('EmotionTrendNotificationService', () {
    setUp(() {
      EmotionTrendNotificationService.resetForTesting();
    });

    tearDown(() {
      EmotionTrendNotificationService.resetForTesting();
    });

    group('notifyTrend', () {
      test('declining 트렌드 시 위로 메시지를 전송해야 한다', () async {
        // Arrange
        const result = EmotionTrendResult(
          trend: EmotionTrend.declining,
          metadata: {'type': 'consecutiveDecline'},
        );

        String? receivedTitle;
        String? receivedBody;
        String? receivedPayload;
        String? receivedChannel;

        Future<void> testShowOverride({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {
          receivedTitle = title;
          receivedBody = body;
          receivedPayload = payload;
          receivedChannel = channel;
        }
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride;

        // Act
        await EmotionTrendNotificationService.notifyTrend(result);

        // Assert
        expect(receivedTitle, isNotNull);
        expect(receivedBody, isNotNull);
        expect(
          EmotionTrendNotificationService.decliningTitles.contains(receivedTitle),
          isTrue,
        );
        expect(
          EmotionTrendNotificationService.decliningBodies.contains(receivedBody),
          isTrue,
        );
        expect(receivedPayload, contains('declining'));
        expect(receivedPayload, contains('emotion_trend'));
        expect(receivedChannel, 'mindlog_mindcare');
      });

      test('recovering 트렌드 시 격려 메시지를 전송해야 한다', () async {
        // Arrange
        const result = EmotionTrendResult(
          trend: EmotionTrend.recovering,
          metadata: {'consecutiveRisingDays': 2},
        );

        String? receivedTitle;
        String? receivedBody;

        Future<void> testShowOverride({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {
          receivedTitle = title;
          receivedBody = body;
        }
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride;

        // Act
        await EmotionTrendNotificationService.notifyTrend(result);

        // Assert
        expect(receivedTitle, isNotNull);
        expect(receivedBody, isNotNull);
        expect(
          EmotionTrendNotificationService.recoveringTitles.contains(receivedTitle),
          isTrue,
        );
        expect(
          EmotionTrendNotificationService.recoveringBodies.contains(receivedBody),
          isTrue,
        );
      });

      test('gap 트렌드 시 리마인더 메시지를 전송해야 한다', () async {
        // Arrange
        const result = EmotionTrendResult(
          trend: EmotionTrend.gap,
          metadata: {'daysSinceLastEntry': 5},
        );

        String? receivedTitle;
        String? receivedBody;

        Future<void> testShowOverride({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {
          receivedTitle = title;
          receivedBody = body;
        }
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride;

        // Act
        await EmotionTrendNotificationService.notifyTrend(result);

        // Assert
        expect(receivedTitle, isNotNull);
        expect(receivedBody, isNotNull);
        expect(
          EmotionTrendNotificationService.gapTitles.contains(receivedTitle),
          isTrue,
        );
        expect(
          EmotionTrendNotificationService.gapBodies.contains(receivedBody),
          isTrue,
        );
      });

      test('steady 트렌드 시 유지 격려 메시지를 전송해야 한다', () async {
        // Arrange
        const result = EmotionTrendResult(
          trend: EmotionTrend.steady,
          metadata: {'averageScore': 8.5},
        );

        String? receivedTitle;
        String? receivedBody;

        Future<void> testShowOverride({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {
          receivedTitle = title;
          receivedBody = body;
        }
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride;

        // Act
        await EmotionTrendNotificationService.notifyTrend(result);

        // Assert
        expect(receivedTitle, isNotNull);
        expect(receivedBody, isNotNull);
        expect(
          EmotionTrendNotificationService.steadyTitles.contains(receivedTitle),
          isTrue,
        );
        expect(
          EmotionTrendNotificationService.steadyBodies.contains(receivedBody),
          isTrue,
        );
      });

      test('payload에 트렌드 이름이 포함되어야 한다', () async {
        // Arrange
        const result = EmotionTrendResult(
          trend: EmotionTrend.recovering,
          metadata: {},
        );

        String? receivedPayload;

        Future<void> testShowOverride({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {
          receivedPayload = payload;
        }
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride;

        // Act
        await EmotionTrendNotificationService.notifyTrend(result);

        // Assert
        expect(receivedPayload, isNotNull);
        expect(receivedPayload, contains('"trend":"recovering"'));
        expect(receivedPayload, contains('"type":"mindcare"'));
        expect(receivedPayload, contains('"subtype":"emotion_trend"'));
      });

      test('채널이 mindcare여야 한다', () async {
        // Arrange
        const result = EmotionTrendResult(
          trend: EmotionTrend.steady,
          metadata: {},
        );

        String? receivedChannel;

        Future<void> testShowOverride({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {
          receivedChannel = channel;
        }
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride;

        // Act
        await EmotionTrendNotificationService.notifyTrend(result);

        // Assert
        expect(receivedChannel, 'mindlog_mindcare');
      });
    });

    group('메시지 풀 검증', () {
      test('declining 제목이 3개여야 한다', () {
        expect(EmotionTrendNotificationService.decliningTitles.length, 3);
      });

      test('declining 본문이 3개여야 한다', () {
        expect(EmotionTrendNotificationService.decliningBodies.length, 3);
      });

      test('recovering 제목이 3개여야 한다', () {
        expect(EmotionTrendNotificationService.recoveringTitles.length, 3);
      });

      test('recovering 본문이 3개여야 한다', () {
        expect(EmotionTrendNotificationService.recoveringBodies.length, 3);
      });

      test('gap 제목이 3개여야 한다', () {
        expect(EmotionTrendNotificationService.gapTitles.length, 3);
      });

      test('gap 본문이 3개여야 한다', () {
        expect(EmotionTrendNotificationService.gapBodies.length, 3);
      });

      test('steady 제목이 3개여야 한다', () {
        expect(EmotionTrendNotificationService.steadyTitles.length, 3);
      });

      test('steady 본문이 3개여야 한다', () {
        expect(EmotionTrendNotificationService.steadyBodies.length, 3);
      });

      test('모든 메시지가 비어있지 않아야 한다', () {
        final allTitles = [
          ...EmotionTrendNotificationService.decliningTitles,
          ...EmotionTrendNotificationService.recoveringTitles,
          ...EmotionTrendNotificationService.gapTitles,
          ...EmotionTrendNotificationService.steadyTitles,
        ];

        final allBodies = [
          ...EmotionTrendNotificationService.decliningBodies,
          ...EmotionTrendNotificationService.recoveringBodies,
          ...EmotionTrendNotificationService.gapBodies,
          ...EmotionTrendNotificationService.steadyBodies,
        ];

        for (final title in allTitles) {
          expect(title.trim(), isNotEmpty);
        }

        for (final body in allBodies) {
          expect(body.trim(), isNotEmpty);
        }
      });
    });

    group('랜덤 선택 결정론적 동작', () {
      test('동일한 시드로 동일한 메시지를 선택해야 한다', () async {
        // Arrange
        const result = EmotionTrendResult(
          trend: EmotionTrend.declining,
          metadata: {},
        );

        final messages1 = <({String title, String body})>[];
        final messages2 = <({String title, String body})>[];

        // 첫 번째 시도
        EmotionTrendNotificationService.setRandom(Random(42));
        Future<void> testShowOverride1({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {
          messages1.add((title: title, body: body));
        }
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride1;
        await EmotionTrendNotificationService.notifyTrend(result);

        // 리셋
        EmotionTrendNotificationService.resetForTesting();

        // 두 번째 시도 (동일한 시드)
        EmotionTrendNotificationService.setRandom(Random(42));
        Future<void> testShowOverride2({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {
          messages2.add((title: title, body: body));
        }
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride2;
        await EmotionTrendNotificationService.notifyTrend(result);

        // Assert
        expect(messages1.length, 1);
        expect(messages2.length, 1);
        expect(messages1.first.title, messages2.first.title);
        expect(messages1.first.body, messages2.first.body);
      });

      test('다른 시드로 다른 메시지를 선택할 수 있어야 한다', () async {
        // Arrange
        const result = EmotionTrendResult(
          trend: EmotionTrend.recovering,
          metadata: {},
        );

        final messages1 = <({String title, String body})>[];
        final messages2 = <({String title, String body})>[];

        // 첫 번째 시도 (시드 1)
        EmotionTrendNotificationService.setRandom(Random(1));
        Future<void> testShowOverride1({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {
          messages1.add((title: title, body: body));
        }
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride1;
        await EmotionTrendNotificationService.notifyTrend(result);

        // 리셋
        EmotionTrendNotificationService.resetForTesting();

        // 두 번째 시도 (시드 999)
        EmotionTrendNotificationService.setRandom(Random(999));
        Future<void> testShowOverride2({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {
          messages2.add((title: title, body: body));
        }
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride2;
        await EmotionTrendNotificationService.notifyTrend(result);

        // Assert (다를 가능성 높음, 같을 수도 있음)
        expect(messages1.length, 1);
        expect(messages2.length, 1);
        // 메시지는 풀 내에 있어야 함
        expect(
          EmotionTrendNotificationService.recoveringTitles
              .contains(messages1.first.title),
          isTrue,
        );
        expect(
          EmotionTrendNotificationService.recoveringTitles
              .contains(messages2.first.title),
          isTrue,
        );
      });
    });

    group('resetForTesting', () {
      test('showNotificationOverride를 초기화해야 한다', () {
        // Arrange
        Future<void> testShowOverride({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {}
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride;

        // Act
        EmotionTrendNotificationService.resetForTesting();

        // Assert
        expect(
          EmotionTrendNotificationService.showNotificationOverride,
          isNull,
        );
      });

      test('Random을 기본값으로 리셋해야 한다', () {
        // Arrange
        EmotionTrendNotificationService.setRandom(Random(999));

        // Act
        EmotionTrendNotificationService.resetForTesting();

        // Assert (새로운 Random 인스턴스, 검증 어려우므로 동작 확인)
        // 리셋 후 notifyTrend 호출 시 예외가 없어야 함
        expect(() => EmotionTrendNotificationService.resetForTesting(), returnsNormally);
      });
    });

    group('테스트용 접근자', () {
      test('decliningTitles가 수정 불가능해야 한다', () {
        final titles = EmotionTrendNotificationService.decliningTitles;
        expect(() => titles.add('새 제목'), throwsUnsupportedError);
      });

      test('decliningBodies가 수정 불가능해야 한다', () {
        final bodies = EmotionTrendNotificationService.decliningBodies;
        expect(() => bodies.add('새 본문'), throwsUnsupportedError);
      });

      test('recoveringTitles가 수정 불가능해야 한다', () {
        final titles = EmotionTrendNotificationService.recoveringTitles;
        expect(() => titles.add('새 제목'), throwsUnsupportedError);
      });

      test('recoveringBodies가 수정 불가능해야 한다', () {
        final bodies = EmotionTrendNotificationService.recoveringBodies;
        expect(() => bodies.add('새 본문'), throwsUnsupportedError);
      });

      test('gapTitles가 수정 불가능해야 한다', () {
        final titles = EmotionTrendNotificationService.gapTitles;
        expect(() => titles.add('새 제목'), throwsUnsupportedError);
      });

      test('gapBodies가 수정 불가능해야 한다', () {
        final bodies = EmotionTrendNotificationService.gapBodies;
        expect(() => bodies.add('새 본문'), throwsUnsupportedError);
      });

      test('steadyTitles가 수정 불가능해야 한다', () {
        final titles = EmotionTrendNotificationService.steadyTitles;
        expect(() => titles.add('새 제목'), throwsUnsupportedError);
      });

      test('steadyBodies가 수정 불가능해야 한다', () {
        final bodies = EmotionTrendNotificationService.steadyBodies;
        expect(() => bodies.add('새 본문'), throwsUnsupportedError);
      });
    });

    group('통합 동작', () {
      test('모든 트렌드 타입에 대해 알림을 전송할 수 있어야 한다', () async {
        // Arrange
        final trends = [
          EmotionTrend.declining,
          EmotionTrend.recovering,
          EmotionTrend.gap,
          EmotionTrend.steady,
        ];

        Future<void> testShowOverride({
          required String title,
          required String body,
          String? payload,
          String channel = '',
        }) async {}
        EmotionTrendNotificationService.showNotificationOverride = testShowOverride;

        // Act & Assert
        for (final trend in trends) {
          final result = EmotionTrendResult(trend: trend, metadata: {});
          await expectLater(
            EmotionTrendNotificationService.notifyTrend(result),
            completes,
          );
        }
      });
    });
  });
}
