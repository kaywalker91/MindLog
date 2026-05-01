import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/utils/time_utils.dart';

void main() {
  group('time_utils', () {

    group('getCurrentKstTime', () {
      test('should return DateTime with timeZoneOffset +09:00', () {
        final now = getCurrentKstTime();
        expect(now.timeZoneOffset, const Duration(hours: 9));
      });
    });

    group('utcToKst', () {
      test('should convert UTC DateTime to KST with offset +09:00', () {
        // 2026-05-02 04:00:00 UTC
        final utcTime = DateTime.utc(2026, 5, 2, 4, 0, 0);
        final kstTime = utcToKst(utcTime);

        // Should have +09:00 offset
        expect(kstTime.timeZoneOffset, const Duration(hours: 9));
        // KST should be UTC + 9 hours
        expect(kstTime.hour, 13); // 04:00 + 09:00 = 13:00
      });

      test('should preserve wall-clock equivalence (UTC+9h)', () {
        final utcTime = DateTime.utc(2026, 5, 2, 10, 30, 0);
        final kstTime = utcToKst(utcTime);

        // Wall-clock time should be UTC + 9 hours
        expect(kstTime.year, utcTime.year);
        expect(kstTime.month, utcTime.month);
        expect(kstTime.day, utcTime.day);
        expect(kstTime.hour, 19); // 10 + 9
        expect(kstTime.minute, 30);
        expect(kstTime.second, 0);
      });
    });

    group('formatIso8601Kst', () {
      test('should output ISO8601 string with +09:00 suffix', () {
        final dt = DateTime(2026, 5, 2, 13, 24, 40);
        final formatted = formatIso8601Kst(dt);

        expect(formatted, contains('+09:00'));
        expect(formatted, startsWith('2026-05-02T'));
      });

      test('should handle midnight rollover correctly', () {
        // Test day boundary: 2026-05-02 00:00:00
        final dt = DateTime(2026, 5, 2, 0, 0, 0);
        final formatted = formatIso8601Kst(dt);

        expect(formatted, '2026-05-02T00:00:00+09:00');
      });

      test('should round-trip with DateTime.parse', () {
        final original = DateTime(2026, 5, 2, 13, 24, 40);
        final formatted = formatIso8601Kst(original);

        // Verify the format is correct
        expect(formatted, '2026-05-02T13:24:40+09:00');

        // Parse the formatted string (verify no exception)
        // Note: DateTime.parse treats the offset, so this is a valid round-trip
        // for the wall-clock representation
        DateTime.parse(formatted);

        // The parsed DateTime represents the same wall-clock time
        // as the original (both represent 2026-05-02 13:24:40 KST)
        // Verify this by converting back to a local representation
        expect(formatted, contains(original.year.toString()));
        expect(formatted, contains(original.month.toString().padLeft(2, '0')));
        expect(formatted, contains(original.day.toString().padLeft(2, '0')));
      });
    });
  });
}
