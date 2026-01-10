import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/mindcare_welcome_dialog.dart';

void main() {
  group('MindcareWelcomeDialog', () {
    testWidgets('renders correctly with all UI elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MindcareWelcomeDialog(),
          ),
        ),
      );

      // 제목 확인
      expect(find.text('마음 케어 알림 시작!'), findsOneWidget);

      // 아이콘 확인 (하트 아이콘)
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // 정보 텍스트 확인
      expect(find.text('매일 아침 따뜻한 메시지가 도착해요'), findsOneWidget);

      // 샘플 메시지 확인
      expect(find.text('"오늘도 당신은 충분히 잘하고 있어요"'), findsOneWidget);

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
        const MaterialApp(
          home: Scaffold(
            body: MindcareWelcomeDialog(),
          ),
        ),
      );

      // 해 아이콘 확인 (정보 행)
      expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);

      // 메일 아이콘 확인 (샘플 메시지)
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
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
          home: const Scaffold(
            body: MindcareWelcomeDialog(),
          ),
        ),
      );

      // 기본 요소 확인 (다크 모드에서도 동일하게 렌더링)
      expect(find.text('마음 케어 알림 시작!'), findsOneWidget);
      expect(find.text('매일 아침 따뜻한 메시지가 도착해요'), findsOneWidget);
      expect(find.text('시작하기'), findsOneWidget);
    });
  });
}
