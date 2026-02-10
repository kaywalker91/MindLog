import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/weekly_insight_guide_dialog.dart';

void main() {
  group('WeeklyInsightGuideDialog', () {
    testWidgets('renders correctly with required content', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WeeklyInsightGuideDialog())),
      );

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('주간 감정 리포트 받기'), findsOneWidget);
      expect(find.text('한 주의 감정 흐름을 한눈에 정리해드려요'), findsOneWidget);
      expect(find.text('이번 주 인사이트 한눈에'), findsOneWidget);
      expect(find.text('언제  '), findsOneWidget);
      expect(find.text('매주 일요일 밤 8시'), findsOneWidget);
      expect(find.text('무엇  '), findsOneWidget);
      expect(find.text('최근 7일 감정 흐름 요약'), findsOneWidget);
      expect(find.text('어디서  '), findsOneWidget);
      expect(find.text('통계 탭에서 바로 확인'), findsOneWidget);
      expect(find.text('매주 일요일 밤 8시, 요약 알림이 도착해요'), findsOneWidget);
      expect(find.text('최근 7일 평균 감정·연속 기록·핵심 키워드를 확인해요'), findsOneWidget);
      expect(find.text('알림을 탭하면 통계 탭으로 바로 이동해요'), findsOneWidget);
      expect(find.text('나중에'), findsOneWidget);
      expect(find.text('통계 보기'), findsOneWidget);
    });

    testWidgets('title keeps single-line policy', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WeeklyInsightGuideDialog())),
      );

      final titleWidget = tester.widget<Text>(find.text('주간 감정 리포트 받기'));
      expect(titleWidget.maxLines, 1);
      expect(titleWidget.softWrap, false);
      expect(titleWidget.overflow, TextOverflow.fade);
    });

    testWidgets('show() returns later when 나중에 is tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      WeeklyInsightGuideResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await WeeklyInsightGuideDialog.show(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('나중에'));
      await tester.pumpAndSettle();

      expect(result, WeeklyInsightGuideResult.later);
    });

    testWidgets('show() returns viewStats when 통계 보기 is tapped', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      WeeklyInsightGuideResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await WeeklyInsightGuideDialog.show(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('통계 보기'));
      await tester.pumpAndSettle();

      expect(result, WeeklyInsightGuideResult.viewStats);
    });

    testWidgets('has rounded border radius', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WeeklyInsightGuideDialog())),
      );

      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.shape, isA<RoundedRectangleBorder>());
      final shape = dialog.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: WeeklyInsightGuideDialog()),
        ),
      );

      expect(find.text('주간 감정 리포트 받기'), findsOneWidget);
      expect(find.text('통계 보기'), findsOneWidget);
    });

    testWidgets('renders without overflow on small viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WeeklyInsightGuideDialog())),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('remains readable at text scale 1.3x', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: const Scaffold(body: WeeklyInsightGuideDialog()),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('나중에'), findsOneWidget);
      expect(find.text('통계 보기'), findsOneWidget);
    });
  });
}
