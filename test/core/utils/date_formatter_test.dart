import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mindlog/core/utils/date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  // 2024-01-15 15:30 = 월요일 (요일/오전오후 로케일 검증용 고정값)
  final sample = DateTime(2024, 1, 15, 15, 30);

  group('DateFormatter 출력 골든 (호출부 실측 패턴 1:1)', () {
    test('formatDetailDateTime — diary_detail 패턴', () {
      // 'yyyy년 MM월 dd일 (E) a hh:mm', ko_KR
      expect(
        DateFormatter.formatDetailDateTime(sample),
        '2024년 01월 15일 (월) 오후 03:30',
      );
    });

    test('formatListDate — diary_item_card 패턴', () {
      // 'MM월 dd일 (E)', ko_KR
      expect(DateFormatter.formatListDate(sample), '01월 15일 (월)');
    });

    test('formatChartShort — emotion_line_chart 축 패턴', () {
      // 'M/d'
      expect(DateFormatter.formatChartShort(sample), '1/15');
    });

    test('formatChartTooltip — emotion_line_chart 툴팁 패턴', () {
      // 'M월 d일'
      expect(DateFormatter.formatChartTooltip(sample), '1월 15일');
    });

    test('formatDate — emotion_calendar 툴팁 패턴(yyyy년 M월 d일)과 동일', () {
      expect(DateFormatter.formatDate(sample), '2024년 1월 15일');
    });
  });

  group('formatRelativeWritten — message_card 패턴 (now 주입 결정론)', () {
    final now = DateTime(2024, 1, 20, 12, 0);

    test('당일(24시간 미만 차이)은 오늘 작성', () {
      expect(
        DateFormatter.formatRelativeWritten(
          DateTime(2024, 1, 20, 9, 0),
          now: now,
        ),
        '오늘 작성',
      );
    });

    test('하루 차이는 어제 작성', () {
      expect(
        DateFormatter.formatRelativeWritten(
          DateTime(2024, 1, 19, 9, 0),
          now: now,
        ),
        '어제 작성',
      );
    });

    test('7일 미만은 N일 전 작성', () {
      expect(
        DateFormatter.formatRelativeWritten(
          DateTime(2024, 1, 17, 12, 0),
          now: now,
        ),
        '3일 전 작성',
      );
    });

    test('7일 이상은 M월 d일 작성', () {
      expect(
        DateFormatter.formatRelativeWritten(
          DateTime(2024, 1, 1, 12, 0),
          now: now,
        ),
        '1월 1일 작성',
      );
    });
  });
}
