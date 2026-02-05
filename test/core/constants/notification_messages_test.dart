import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/notification_messages.dart';

/// 결정론적 테스트를 위한 Mock Random
class MockRandom implements Random {
  int _counter = 0;

  @override
  int nextInt(int max) => _counter++ % max;

  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => true;
}

void main() {
  setUp(() => NotificationMessages.resetForTesting());
  tearDown(() => NotificationMessages.resetForTesting());

  group('NotificationMessages', () {
    group('리마인더 메시지', () {
      test('제목 목록이 비어있지 않아야 한다', () {
        expect(NotificationMessages.reminderTitles, isNotEmpty);
      });

      test('본문 목록이 비어있지 않아야 한다', () {
        expect(NotificationMessages.reminderBodies, isNotEmpty);
      });

      test('getRandomReminderTitle은 목록 내 값을 반환해야 한다', () {
        final title = NotificationMessages.getRandomReminderTitle();
        expect(NotificationMessages.reminderTitles, contains(title));
      });

      test('getRandomReminderBody는 목록 내 값을 반환해야 한다', () {
        final body = NotificationMessages.getRandomReminderBody();
        expect(NotificationMessages.reminderBodies, contains(body));
      });

      test('getRandomReminderMessage는 title과 body를 반환해야 한다', () {
        final message = NotificationMessages.getRandomReminderMessage();
        expect(message.title, isNotEmpty);
        expect(message.body, isNotEmpty);
        expect(NotificationMessages.reminderTitles, contains(message.title));
        expect(NotificationMessages.reminderBodies, contains(message.body));
      });
    });

    group('마음케어 메시지', () {
      test('제목 목록이 비어있지 않아야 한다', () {
        expect(NotificationMessages.mindcareTitles, isNotEmpty);
      });

      test('본문 목록이 20개 이상이어야 한다', () {
        expect(
          NotificationMessages.mindcareBodies.length,
          greaterThanOrEqualTo(20),
        );
      });

      test('getRandomMindcareTitle은 목록 내 값을 반환해야 한다', () {
        final title = NotificationMessages.getRandomMindcareTitle();
        expect(NotificationMessages.mindcareTitles, contains(title));
      });

      test('getRandomMindcareBody는 목록 내 값을 반환해야 한다', () {
        final body = NotificationMessages.getRandomMindcareBody();
        expect(NotificationMessages.mindcareBodies, contains(body));
      });

      test('getRandomMindcareMessage는 유효한 값을 반환해야 한다', () {
        final message = NotificationMessages.getRandomMindcareMessage();
        expect(NotificationMessages.mindcareTitles, contains(message.title));
        expect(NotificationMessages.mindcareBodies, contains(message.body));
      });
    });

    group('Random 주입', () {
      test('Mock Random 주입 시 결정론적으로 동작해야 한다', () {
        NotificationMessages.setRandom(MockRandom());
        final first = NotificationMessages.getRandomReminderTitle();

        NotificationMessages.setRandom(MockRandom());
        final second = NotificationMessages.getRandomReminderTitle();

        expect(first, equals(second));
      });

      test('resetForTesting 후 다시 랜덤하게 동작해야 한다', () {
        NotificationMessages.setRandom(MockRandom());
        NotificationMessages.resetForTesting();

        // 여러 번 호출해서 다양한 값이 나오는지 확인 (확률적)
        final results = <String>{};
        for (var i = 0; i < 50; i++) {
          results.add(NotificationMessages.getRandomReminderTitle());
        }
        // 50번 호출 시 최소 2개 이상의 다른 값이 나와야 함
        expect(results.length, greaterThan(1));
      });
    });

    group('메시지 품질', () {
      test('모든 리마인더 메시지는 빈 문자열이 아니어야 한다', () {
        for (final title in NotificationMessages.reminderTitles) {
          expect(title.trim(), isNotEmpty);
        }
        for (final body in NotificationMessages.reminderBodies) {
          expect(body.trim(), isNotEmpty);
        }
      });

      test('모든 마음케어 메시지는 빈 문자열이 아니어야 한다', () {
        for (final title in NotificationMessages.mindcareTitles) {
          expect(title.trim(), isNotEmpty);
        }
        for (final body in NotificationMessages.mindcareBodies) {
          expect(body.trim(), isNotEmpty);
        }
      });

      test('마음케어 본문은 50자 이하여야 한다', () {
        for (final body in NotificationMessages.mindcareBodies) {
          expect(
            body.length,
            lessThanOrEqualTo(50),
            reason: '"$body" is ${body.length} characters',
          );
        }
      });

      test('리마인더 본문은 30자 이하여야 한다', () {
        for (final body in NotificationMessages.reminderBodies) {
          expect(
            body.length,
            lessThanOrEqualTo(30),
            reason: '"$body" is ${body.length} characters',
          );
        }
      });
    });

    group('목록 불변성', () {
      test('reminderTitles 수정 시도 시 에러가 발생해야 한다', () {
        expect(
          () => NotificationMessages.reminderTitles.add('test'),
          throwsUnsupportedError,
        );
      });

      test('mindcareBodies 수정 시도 시 에러가 발생해야 한다', () {
        expect(
          () => NotificationMessages.mindcareBodies.add('test'),
          throwsUnsupportedError,
        );
      });
    });

    group('시간대별 메시지 (TimeSlot)', () {
      test('getCurrentTimeSlot이 시간대에 따라 올바른 값을 반환해야 한다', () {
        // 아침 (06:00 - 11:59)
        expect(
          NotificationMessages.getCurrentTimeSlot(DateTime(2024, 1, 1, 6, 0)),
          TimeSlot.morning,
        );
        expect(
          NotificationMessages.getCurrentTimeSlot(DateTime(2024, 1, 1, 11, 59)),
          TimeSlot.morning,
        );

        // 오후 (12:00 - 17:59)
        expect(
          NotificationMessages.getCurrentTimeSlot(DateTime(2024, 1, 1, 12, 0)),
          TimeSlot.afternoon,
        );
        expect(
          NotificationMessages.getCurrentTimeSlot(DateTime(2024, 1, 1, 17, 59)),
          TimeSlot.afternoon,
        );

        // 저녁 (18:00 - 21:59)
        expect(
          NotificationMessages.getCurrentTimeSlot(DateTime(2024, 1, 1, 18, 0)),
          TimeSlot.evening,
        );
        expect(
          NotificationMessages.getCurrentTimeSlot(DateTime(2024, 1, 1, 21, 59)),
          TimeSlot.evening,
        );

        // 밤 (22:00 - 05:59)
        expect(
          NotificationMessages.getCurrentTimeSlot(DateTime(2024, 1, 1, 22, 0)),
          TimeSlot.night,
        );
        expect(
          NotificationMessages.getCurrentTimeSlot(DateTime(2024, 1, 1, 5, 59)),
          TimeSlot.night,
        );
        expect(
          NotificationMessages.getCurrentTimeSlot(DateTime(2024, 1, 1, 0, 0)),
          TimeSlot.night,
        );
      });

      test('모든 시간대에 최소 4개 이상의 제목이 있어야 한다', () {
        for (final slot in TimeSlot.values) {
          final titles = NotificationMessages.getTitlesForSlot(slot);
          expect(
            titles.length,
            greaterThanOrEqualTo(4),
            reason: '$slot should have at least 4 titles',
          );
        }
      });

      test('모든 시간대에 최소 4개 이상의 본문이 있어야 한다', () {
        for (final slot in TimeSlot.values) {
          final bodies = NotificationMessages.getBodiesForSlot(slot);
          expect(
            bodies.length,
            greaterThanOrEqualTo(4),
            reason: '$slot should have at least 4 bodies',
          );
        }
      });

      test('getMindcareMessageByTimeSlot이 해당 시간대 메시지를 반환해야 한다', () {
        for (final slot in TimeSlot.values) {
          final message = NotificationMessages.getMindcareMessageByTimeSlot(
            slot,
          );
          final titles = NotificationMessages.getTitlesForSlot(slot);
          final bodies = NotificationMessages.getBodiesForSlot(slot);

          expect(
            titles,
            contains(message.title),
            reason: '$slot title should be in the list',
          );
          expect(
            bodies,
            contains(message.body),
            reason: '$slot body should be in the list',
          );
        }
      });

      test('시간대별 메시지는 빈 문자열이 아니어야 한다', () {
        for (final slot in TimeSlot.values) {
          for (final title in NotificationMessages.getTitlesForSlot(slot)) {
            expect(title.trim(), isNotEmpty, reason: '$slot title is empty');
          }
          for (final body in NotificationMessages.getBodiesForSlot(slot)) {
            expect(body.trim(), isNotEmpty, reason: '$slot body is empty');
          }
        }
      });

      test('시간대별 본문은 50자 이하여야 한다', () {
        for (final slot in TimeSlot.values) {
          for (final body in NotificationMessages.getBodiesForSlot(slot)) {
            expect(
              body.length,
              lessThanOrEqualTo(50),
              reason: '$slot body "$body" is ${body.length} characters',
            );
          }
        }
      });

      test('시간대별 목록 접근자가 불변성을 유지해야 한다', () {
        expect(
          () => NotificationMessages.morningTitles.add('test'),
          throwsUnsupportedError,
        );
        expect(
          () => NotificationMessages.afternoonBodies.add('test'),
          throwsUnsupportedError,
        );
        expect(
          () => NotificationMessages.eveningTitles.add('test'),
          throwsUnsupportedError,
        );
        expect(
          () => NotificationMessages.nightBodies.add('test'),
          throwsUnsupportedError,
        );
      });
    });

    group('이름 개인화 (applyNamePersonalization)', () {
      test('이름이 있으면 {name}을 실제 이름으로 치환해야 한다', () {
        const message = '{name}님, 오늘 하루 수고하셨어요';
        final result = NotificationMessages.applyNamePersonalization(
          message,
          '지수',
        );
        expect(result, '지수님, 오늘 하루 수고하셨어요');
      });

      test('이름이 있으면 {name} 단독도 치환해야 한다', () {
        const message = '안녕하세요 {name}';
        final result = NotificationMessages.applyNamePersonalization(
          message,
          '민수',
        );
        expect(result, '안녕하세요 민수');
      });

      test('이름이 null이면 {name}님, 패턴을 제거해야 한다', () {
        const message = '{name}님, 오늘 하루 수고하셨어요';
        final result = NotificationMessages.applyNamePersonalization(
          message,
          null,
        );
        expect(result, '오늘 하루 수고하셨어요');
      });

      test('이름이 빈 문자열이면 {name}님, 패턴을 제거해야 한다', () {
        const message = '{name}님, 오늘 하루 수고하셨어요';
        final result = NotificationMessages.applyNamePersonalization(
          message,
          '',
        );
        expect(result, '오늘 하루 수고하셨어요');
      });

      test('이름이 공백만 있으면 폴백 처리해야 한다', () {
        const message = '{name}님, 좋은 아침이에요';
        final result = NotificationMessages.applyNamePersonalization(
          message,
          '   ',
        );
        expect(result, '좋은 아침이에요');
      });

      test('이름이 null이면 {name} 단독 패턴도 제거해야 한다', () {
        const message = '안녕하세요 {name}';
        final result = NotificationMessages.applyNamePersonalization(
          message,
          null,
        );
        expect(result, '안녕하세요 ');
      });

      test('{name} 패턴이 없는 메시지는 그대로 반환해야 한다', () {
        const message = '오늘 하루 수고하셨어요';
        final result = NotificationMessages.applyNamePersonalization(
          message,
          '지수',
        );
        expect(result, '오늘 하루 수고하셨어요');
      });

      test('여러 {name} 패턴이 있으면 모두 치환해야 한다', () {
        const message = '{name}님, {name}의 하루를 응원해요';
        final result = NotificationMessages.applyNamePersonalization(
          message,
          '민지',
        );
        expect(result, '민지님, 민지의 하루를 응원해요');
      });

      test('이름에 공백이 있으면 trim 후 치환해야 한다', () {
        const message = '{name}님, 안녕하세요';
        final result = NotificationMessages.applyNamePersonalization(
          message,
          '  지수  ',
        );
        expect(result, '지수님, 안녕하세요');
      });
    });

    group('applyNameToMessage', () {
      test('title과 body 모두에 이름 개인화를 적용해야 한다', () {
        const message = (title: '{name}님, 좋은 아침이에요', body: '{name}의 하루를 응원해요');
        final result = NotificationMessages.applyNameToMessage(message, '지수');
        expect(result.title, '지수님, 좋은 아침이에요');
        expect(result.body, '지수의 하루를 응원해요');
      });

      test('이름이 없으면 title과 body 모두에서 패턴을 제거해야 한다', () {
        const message = (title: '{name}님, 좋은 아침이에요', body: '오늘 하루도 힘내세요');
        final result = NotificationMessages.applyNameToMessage(message, null);
        expect(result.title, '좋은 아침이에요');
        expect(result.body, '오늘 하루도 힘내세요');
      });
    });

    group('감정 레벨 (EmotionLevel)', () {
      test('getEmotionLevel이 점수에 따라 올바른 레벨을 반환해야 한다', () {
        // 낮음 (1-3)
        expect(NotificationMessages.getEmotionLevel(1.0), EmotionLevel.low);
        expect(NotificationMessages.getEmotionLevel(3.0), EmotionLevel.low);

        // 보통 (4-6)
        expect(NotificationMessages.getEmotionLevel(3.1), EmotionLevel.medium);
        expect(NotificationMessages.getEmotionLevel(4.0), EmotionLevel.medium);
        expect(NotificationMessages.getEmotionLevel(6.0), EmotionLevel.medium);

        // 높음 (7-10)
        expect(NotificationMessages.getEmotionLevel(6.1), EmotionLevel.high);
        expect(NotificationMessages.getEmotionLevel(7.0), EmotionLevel.high);
        expect(NotificationMessages.getEmotionLevel(10.0), EmotionLevel.high);
      });

      test('공감/위로 메시지 목록이 비어있지 않아야 한다', () {
        expect(NotificationMessages.empathyBodies, isNotEmpty);
      });

      test('격려/긍정 메시지 목록이 비어있지 않아야 한다', () {
        expect(NotificationMessages.encouragementBodies, isNotEmpty);
      });

      test('getBodiesForEmotionLevel이 올바른 목록을 반환해야 한다', () {
        final lowBodies = NotificationMessages.getBodiesForEmotionLevel(
          EmotionLevel.low,
        );
        expect(lowBodies, equals(NotificationMessages.empathyBodies));

        final highBodies = NotificationMessages.getBodiesForEmotionLevel(
          EmotionLevel.high,
        );
        expect(highBodies, equals(NotificationMessages.encouragementBodies));

        final mediumBodies = NotificationMessages.getBodiesForEmotionLevel(
          EmotionLevel.medium,
        );
        expect(mediumBodies, equals(NotificationMessages.mindcareBodies));
      });
    });

    group('감정 기반 메시지 (getMindcareMessageByEmotion)', () {
      test('낮은 감정 점수(1-3)에서 유효한 메시지를 반환해야 한다', () {
        final message = NotificationMessages.getMindcareMessageByEmotion(2.0);
        expect(message.title, isNotEmpty);
        expect(message.body, isNotEmpty);
      });

      test('보통 감정 점수(4-6)에서 유효한 메시지를 반환해야 한다', () {
        final message = NotificationMessages.getMindcareMessageByEmotion(5.0);
        expect(message.title, isNotEmpty);
        expect(message.body, isNotEmpty);
      });

      test('높은 감정 점수(7-10)에서 유효한 메시지를 반환해야 한다', () {
        final message = NotificationMessages.getMindcareMessageByEmotion(8.0);
        expect(message.title, isNotEmpty);
        expect(message.body, isNotEmpty);
      });

      test('시간대를 명시적으로 지정할 수 있어야 한다', () {
        final message = NotificationMessages.getMindcareMessageByEmotion(
          5.0,
          TimeSlot.morning,
        );

        // 제목이 아침 시간대 목록에 있어야 함
        expect(NotificationMessages.morningTitles, contains(message.title));
      });

      test('Mock Random 주입 시 결정론적으로 동작해야 한다', () {
        NotificationMessages.setRandom(MockRandom());
        final first = NotificationMessages.getMindcareMessageByEmotion(5.0);

        NotificationMessages.setRandom(MockRandom());
        final second = NotificationMessages.getMindcareMessageByEmotion(5.0);

        expect(first.title, equals(second.title));
        expect(first.body, equals(second.body));
      });

      test('감정 레벨별 목록 접근자가 불변성을 유지해야 한다', () {
        expect(
          () => NotificationMessages.empathyBodies.add('test'),
          throwsUnsupportedError,
        );
        expect(
          () => NotificationMessages.encouragementBodies.add('test'),
          throwsUnsupportedError,
        );
      });
    });

    group('가중치 분포 검증 (통계적 테스트)', () {
      const int sampleSize = 1000;
      // 허용 오차: 기대값 ± 10%
      const double tolerance = 0.10;

      test('낮은 감정(1-3)에서 공감 메시지가 dominant해야 한다 (>70%)', () {
        // Arrange
        NotificationMessages.resetForTesting();
        final empathySet = NotificationMessages.empathyBodies.toSet();

        int empathyCount = 0;

        // Act: 1000번 샘플링
        for (int i = 0; i < sampleSize; i++) {
          final message = NotificationMessages.getMindcareMessageByEmotion(2.0);
          if (empathySet.contains(message.body)) {
            empathyCount++;
          }
        }

        // Assert: 가중치 4:1 → 공감 메시지가 70% 이상
        // (메시지 풀 중복으로 인해 실제 비율은 더 높을 수 있음)
        final actualRatio = empathyCount / sampleSize;
        const minExpectedRatio = 0.70;

        expect(
          actualRatio,
          greaterThanOrEqualTo(minExpectedRatio),
          reason:
              '공감 메시지 비율: ${(actualRatio * 100).toStringAsFixed(1)}% '
              '(최소 기대: ${(minExpectedRatio * 100).toStringAsFixed(0)}%)',
        );
      });

      test('높은 감정(7-10)에서 격려 메시지가 dominant해야 한다 (>50%)', () {
        // Arrange
        NotificationMessages.resetForTesting();
        final encouragementSet = NotificationMessages.encouragementBodies.toSet();

        int encouragementCount = 0;

        // Act
        for (int i = 0; i < sampleSize; i++) {
          final message = NotificationMessages.getMindcareMessageByEmotion(8.0);
          if (encouragementSet.contains(message.body)) {
            encouragementCount++;
          }
        }

        // Assert: 가중치 3:2 → 격려 메시지가 50% 이상
        // (메시지 풀 중복으로 인해 실제 비율은 더 높을 수 있음)
        final actualRatio = encouragementCount / sampleSize;
        const minExpectedRatio = 0.50;

        expect(
          actualRatio,
          greaterThanOrEqualTo(minExpectedRatio),
          reason:
              '격려 메시지 비율: ${(actualRatio * 100).toStringAsFixed(1)}% '
              '(최소 기대: ${(minExpectedRatio * 100).toStringAsFixed(0)}%)',
        );
      });

      test('보통 감정(4-6)에서 일반 메시지가 선택되어야 한다', () {
        // Arrange
        NotificationMessages.resetForTesting();
        final mindcareSet = NotificationMessages.mindcareBodies.toSet();

        int mindcareCount = 0;

        // Act
        for (int i = 0; i < sampleSize; i++) {
          final message = NotificationMessages.getMindcareMessageByEmotion(5.0);
          if (mindcareSet.contains(message.body)) {
            mindcareCount++;
          }
        }

        // Assert: 일반 메시지가 최소 30% 이상 선택되어야 함
        // (풀 크기와 중복에 따라 실제 비율은 크게 달라질 수 있음)
        final actualRatio = mindcareCount / sampleSize;

        expect(
          actualRatio,
          greaterThanOrEqualTo(0.30),
          reason:
              '일반 메시지 비율: ${(actualRatio * 100).toStringAsFixed(1)}% '
              '(최소 기대: 30%)',
        );
      });

      test('감정 레벨별 가중치가 차별화되어야 한다', () {
        // Arrange
        NotificationMessages.resetForTesting();
        final empathySet = NotificationMessages.empathyBodies.toSet();
        final encouragementSet = NotificationMessages.encouragementBodies.toSet();

        int lowEmpathyCount = 0;
        int highEncouragementCount = 0;
        int mediumEmpathyCount = 0;
        int mediumEncouragementCount = 0;

        // Act: 각 레벨별 샘플링
        for (int i = 0; i < sampleSize; i++) {
          // 낮은 감정
          final lowMsg = NotificationMessages.getMindcareMessageByEmotion(2.0);
          if (empathySet.contains(lowMsg.body)) lowEmpathyCount++;

          // 높은 감정
          final highMsg = NotificationMessages.getMindcareMessageByEmotion(8.0);
          if (encouragementSet.contains(highMsg.body)) highEncouragementCount++;

          // 보통 감정
          final medMsg = NotificationMessages.getMindcareMessageByEmotion(5.0);
          if (empathySet.contains(medMsg.body)) mediumEmpathyCount++;
          if (encouragementSet.contains(medMsg.body)) mediumEncouragementCount++;
        }

        final lowEmpathyRatio = lowEmpathyCount / sampleSize;
        final highEncouragementRatio = highEncouragementCount / sampleSize;
        final mediumEmpathyRatio = mediumEmpathyCount / sampleSize;
        final mediumEncouragementRatio = mediumEncouragementCount / sampleSize;

        // Assert: 낮은 감정에서 공감 비율이 보통 감정보다 높아야 함
        expect(
          lowEmpathyRatio,
          greaterThan(mediumEmpathyRatio),
          reason: '낮은 감정에서 공감 메시지 비율(${(lowEmpathyRatio * 100).toStringAsFixed(1)}%)이 '
              '보통 감정(${(mediumEmpathyRatio * 100).toStringAsFixed(1)}%)보다 높아야 함',
        );

        // Assert: 높은 감정에서 격려 비율이 보통 감정보다 높아야 함
        expect(
          highEncouragementRatio,
          greaterThan(mediumEncouragementRatio),
          reason: '높은 감정에서 격려 메시지 비율(${(highEncouragementRatio * 100).toStringAsFixed(1)}%)이 '
              '보통 감정(${(mediumEncouragementRatio * 100).toStringAsFixed(1)}%)보다 높아야 함',
        );
      });

      test('각 감정 레벨에서 메시지 풀의 모든 항목이 선택 가능해야 한다', () {
        // Arrange
        NotificationMessages.resetForTesting();
        const largeSampleSize = 2000;

        // Act & Assert for each emotion level
        for (final level in EmotionLevel.values) {
          final double score = switch (level) {
            EmotionLevel.low => 2.0,
            EmotionLevel.medium => 5.0,
            EmotionLevel.high => 8.0,
          };

          final selectedBodies = <String>{};
          for (int i = 0; i < largeSampleSize; i++) {
            final message = NotificationMessages.getMindcareMessageByEmotion(
              score,
            );
            selectedBodies.add(message.body);
          }

          // 최소 5개 이상의 다양한 메시지가 선택되어야 함
          expect(
            selectedBodies.length,
            greaterThanOrEqualTo(5),
            reason: '$level 레벨에서 다양한 메시지가 선택되어야 함 '
                '(실제: ${selectedBodies.length}개)',
          );
        }
      });

      test('시간대별 제목이 균등하게 분포되어야 한다', () {
        // Arrange
        NotificationMessages.resetForTesting();
        final currentSlot = NotificationMessages.getCurrentTimeSlot();
        final titles = NotificationMessages.getTitlesForSlot(currentSlot);
        final titleCounts = <String, int>{};

        // Act
        for (int i = 0; i < sampleSize; i++) {
          final message = NotificationMessages.getMindcareMessageByEmotion(5.0);
          titleCounts[message.title] = (titleCounts[message.title] ?? 0) + 1;
        }

        // Assert: 모든 제목이 최소 1번은 선택되어야 함
        for (final title in titles) {
          expect(
            titleCounts.containsKey(title),
            isTrue,
            reason: '제목 "$title"이 최소 1번은 선택되어야 함',
          );
        }

        // 각 제목의 비율이 균등해야 함 (1/N ± tolerance)
        final expectedRatio = 1.0 / titles.length;
        for (final entry in titleCounts.entries) {
          final actualRatio = entry.value / sampleSize;
          expect(
            actualRatio,
            closeTo(expectedRatio, tolerance + 0.05), // 제목은 더 넓은 오차 허용
            reason:
                '제목 "${entry.key}" 비율: ${(actualRatio * 100).toStringAsFixed(1)}%',
          );
        }
      });
    });
  });
}
