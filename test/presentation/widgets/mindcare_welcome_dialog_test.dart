import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindlog/presentation/widgets/mindcare_welcome_dialog.dart';

void main() {
  group('MindcareWelcomeDialog', () {
    testWidgets('renders correctly with all UI elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MindcareWelcomeDialog())),
      );

      // 제목 확인
      expect(find.text('마음 케어 알림 시작!'), findsOneWidget);

      // 아이콘 확인 (저녁 달 아이콘)
      expect(find.byIcon(Icons.nightlight_round), findsOneWidget);

      // 정보 텍스트 확인
      expect(find.text('매일 저녁 9시, 하루 마무리 메시지가 도착해요'), findsOneWidget);

      // 샘플 메시지 확인
      expect(find.text('"오늘 하루는 어떠셨나요? 마음을 돌아봐요"'), findsOneWidget);

      // 시작하기 버튼 확인
      expect(find.text('시작하기'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('show() method displays dialog correctly', (tester) async {
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
      expect(find.byType(AlertDialog), findsNothing);

      // 버튼 탭하여 다이얼로그 표시
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 다이얼로그 표시 확인
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('마음 케어 알림 시작!'), findsOneWidget);
    });

    testWidgets('dialog closes when 시작하기 button is tapped', (tester) async {
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
      expect(find.byType(AlertDialog), findsOneWidget);

      // 시작하기 버튼 탭
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      // 다이얼로그 닫힘 확인
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('has correct visual elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MindcareWelcomeDialog())),
      );

      // 저녁 아이콘 확인 (정보 행 1)
      expect(find.byIcon(Icons.nightlight_outlined), findsOneWidget);

      // 하트 아이콘 확인 (정보 행 2: 감정 기반 맞춤 메시지)
      expect(find.byIcon(Icons.favorite_outlined), findsOneWidget);

      // 메일 아이콘 확인 (샘플 메시지)
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);

      // 감정 기반 맞춤 메시지 텍스트 확인
      expect(
        find.text('내 감정 상태에 따라 맞춤 메시지를 보내드려요'),
        findsOneWidget,
      );
    });

    testWidgets('has rounded border radius', (tester) async {
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

      // AlertDialog 찾기
      final alertDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));

      // shape이 RoundedRectangleBorder인지 확인
      expect(alertDialog.shape, isA<RoundedRectangleBorder>());

      final shape = alertDialog.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: MindcareWelcomeDialog()),
        ),
      );

      // 기본 요소 확인 (다크 모드에서도 동일하게 렌더링)
      expect(find.text('마음 케어 알림 시작!'), findsOneWidget);
      expect(find.text('매일 저녁 9시, 하루 마무리 메시지가 도착해요'), findsOneWidget);
      expect(find.text('시작하기'), findsOneWidget);
    });
  });
}
