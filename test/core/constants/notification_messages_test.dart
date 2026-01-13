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
  });
}
