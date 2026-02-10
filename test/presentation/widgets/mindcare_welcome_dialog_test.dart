import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindlog/presentation/widgets/mindcare_welcome_dialog.dart';

void main() {
  group('MindcareWelcomeDialog', () {
    testWidgets('renders correctly with all UI elements', (tester) async {
      // 다이얼로그 콘텐츠가 기본 뷰포트보다 크므로 확장
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MindcareWelcomeDialog())),
      );

      // 제목 확인
      expect(find.text('마음케어를 시작해요'), findsOneWidget);

      // 부제 확인
      expect(find.text('검증된 심리학 기반 마음케어'), findsOneWidget);

      // 심리학 아이콘 확인 (헤더 + 정보 행에 각 1개 = 2개)
      expect(find.byIcon(Icons.psychology_outlined), findsNWidgets(2));

      // 정보 텍스트 확인
      expect(find.text('매일 밤 9시, 하루를 정리하는 메시지를 보내드려요'), findsOneWidget);
      expect(find.text('CBT·마인드풀니스 기반의 검증된 케어'), findsOneWidget);
      expect(find.text('오늘의 감정에 맞는 맞춤 메시지를 전해드려요'), findsOneWidget);

      // 샘플 메시지 확인
      expect(
        find.text('"잠시 멈추고 현재를 느껴보세요.\n지금 이 순간, 있는 그대로 충분해요"'),
        findsOneWidget,
      );

      // 시작하기 버튼 확인
      expect(find.text('시작하기'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('show() method displays dialog correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => MindcareWelcomeDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // 다이얼로그 표시 전 확인
      expect(find.byType(Dialog), findsNothing);

      // 버튼 탭하여 다이얼로그 표시
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 다이얼로그 표시 확인
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('마음케어를 시작해요'), findsOneWidget);
    });

    testWidgets('dialog closes when 시작하기 button is tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // go_router를 사용하는 위젯 테스트용 설정
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => MindcareWelcomeDialog.show(context),
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // 다이얼로그 표시
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 다이얼로그 확인
      expect(find.byType(Dialog), findsOneWidget);

      // 시작하기 버튼 탭
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      // 다이얼로그 닫힘 확인
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('has correct visual elements', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MindcareWelcomeDialog())),
      );

      // 시간 아이콘 확인 (정보 행 1)
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);

      // 심리학 아이콘 확인 (헤더 + 정보 행 2)
      expect(find.byIcon(Icons.psychology_outlined), findsNWidgets(2));

      // 하트 아이콘 확인 (정보 행 3: 감정 맞춤 메시지)
      expect(find.byIcon(Icons.favorite_outlined), findsOneWidget);

      // spa 아이콘 확인 (샘플 메시지)
      expect(find.byIcon(Icons.spa_outlined), findsOneWidget);

      // Cheer Me 비교 섹션 확인
      expect(find.text('Cheer Me와 무엇이 다른가요?'), findsOneWidget);
      expect(find.textContaining('Cheer Me: 내가 쓴 응원을 나에게 전해요.'), findsOneWidget);
      expect(find.textContaining('마음케어: 전문 심리 기법으로 마음을 돌봐요.'), findsOneWidget);
    });

    testWidgets('has rounded border radius', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => MindcareWelcomeDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // 다이얼로그 표시
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog 찾기
      final dialog = tester.widget<Dialog>(find.byType(Dialog));

      // shape이 RoundedRectangleBorder인지 확인
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
          home: const Scaffold(body: MindcareWelcomeDialog()),
        ),
      );

      // 기본 요소 확인 (다크 모드에서도 동일하게 렌더링)
      expect(find.text('마음케어를 시작해요'), findsOneWidget);
      expect(find.text('매일 밤 9시, 하루를 정리하는 메시지를 보내드려요'), findsOneWidget);
      expect(find.text('시작하기'), findsOneWidget);
    });

    testWidgets('renders without overflow on small viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MindcareWelcomeDialog())),
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
            child: const Scaffold(body: MindcareWelcomeDialog()),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('시작하기'), findsOneWidget);
    });
  });
}
