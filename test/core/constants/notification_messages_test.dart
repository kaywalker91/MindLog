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

      test('getRandomReminderTitle은 {name}이 제거된 유효한 값을 반환해야 한다', () {
        final title = NotificationMessages.getRandomReminderTitle();
        expect(title, isNot(contains('{name}')));
        expect(title.trim(), isNotEmpty);
      });

      test('getRandomReminderBody는 목록 내 값을 반환해야 한다', () {
        final body = NotificationMessages.getRandomReminderBody();
        expect(NotificationMessages.reminderBodies, contains(body));
      });

      test('getRandomReminderMessage는 title과 body를 반환해야 한다', () {
        final message = NotificationMessages.getRandomReminderMessage();
        expect(message.title, isNotEmpty);
        expect(message.body, isNotEmpty);
        expect(message.title, isNot(contains('{name}')));
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

    group('Cheer Me 제목 (getCheerMeTitle)', () {
      test('cheerMeTitles 목록이 8개여야 한다', () {
        expect(NotificationMessages.cheerMeTitles, hasLength(8));
      });

      test('cheerMeTitles 목록이 불변이어야 한다', () {
        expect(
          () => NotificationMessages.cheerMeTitles.add('test'),
          throwsUnsupportedError,
        );
      });

      test('이름이 있으면 {name}을 치환한 제목을 반환해야 한다', () {
        NotificationMessages.setRandom(MockRandom());
        final title = NotificationMessages.getCheerMeTitle('지수');
        expect(title, isNot(contains('{name}')));
        // MockRandom은 counter=0 → index 0 → '{name}님의 응원 메시지'
        expect(title, '지수님의 응원 메시지');
      });

      test('이름이 null이면 {name} 패턴을 제거한 제목을 반환해야 한다', () {
        NotificationMessages.setRandom(MockRandom());
        final title = NotificationMessages.getCheerMeTitle(null);
        expect(title, isNot(contains('{name}')));
        // '{name}님의 응원 메시지' → '응원 메시지'
        expect(title, '응원 메시지');
      });

      test('Mock Random으로 결정론적 제목 선택을 확인해야 한다', () {
        NotificationMessages.setRandom(MockRandom());
        final first = NotificationMessages.getCheerMeTitle('민수');

        NotificationMessages.setRandom(MockRandom());
        final second = NotificationMessages.getCheerMeTitle('민수');

        expect(first, equals(second));
      });

      test('모든 cheerMeTitles에 {name}이 포함되어야 한다 (100%)', () {
        final titles = NotificationMessages.cheerMeTitles;
        for (final title in titles) {
          expect(
            title.contains('{name}'),
            isTrue,
            reason: '"{name}" 패턴 누락: "$title"',
          );
        }
      });

      test('모든 cheerMeTitles에 이름 개인화가 올바르게 적용되어야 한다', () {
        for (final title in NotificationMessages.cheerMeTitles) {
          final withName = NotificationMessages.applyNamePersonalization(
            title,
            '테스트',
          );
          final withoutName = NotificationMessages.applyNamePersonalization(
            title,
            null,
          );
          expect(
            withName,
            isNot(contains('{name}')),
            reason: '이름 적용 후 {name} 남음: $withName (원본: $title)',
          );
          expect(
            withoutName,
            isNot(contains('{name}')),
            reason: '이름 제거 후 {name} 남음: $withoutName (원본: $title)',
          );
          expect(withoutName.trim(), isNotEmpty, reason: '제거 후 빈 문자열: $title');
        }
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

    group('applyNamePersonalization - 조사 커버리지 (Fix D)', () {
      test('{name}님에게 패턴을 null 이름에서 제거해야 한다', () {
        final result = NotificationMessages.applyNamePersonalization(
          '{name}님에게 보내는 응원',
          null,
        );
        expect(result, '보내는 응원');
      });

      test('{name}님께 패턴을 null 이름에서 제거해야 한다', () {
        final result = NotificationMessages.applyNamePersonalization(
          '{name}님께 드리는 메시지',
          null,
        );
        expect(result, '드리는 메시지');
      });

      test('{name}님에게 패턴에 실제 이름이 치환되어야 한다', () {
        final result = NotificationMessages.applyNamePersonalization(
          '{name}님에게 보내는 응원',
          '지수',
        );
        expect(result, '지수님에게 보내는 응원');
      });

      test('{name}님께 패턴에 실제 이름이 치환되어야 한다', () {
        final result = NotificationMessages.applyNamePersonalization(
          '{name}님께 드리는 메시지',
          '지수',
        );
        expect(result, '지수님께 드리는 메시지');
      });

      test('기존 조사 , 는 여전히 동작해야 한다', () {
        expect(
          NotificationMessages.applyNamePersonalization('{name}님, 안녕', null),
          '안녕',
        );
      });

      test('기존 조사 의 는 여전히 동작해야 한다', () {
        expect(
          NotificationMessages.applyNamePersonalization('{name}님의 응원', null),
          '응원',
        );
      });

      test('기존 조사 은 는 여전히 동작해야 한다', () {
        expect(
          NotificationMessages.applyNamePersonalization(
            '{name}님은 잘하고 있어요',
            null,
          ),
          '잘하고 있어요',
        );
      });

      test('기존 조사 을 는 여전히 동작해야 한다', () {
        expect(
          NotificationMessages.applyNamePersonalization('{name}님을 응원해요', null),
          '응원해요',
        );
      });

      test('기존 조사 이 는 여전히 동작해야 한다', () {
        expect(
          NotificationMessages.applyNamePersonalization(
            '{name}님이 잘하고 있어요',
            null,
          ),
          '잘하고 있어요',
        );
      });
    });

    group('getRandomReminderTitle - userName 파라미터 (Fix C)', () {
      test('userName 전달 시 {name}이 이름으로 치환되어야 한다', () {
        // MockRandom counter=0 → index 0 → '{name}님, 오늘 하루는 어떠셨나요?'
        NotificationMessages.setRandom(MockRandom());
        final title = NotificationMessages.getRandomReminderTitle('지수');
        expect(title, '지수님, 오늘 하루는 어떠셨나요?');
      });

      test('userName이 null이면 {name}님 패턴이 제거되어야 한다', () {
        NotificationMessages.setRandom(MockRandom());
        final title = NotificationMessages.getRandomReminderTitle(null);
        expect(title, isNot(contains('{name}')));
        expect(title.trim(), isNotEmpty);
      });

      test('userName이 빈 문자열이면 {name}님 패턴이 제거되어야 한다', () {
        NotificationMessages.setRandom(MockRandom());
        final title = NotificationMessages.getRandomReminderTitle('');
        expect(title, isNot(contains('{name}')));
      });

      test('인자 없이 호출해도 컴파일 오류 없이 {name} 제거됨', () {
        NotificationMessages.setRandom(MockRandom());
        final title = NotificationMessages.getRandomReminderTitle();
        expect(title, isNot(contains('{name}')));
      });

      test('{name}이 없는 템플릿은 userName과 무관하게 그대로 반환되어야 한다', () {
        // index 1 → '오늘 기분이 어떠셨어요?' ({name} 없음)
        NotificationMessages.setRandom(MockRandom()..nextInt(8)); // skip index 0
        final title = NotificationMessages.getRandomReminderTitle('지수');
        expect(title, '오늘 기분이 어떠셨어요?');
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

    group('실제 메시지 템플릿 이름 개인화 통합 테스트', () {
      test('감정 기반 메시지 + 이름 적용 시 {name}이 치환되어야 한다', () {
        // 여러 시드로 반복 검증
        for (int seed = 0; seed < 20; seed++) {
          NotificationMessages.setRandom(Random(seed));
          final message = NotificationMessages.getMindcareMessageByEmotion(8.0);
          final personalized = NotificationMessages.applyNameToMessage(
            message,
            '지수',
          );

          expect(
            personalized.title,
            isNot(contains('{name}')),
            reason: 'seed=$seed title: ${personalized.title}',
          );
          expect(
            personalized.body,
            isNot(contains('{name}')),
            reason: 'seed=$seed body: ${personalized.body}',
          );
        }
      });

      test('이름이 null이면 {name} 패턴이 깔끔하게 제거되어야 한다', () {
        for (int seed = 0; seed < 20; seed++) {
          NotificationMessages.setRandom(Random(seed));
          final message = NotificationMessages.getMindcareMessageByEmotion(2.0);
          final personalized = NotificationMessages.applyNameToMessage(
            message,
            null,
          );

          expect(
            personalized.title,
            isNot(contains('{name}')),
            reason: 'seed=$seed title: ${personalized.title}',
          );
          expect(
            personalized.body,
            isNot(contains('{name}')),
            reason: 'seed=$seed body: ${personalized.body}',
          );
        }
      });

      test('시간대별 메시지에도 이름이 적용되어야 한다', () {
        for (final slot in TimeSlot.values) {
          NotificationMessages.setRandom(MockRandom());
          final message = NotificationMessages.getMindcareMessageByTimeSlot(
            slot,
          );
          final personalized = NotificationMessages.applyNameToMessage(
            message,
            '민수',
          );

          expect(
            personalized.title,
            isNot(contains('{name}')),
            reason: '$slot title: ${personalized.title}',
          );
          expect(
            personalized.body,
            isNot(contains('{name}')),
            reason: '$slot body: ${personalized.body}',
          );
        }
      });

      test('모든 메시지 풀에서 {name} 패턴이 올바르게 처리되어야 한다', () {
        final allMessages = [
          ...NotificationMessages.cheerMeTitles,
          ...NotificationMessages.reminderTitles,
          ...NotificationMessages.reminderBodies,
          ...NotificationMessages.mindcareTitles,
          ...NotificationMessages.mindcareBodies,
          ...NotificationMessages.morningTitles,
          ...NotificationMessages.morningBodies,
          ...NotificationMessages.afternoonTitles,
          ...NotificationMessages.afternoonBodies,
          ...NotificationMessages.eveningTitles,
          ...NotificationMessages.eveningBodies,
          ...NotificationMessages.nightTitles,
          ...NotificationMessages.nightBodies,
          ...NotificationMessages.empathyBodies,
          ...NotificationMessages.encouragementBodies,
        ];

        for (final msg in allMessages) {
          final withName = NotificationMessages.applyNamePersonalization(
            msg,
            '테스트',
          );
          final withoutName = NotificationMessages.applyNamePersonalization(
            msg,
            null,
          );

          expect(
            withName,
            isNot(contains('{name}')),
            reason: '이름 적용 후에도 {name} 남음: $withName (원본: $msg)',
          );
          expect(
            withoutName,
            isNot(contains('{name}')),
            reason: '이름 제거 후에도 {name} 남음: $withoutName (원본: $msg)',
          );
        }
      });

      test('{name} 포함 메시지는 Cheer Me/리마인더에만 존재해야 한다', () {
        // 마음케어/시간대/감정 메시지에는 {name}이 없어야 함
        final mindcareMessages = [
          ...NotificationMessages.mindcareTitles,
          ...NotificationMessages.mindcareBodies,
          ...NotificationMessages.morningTitles,
          ...NotificationMessages.morningBodies,
          ...NotificationMessages.afternoonTitles,
          ...NotificationMessages.afternoonBodies,
          ...NotificationMessages.eveningTitles,
          ...NotificationMessages.eveningBodies,
          ...NotificationMessages.nightTitles,
          ...NotificationMessages.nightBodies,
          ...NotificationMessages.empathyBodies,
          ...NotificationMessages.encouragementBodies,
        ];

        for (final msg in mindcareMessages) {
          expect(
            msg.contains('{name}'),
            isFalse,
            reason: '마음케어 메시지에 {name} 패턴 발견: "$msg"',
          );
        }

        // Cheer Me와 리마인더에는 {name}이 포함된 메시지가 있어야 함
        final localMessages = [
          ...NotificationMessages.cheerMeTitles,
          ...NotificationMessages.reminderTitles,
        ];
        final nameCount = localMessages
            .where((m) => m.contains('{name}'))
            .length;
        expect(nameCount, greaterThan(0));
      });

      test('{name}님의 패턴이 null 이름에서 깔끔하게 제거되어야 한다', () {
        // {name}님의 패턴 테스트
        final result = NotificationMessages.applyNamePersonalization(
          '{name}님의 오늘의 격려',
          null,
        );
        expect(result, '오늘의 격려');
      });

      test('{name}님은 패턴이 null 이름에서 깔끔하게 제거되어야 한다', () {
        final result = NotificationMessages.applyNamePersonalization(
          '{name}님은 충분히 잘하고 있어요',
          null,
        );
        expect(result, '충분히 잘하고 있어요');
      });

      test('한 글자 이름이 올바르게 치환되어야 한다', () {
        final result = NotificationMessages.applyNamePersonalization(
          '{name}님, 오늘도 파이팅!',
          '수',
        );
        expect(result, '수님, 오늘도 파이팅!');
      });

      test('이모지 이름이 올바르게 치환되어야 한다', () {
        final result = NotificationMessages.applyNamePersonalization(
          '{name}님, 좋은 아침이에요',
          '😊',
        );
        expect(result, '😊님, 좋은 아침이에요');
      });

      test('{name} 문자열을 포함한 이름도 올바르게 처리되어야 한다', () {
        // 이름 자체에 "{name}" 문자열이 포함된 경우 — 치환 후 재귀 치환 없음 확인
        final result = NotificationMessages.applyNamePersonalization(
          '{name}님, 안녕하세요',
          '{name}테스트',
        );
        // 첫 번째 {name}이 이름으로 치환됨 → "{name}테스트님, 안녕하세요"
        expect(result, '{name}테스트님, 안녕하세요');
      });

      test('{name}님을 패턴이 null 이름에서 깔끔하게 제거되어야 한다', () {
        final result = NotificationMessages.applyNamePersonalization(
          '{name}님을 응원합니다',
          null,
        );
        expect(result, '응원합니다');
      });

      test('{name}님이 패턴이 null 이름에서 깔끔하게 제거되어야 한다', () {
        final result = NotificationMessages.applyNamePersonalization(
          '{name}님이 잘하고 있어요',
          null,
        );
        expect(result, '잘하고 있어요');
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
        final encouragementSet = NotificationMessages.encouragementBodies
            .toSet();

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
        final encouragementSet = NotificationMessages.encouragementBodies
            .toSet();

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
          if (empathySet.contains(medMsg.body)) {
            mediumEmpathyCount++;
          }
          if (encouragementSet.contains(medMsg.body)) {
            mediumEncouragementCount++;
          }
        }

        final lowEmpathyRatio = lowEmpathyCount / sampleSize;
        final highEncouragementRatio = highEncouragementCount / sampleSize;
        final mediumEmpathyRatio = mediumEmpathyCount / sampleSize;
        final mediumEncouragementRatio = mediumEncouragementCount / sampleSize;

        // Assert: 낮은 감정에서 공감 비율이 보통 감정보다 높아야 함
        expect(
          lowEmpathyRatio,
          greaterThan(mediumEmpathyRatio),
          reason:
              '낮은 감정에서 공감 메시지 비율(${(lowEmpathyRatio * 100).toStringAsFixed(1)}%)이 '
              '보통 감정(${(mediumEmpathyRatio * 100).toStringAsFixed(1)}%)보다 높아야 함',
        );

        // Assert: 높은 감정에서 격려 비율이 보통 감정보다 높아야 함
        expect(
          highEncouragementRatio,
          greaterThan(mediumEncouragementRatio),
          reason:
              '높은 감정에서 격려 메시지 비율(${(highEncouragementRatio * 100).toStringAsFixed(1)}%)이 '
              '보통 감정(${(mediumEncouragementRatio * 100).toStringAsFixed(1)}%)보다 높아야 함',
        );
      });

      group('인지 패턴 CBT 메시지 (getCognitivePatternMessage)', () {
        test('흑백사고 패턴에 대해 유효한 메시지를 반환해야 한다', () {
          final message = NotificationMessages.getCognitivePatternMessage(
            '흑백사고',
          );
          expect(message, isNotNull);
          expect(message!.title, isNotEmpty);
          expect(message.body, isNotEmpty);
        });

        test('과일반화 패턴에 대해 유효한 메시지를 반환해야 한다', () {
          final message = NotificationMessages.getCognitivePatternMessage(
            '과일반화',
          );
          expect(message, isNotNull);
          expect(message!.title, isNotEmpty);
          expect(message.body, isNotEmpty);
        });

        test('감정적추론 패턴에 대해 유효한 메시지를 반환해야 한다', () {
          final message = NotificationMessages.getCognitivePatternMessage(
            '감정적추론',
          );
          expect(message, isNotNull);
          expect(message!.title, isNotEmpty);
          expect(message.body, isNotEmpty);
        });

        test('당위적사고 패턴에 대해 유효한 메시지를 반환해야 한다', () {
          final message = NotificationMessages.getCognitivePatternMessage(
            '당위적사고',
          );
          expect(message, isNotNull);
          expect(message!.title, isNotEmpty);
          expect(message.body, isNotEmpty);
        });

        test('알 수 없는 패턴에 대해 null을 반환해야 한다', () {
          final message = NotificationMessages.getCognitivePatternMessage(
            '존재하지_않는_패턴',
          );
          expect(message, isNull);
        });

        test('빈 문자열 패턴에 대해 null을 반환해야 한다', () {
          final message = NotificationMessages.getCognitivePatternMessage('');
          expect(message, isNull);
        });

        test('지원되는 모든 패턴이 최소 3개 이상의 메시지를 가져야 한다', () {
          final patterns = NotificationMessages.supportedCognitivePatterns;
          expect(patterns, isNotEmpty);

          for (final pattern in patterns) {
            final messages =
                NotificationMessages.cognitivePatternMessages[pattern];
            expect(messages, isNotNull, reason: '$pattern에 메시지 목록이 없음');
            expect(
              messages!.length,
              greaterThanOrEqualTo(3),
              reason: '$pattern에 메시지가 3개 미만 (실제: ${messages.length}개)',
            );
          }
        });

        test('모든 인지 패턴 메시지는 빈 문자열이 아니어야 한다', () {
          final patterns = NotificationMessages.cognitivePatternMessages;
          for (final entry in patterns.entries) {
            for (final message in entry.value) {
              expect(
                message.title.trim(),
                isNotEmpty,
                reason: '${entry.key}의 title이 비어있음: "${message.title}"',
              );
              expect(
                message.body.trim(),
                isNotEmpty,
                reason: '${entry.key}의 body가 비어있음: "${message.body}"',
              );
            }
          }
        });

        test('인지 패턴 메시지 본문은 100자 이하여야 한다', () {
          final patterns = NotificationMessages.cognitivePatternMessages;
          for (final entry in patterns.entries) {
            for (final message in entry.value) {
              expect(
                message.body.length,
                lessThanOrEqualTo(100),
                reason:
                    '${entry.key}의 body가 100자 초과: "${message.body}" (${message.body.length}자)',
              );
            }
          }
        });

        test('인지 패턴 메시지 제목은 30자 이하여야 한다', () {
          final patterns = NotificationMessages.cognitivePatternMessages;
          for (final entry in patterns.entries) {
            for (final message in entry.value) {
              expect(
                message.title.length,
                lessThanOrEqualTo(30),
                reason:
                    '${entry.key}의 title이 30자 초과: "${message.title}" (${message.title.length}자)',
              );
            }
          }
        });

        test('Mock Random으로 결정론적 메시지 선택을 확인해야 한다', () {
          NotificationMessages.setRandom(MockRandom());
          final first = NotificationMessages.getCognitivePatternMessage('흑백사고');

          NotificationMessages.setRandom(MockRandom());
          final second = NotificationMessages.getCognitivePatternMessage(
            '흑백사고',
          );

          expect(first, isNotNull);
          expect(second, isNotNull);
          expect(first!.title, equals(second!.title));
          expect(first.body, equals(second.body));
        });

        test('supportedCognitivePatterns가 현재 지원 패턴 목록을 반환해야 한다', () {
          final patterns = NotificationMessages.supportedCognitivePatterns;
          expect(patterns, contains('흑백사고'));
          expect(patterns, contains('과일반화'));
          expect(patterns, contains('감정적추론'));
          expect(patterns, contains('당위적사고'));
          expect(patterns.length, equals(4));
        });

        test('cognitivePatternMessages 맵이 불변이어야 한다', () {
          final messages = NotificationMessages.cognitivePatternMessages;
          expect(() => messages['새로운_패턴'] = [], throwsUnsupportedError);
        });
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
            reason:
                '$level 레벨에서 다양한 메시지가 선택되어야 함 '
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
