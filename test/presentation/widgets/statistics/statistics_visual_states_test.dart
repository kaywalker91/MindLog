import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/core/theme/statistics_theme_tokens.dart';
import 'package:mindlog/domain/entities/statistics.dart';
import 'package:mindlog/presentation/widgets/emotion_calendar/day_cell.dart';
import 'package:mindlog/presentation/widgets/statistics/heatmap_card.dart';

void main() {
  group('Statistics visual states', () {
    testWidgets('기간 칩 선택/비선택 색상이 토큰과 일치해야 한다', (tester) async {
      const selectedPeriod = StatisticsPeriod.week;
      final stats = EmotionStatistics.empty();
      late StatisticsThemeTokens tokens;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) {
                tokens = StatisticsThemeTokens.of(context);
                return Scaffold(
                  body: StatisticsHeatmapCard(
                    statistics: stats,
                    selectedPeriod: selectedPeriod,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selectedChip = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('최근 7일'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final unselectedChip = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('최근 30일'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final selectedChipDecoration = selectedChip.decoration! as BoxDecoration;
      final unselectedChipDecoration =
          unselectedChip.decoration! as BoxDecoration;

      expect(selectedChipDecoration.color, tokens.chipSelectedBackground);
      expect(unselectedChipDecoration.color, tokens.chipUnselectedBackground);
    });

    testWidgets('오늘 셀은 은은한 배경 + 강조 테두리를 사용해야 한다', (tester) async {
      final now = DateTime.now();
      late StatisticsThemeTokens tokens;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              tokens = StatisticsThemeTokens.of(context);
              return Scaffold(
                body: DayCell(
                  date: DateTime(now.year, now.month, now.day),
                  score: null,
                  isCurrentMonth: true,
                  isToday: true,
                  isFuture: false,
                  onTap: null,
                  tooltipFormatter: DateFormat('yyyy년 M월 d일'),
                  emojiSize: 16,
                  dateFontSize: 12,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final decoration = _findBoxDecoration(
        tester,
        (box) =>
            box.border is Border && (box.border! as Border).top.width == 1.8,
      );
      final border = decoration.border! as Border;

      expect(decoration.color, tokens.calendarTodayBackground);
      expect(border.top.color, tokens.calendarTodayBorder);
    });
  });
}

BoxDecoration _findBoxDecoration(
  WidgetTester tester,
  bool Function(BoxDecoration box) predicate,
) {
  for (final container in tester.widgetList<Container>(
    find.byType(Container),
  )) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration && predicate(decoration)) {
      return decoration;
    }
  }
  throw TestFailure('조건에 맞는 BoxDecoration을 찾지 못했습니다.');
}
