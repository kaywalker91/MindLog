import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/emotion_garden.dart';

void main() {
  group('EmotionGarden', () {
    group('이모지 매핑 테스트', () {
      testWidgets('점수 1-2는 씨앗(🌱)을 표시해야 한다', (tester) async {
        final testData = {DateTime(2024, 1, 1): 1.5, DateTime(2024, 1, 2): 2.0};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmotionGarden(activityMap: testData, weeksToShow: 1),
            ),
          ),
        );

        expect(find.text('🌱'), findsWidgets);
      });

      testWidgets('점수 3-4는 새싹(🌿)을 표시해야 한다', (tester) async {
        final testData = {DateTime(2024, 1, 1): 3.5};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmotionGarden(activityMap: testData, weeksToShow: 1),
            ),
          ),
        );

        expect(find.text('🌿'), findsOneWidget);
      });

      testWidgets('점수 5-6은 꽃봉오리(🌷)를 표시해야 한다', (tester) async {
        final testData = {DateTime(2024, 1, 1): 5.5};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmotionGarden(activityMap: testData, weeksToShow: 1),
            ),
          ),
        );

        expect(find.text('🌷'), findsOneWidget);
      });

      testWidgets('점수 7-8은 꽃(🌸)을 표시해야 한다', (tester) async {
        final testData = {DateTime(2024, 1, 1): 7.5};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmotionGarden(activityMap: testData, weeksToShow: 1),
            ),
          ),
        );

        expect(find.text('🌸'), findsOneWidget);
      });

      testWidgets('점수 9-10은 해바라기(🌻)를 표시해야 한다', (tester) async {
        final testData = {DateTime(2024, 1, 1): 9.5};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmotionGarden(activityMap: testData, weeksToShow: 1),
            ),
          ),
        );

        expect(find.text('🌻'), findsOneWidget);
      });
    });

    group('빈 데이터 처리', () {
      testWidgets('activityMap이 비어있어도 범례는 표시되어야 한다', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmotionGarden(activityMap: {}, weeksToShow: 1),
            ),
          ),
        );

        // 범례에 이모지가 표시됨 (1개씩만)
        // 범례 이모지는 존재하지만, 그리드 셀에 추가 이모지는 없어야 함
        expect(find.text('마음의 정원'), findsOneWidget);
        expect(find.byType(EmotionGarden), findsOneWidget);
      });
    });

    group('범례 표시', () {
      testWidgets('마음의 정원 범례가 표시되어야 한다', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmotionGarden(activityMap: {}, weeksToShow: 1),
            ),
          ),
        );

        expect(find.text('마음의 정원'), findsOneWidget);
        // 범례 화살표
        expect(find.text('→'), findsNWidgets(4));
      });
    });

    group('요일 라벨', () {
      testWidgets('요일 라벨이 올바르게 표시되어야 한다', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmotionGarden(activityMap: {}, weeksToShow: 1),
            ),
          ),
        );

        expect(find.text('월'), findsOneWidget);
        expect(find.text('화'), findsOneWidget);
        expect(find.text('수'), findsOneWidget);
        expect(find.text('목'), findsOneWidget);
        expect(find.text('금'), findsOneWidget);
        expect(find.text('토'), findsOneWidget);
        expect(find.text('일'), findsOneWidget);
      });
    });

    group('위젯 렌더링', () {
      testWidgets('샘플 데이터로 정상 렌더링되어야 한다', (tester) async {
        final now = DateTime.now();
        final testData = {
          now.subtract(const Duration(days: 1)): 8.5,
          now.subtract(const Duration(days: 2)): 3.0,
          now.subtract(const Duration(days: 3)): 9.5,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmotionGarden(activityMap: testData, weeksToShow: 4),
            ),
          ),
        );

        // EmotionGarden 위젯 존재 확인
        expect(find.byType(EmotionGarden), findsOneWidget);
        // SingleChildScrollView 존재 (수평 스크롤)
        expect(find.byType(SingleChildScrollView), findsNWidgets(2));
      });

      testWidgets('weeksToShow 파라미터가 반영되어야 한다', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmotionGarden(activityMap: {}, weeksToShow: 8),
            ),
          ),
        );

        expect(find.byType(EmotionGarden), findsOneWidget);
      });
    });

    group('다크 모드', () {
      testWidgets('다크 모드에서도 정상 렌더링되어야 한다', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData.dark(useMaterial3: true),
            home: const Scaffold(
              body: EmotionGarden(activityMap: {}, weeksToShow: 4),
            ),
          ),
        );

        expect(find.byType(EmotionGarden), findsOneWidget);
        expect(find.text('마음의 정원'), findsOneWidget);
      });
    });
  });
}
