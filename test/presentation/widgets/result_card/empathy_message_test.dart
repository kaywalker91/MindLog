import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/result_card/empathy_message.dart';

void main() {
  setUpAll(() {
    Animate.restartOnHotReload = false;
  });

  Widget buildTestWidget(String message) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: 280, child: EmpathyMessage(message: message)),
        ),
      ),
    );
  }

  const longMessage =
      '이직 준비는 항상 힘든 과정이죠. 하지만 오늘도 잘 해내신 것 같아요. '
      '마음을 편하게 해주시고, 스스로에게 믿음을 주세요. '
      '하루의 작은 진전도 분명 의미가 있습니다. 충분히 잘하고 계세요.';
  const shortMessage = '오늘도 수고하셨어요.';

  group('EmpathyMessage', () {
    testWidgets('긴 메시지도 잘림 없이 전체 표시되어야 한다', (tester) async {
      await tester.pumpWidget(buildTestWidget(longMessage));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('전체보기'), findsNothing);
      expect(find.text('접기'), findsNothing);

      final textWidgets = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.data == longMessage);
      expect(textWidgets, isNotEmpty);

      final displayedText = textWidgets.first;
      expect(displayedText.maxLines, isNull);
      expect(displayedText.overflow, isNull);
    });

    testWidgets('짧은 메시지도 잘림 없이 전체 표시되어야 한다', (tester) async {
      await tester.pumpWidget(buildTestWidget(shortMessage));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('전체보기'), findsNothing);
      expect(find.text('접기'), findsNothing);
      expect(find.text(shortMessage), findsOneWidget);
    });

    testWidgets('인용문 아이콘이 표시되어야 한다', (tester) async {
      await tester.pumpWidget(buildTestWidget(shortMessage));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);
    });
  });
}
