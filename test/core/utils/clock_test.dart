import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/utils/clock.dart';

void main() {
  group('SystemClock', () {
    test('now()는 현재 시간을 반환해야 한다', () {
      const clock = SystemClock();
      final before = DateTime.now();
      final now = clock.now();
      final after = DateTime.now();

      expect(now.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(now.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('FixedClock', () {
    test('항상 고정된 시간을 반환해야 한다', () {
      final fixedTime = DateTime(2024, 6, 15, 14, 30);
      final clock = FixedClock(fixedTime);

      expect(clock.now(), fixedTime);
      expect(clock.now(), fixedTime); // 두 번 호출해도 동일
    });

    test('nowUtc()는 UTC로 변환된 시간을 반환해야 한다', () {
      final fixedTime = DateTime(2024, 6, 15, 14, 30);
      final clock = FixedClock(fixedTime);

      expect(clock.nowUtc(), fixedTime.toUtc());
    });
  });

  group('AdjustableClock', () {
    test('초기 시간을 설정할 수 있어야 한다', () {
      final initialTime = DateTime(2024, 1, 1, 10, 0);
      final clock = AdjustableClock(initialTime);

      expect(clock.now(), initialTime);
    });

    test('setTime()으로 시간을 변경할 수 있어야 한다', () {
      final clock = AdjustableClock(DateTime(2024, 1, 1));
      final newTime = DateTime(2024, 6, 15, 14, 30);

      clock.setTime(newTime);

      expect(clock.now(), newTime);
    });

    test('advance()로 시간을 진행시킬 수 있어야 한다', () {
      final initialTime = DateTime(2024, 1, 1, 10, 0);
      final clock = AdjustableClock(initialTime);

      clock.advance(const Duration(hours: 2, minutes: 30));

      expect(clock.now(), DateTime(2024, 1, 1, 12, 30));
    });

    test('rewind()로 시간을 되돌릴 수 있어야 한다', () {
      final initialTime = DateTime(2024, 1, 1, 10, 0);
      final clock = AdjustableClock(initialTime);

      clock.rewind(const Duration(hours: 1));

      expect(clock.now(), DateTime(2024, 1, 1, 9, 0));
    });

    test('연속적인 advance/rewind가 정확하게 동작해야 한다', () {
      final clock = AdjustableClock(DateTime(2024, 1, 1, 12, 0));

      clock.advance(const Duration(days: 1));
      expect(clock.now(), DateTime(2024, 1, 2, 12, 0));

      clock.advance(const Duration(hours: 5));
      expect(clock.now(), DateTime(2024, 1, 2, 17, 0));

      clock.rewind(const Duration(days: 2));
      expect(clock.now(), DateTime(2023, 12, 31, 17, 0));
    });
  });
}
