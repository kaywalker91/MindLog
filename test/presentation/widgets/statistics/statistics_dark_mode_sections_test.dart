import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/statistics.dart';
import 'package:mindlog/presentation/widgets/emotion_line_chart.dart';
import 'package:mindlog/presentation/widgets/keyword_tags/keyword_tags.dart';
import 'package:mindlog/presentation/widgets/statistics/chart_card.dart';
import 'package:mindlog/presentation/widgets/statistics/keyword_card.dart';

import '../../../fixtures/statistics_fixtures.dart';

void main() {
  setUpAll(() {
    Animate.restartOnHotReload = false;
  });

  group('Statistics dark mode sections', () {
    testWidgets('감정 추이 카드가 시맨틱 색상을 사용해야 한다', (tester) async {
      final statistics = StatisticsFixtures.weekly();
      final colorScheme = await _pumpWithTheme(
        tester,
        StatisticsChartCard(
          statistics: statistics,
          selectedPeriod: StatisticsPeriod.week,
        ),
        brightness: Brightness.dark,
      );

      final cardContainer = tester.widget<Container>(
        find
            .ancestor(of: find.text('감정 추이'), matching: find.byType(Container))
            .first,
      );
      final cardDecoration = cardContainer.decoration! as BoxDecoration;
      final cardBorder = cardDecoration.border! as Border;

      expect(cardDecoration.color, colorScheme.surfaceContainerLow);
      expect(cardBorder.top.color, colorScheme.outlineVariant);

      final title = tester.widget<Text>(find.text('감정 추이'));
      final subtitle = tester.widget<Text>(find.text('최근 7일'));

      expect(title.style?.color, colorScheme.onSurface);
      expect(subtitle.style?.color, colorScheme.onSurfaceVariant);
    });

    testWidgets('감정 추이 라인차트가 다크모드 시맨틱 색상을 사용해야 한다', (tester) async {
      final colorScheme = await _pumpWithTheme(
        tester,
        EmotionLineChart(
          dailyEmotions: [
            DailyEmotion(
              date: DateTime(2026, 2, 18),
              averageScore: 6,
              diaryCount: 1,
            ),
            DailyEmotion(
              date: DateTime(2026, 2, 19),
              averageScore: 7,
              diaryCount: 1,
            ),
          ],
          period: StatisticsPeriod.week,
        ),
        brightness: Brightness.dark,
      );

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final line = chart.data.lineBarsData.single;
      final dotPainter =
          line.dotData.getDotPainter(line.spots.first, 1.0, line, 0)
              as FlDotCirclePainter;
      final tooltipColor =
          chart.data.lineTouchData.touchTooltipData.getTooltipColor;
      final tooltipItems =
          chart.data.lineTouchData.touchTooltipData.getTooltipItems;
      final lineBarSpot = LineBarSpot(line, 0, line.spots.first);
      final tooltipItem = tooltipItems([lineBarSpot]).first;

      expect(line.color, colorScheme.primary);
      expect(dotPainter.color, colorScheme.primary);
      expect(dotPainter.strokeColor, colorScheme.surface);
      expect(tooltipColor(lineBarSpot), colorScheme.inverseSurface);
      expect(tooltipItem?.textStyle.color, colorScheme.onInverseSurface);
    });

    testWidgets('감정 추이 빈 상태는 onSurfaceVariant 계열로 표시되어야 한다', (tester) async {
      final colorScheme = await _pumpWithTheme(
        tester,
        const EmotionLineChart(
          dailyEmotions: [],
          period: StatisticsPeriod.week,
        ),
        brightness: Brightness.dark,
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.show_chart));
      final emptyTitle = tester.widget<Text>(find.text('아직 분석된 일기가 없어요'));
      final emptyBody = tester.widget<Text>(
        find.text('일기를 작성하면 감정 추이를 볼 수 있어요'),
      );

      expect(icon.color, colorScheme.onSurfaceVariant);
      expect(emptyTitle.style?.color, colorScheme.onSurfaceVariant);
      expect(
        emptyBody.style?.color,
        colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
      );
    });

    testWidgets('자주 느낀 감정 카드가 시맨틱 색상을 사용해야 한다', (tester) async {
      const statistics = EmotionStatistics(
        dailyEmotions: [],
        keywordFrequency: {'자제': 1},
        activityMap: {},
        totalDiaries: 1,
        overallAverageScore: 6,
      );
      final colorScheme = await _pumpWithTheme(
        tester,
        const StatisticsKeywordCard(
          statistics: statistics,
          selectedPeriod: StatisticsPeriod.week,
        ),
        brightness: Brightness.dark,
      );

      final cardContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('자주 느낀 감정'),
              matching: find.byType(Container),
            )
            .first,
      );
      final cardDecoration = cardContainer.decoration! as BoxDecoration;
      final cardBorder = cardDecoration.border! as Border;

      expect(cardDecoration.color, colorScheme.surfaceContainerLow);
      expect(cardBorder.top.color, colorScheme.outlineVariant);

      final title = tester.widget<Text>(find.text('자주 느낀 감정'));
      final subtitle = tester.widget<Text>(find.text('최근 7일 감정 패턴 요약'));

      expect(title.style?.color, colorScheme.onSurface);
      expect(subtitle.style?.color, colorScheme.onSurfaceVariant);
    });

    testWidgets('키워드 섹션이 다크모드에서 시맨틱 텍스트/배지 색상을 사용해야 한다', (tester) async {
      final colorScheme = await _pumpWithTheme(
        tester,
        const KeywordTags(keywordFrequency: {'자제': 2, '생활습관': 1, '건강': 1}),
        brightness: Brightness.dark,
      );

      final sectionTitle = tester.widget<Text>(find.text('다음으로 많이 느낀 감정'));
      final topPercent = tester.widget<Text>(find.text('50%'));
      final rankBadge = tester.widget<Text>(find.text('#2'));
      final rankKeyword = tester.widget<Text>(find.text('생활습관'));

      expect(sectionTitle.style?.color, colorScheme.onSurfaceVariant);
      expect(topPercent.style?.color, colorScheme.onPrimary);
      expect(rankBadge.style?.color, colorScheme.onPrimaryContainer);
      expect(rankKeyword.style?.color, colorScheme.onSurface);
    });

    testWidgets('라이트모드에서도 배지 포인트 색상이 primary를 유지해야 한다', (tester) async {
      final colorScheme = await _pumpWithTheme(
        tester,
        const KeywordTags(keywordFrequency: {'자제': 2, '생활습관': 1, '건강': 1}),
        brightness: Brightness.light,
      );

      final percentText = find.text('50%');
      final percentContainer = tester.widget<Container>(
        find.ancestor(of: percentText, matching: find.byType(Container)).first,
      );
      final percentDecoration = percentContainer.decoration! as BoxDecoration;
      final percentWidget = tester.widget<Text>(percentText);

      expect(percentDecoration.color, colorScheme.primary);
      expect(percentWidget.style?.color, colorScheme.onPrimary);
    });

    testWidgets('긴 키워드가 있어도 overflow 예외 없이 렌더링되어야 한다', (tester) async {
      await _pumpWithTheme(
        tester,
        const KeywordTags(
          keywordFrequency: {
            '아주아주길게반복되는감정키워드테스트용문자열아주아주길게반복되는감정키워드': 3,
            '짧은키워드': 1,
          },
        ),
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
    });
  });
}

Future<ColorScheme> _pumpWithTheme(
  WidgetTester tester,
  Widget child, {
  required Brightness brightness,
}) async {
  late ColorScheme capturedColorScheme;

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7EC8E3),
          brightness: brightness,
        ),
      ),
      home: Builder(
        builder: (context) {
          capturedColorScheme = Theme.of(context).colorScheme;
          return Scaffold(body: child);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return capturedColorScheme;
}
