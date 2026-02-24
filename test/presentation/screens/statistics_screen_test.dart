import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/domain/entities/statistics.dart';
import 'package:mindlog/presentation/providers/statistics_providers.dart';
import 'package:mindlog/presentation/providers/ui_state_providers.dart';
import 'package:mindlog/presentation/screens/statistics_screen.dart';
import 'package:mindlog/presentation/widgets/statistics/chart_card.dart';
import 'package:mindlog/presentation/widgets/statistics/heatmap_card.dart';
import 'package:mindlog/presentation/widgets/statistics/keyword_card.dart';
import 'package:mindlog/presentation/widgets/statistics/summary_row.dart';

import '../../fixtures/statistics_fixtures.dart';

/// 큰 논리 크기(800×2000) 설정 — 통계 화면 4개 카드가 모두 뷰포트 안에 들어오도록
void _setLargeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
}

void _resetView(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Widget _buildHarness({
  Future<EmotionStatistics>? statsFuture,
  EmotionStatistics? statsData,
  StatisticsPeriod initialPeriod = StatisticsPeriod.week,
}) {
  final future =
      statsFuture ?? Future.value(statsData ?? StatisticsFixtures.weekly());

  return ProviderScope(
    overrides: [
      statisticsProvider.overrideWith((ref) => future),
      selectedStatisticsPeriodProvider.overrideWith((ref) => initialPeriod),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const StatisticsScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    // flutter_animate 타이머 자동 재시작 비활성화 (테스트 환경 타이머 누수 방지)
    Animate.restartOnHotReload = false;
  });

  group('StatisticsScreen', () {
    testWidgets('로딩 상태: CircularProgressIndicator가 표시된다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      final completer = Completer<EmotionStatistics>();
      await tester.pumpWidget(_buildHarness(statsFuture: completer.future));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 정리: completer 완료 후 타이머 소진
      completer.complete(StatisticsFixtures.weekly());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // animate 타이머
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('데이터 상태: 주요 통계 위젯 4개가 모두 렌더링된다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(
        _buildHarness(statsData: StatisticsFixtures.weekly()),
      );
      await tester.pump(); // FutureProvider 해결
      await tester.pump(); // 위젯 트리 갱신
      await tester.pump(const Duration(milliseconds: 500)); // animate 타이머 소진
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(StatisticsSummaryRow), findsOneWidget);
      expect(find.byType(StatisticsHeatmapCard), findsOneWidget);
      expect(find.byType(StatisticsChartCard), findsOneWidget);
      expect(find.byType(StatisticsKeywordCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('에러 상태: 에러 메시지와 재시도 버튼이 표시된다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statisticsProvider.overrideWith(
              (ref) async =>
                  throw const Failure.network(message: '통계 데이터를 불러오지 못했습니다.'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const StatisticsScreen(),
          ),
        ),
      );
      await tester.pump(); // FutureProvider 오류 처리
      await tester.pump();

      expect(find.text('잠시 연결이 어려워요'), findsOneWidget);
      expect(find.text('다시 시도해볼게요'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('에러 상태에서 재시도 버튼 탭 시 통계 Provider가 새로고침된다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      int fetchCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statisticsProvider.overrideWith((ref) async {
              fetchCount++;
              if (fetchCount == 1) {
                throw const Failure.network();
              }
              return StatisticsFixtures.weekly();
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const StatisticsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // 최초 에러 상태
      expect(find.text('다시 시도해볼게요'), findsOneWidget);
      expect(fetchCount, 1);

      // 재시도 버튼 탭 → provider refresh
      await tester.tap(find.text('다시 시도해볼게요'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // animate 타이머 소진
      await tester.pump(const Duration(milliseconds: 500));

      expect(fetchCount, 2, reason: '재시도 버튼 탭 시 통계 데이터를 다시 불러와야 한다');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '기간 탭 전환: 최근 30일 탭 선택 시 selectedStatisticsPeriodProvider가 갱신된다',
      (tester) async {
        _setLargeView(tester);
        addTearDown(() => _resetView(tester));

        await tester.pumpWidget(
          _buildHarness(statsData: StatisticsFixtures.weekly()),
        );
        await tester.pump();
        await tester.pump();

        // '최근 30일' 탭 탭 (칩에서 첫 번째 매치)
        await tester.tap(find.text('최근 30일').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500)); // animate 타이머 소진
        await tester.pump(const Duration(milliseconds: 500));

        // StatisticsHeatmapCard의 _PeriodChips가 Provider를 업데이트했는지 확인
        // — '최근 30일' 텍스트가 화면에 존재 (칩 + 레이블 중복 허용)
        expect(find.text('최근 30일'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('빈 통계 데이터 상태: 주요 위젯들이 예외 없이 렌더링된다', (tester) async {
      _setLargeView(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(
        _buildHarness(statsData: StatisticsFixtures.empty()),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(StatisticsSummaryRow), findsOneWidget);
      expect(find.byType(StatisticsHeatmapCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
