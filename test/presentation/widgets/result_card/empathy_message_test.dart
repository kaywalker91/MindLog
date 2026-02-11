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
    testWidgets('긴 메시지에서 기본 4줄 축약과 전체보기 토글이 보여야 한다', (tester) async {
      await tester.pumpWidget(buildTestWidget(longMessage));
      await tester.pumpAndSettle();

      expect(find.text('전체보기'), findsOneWidget);

      final crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showFirst);

      final collapsedText = tester
          .widgetList<Text>(find.byType(Text))
          .where((text) => text.data == longMessage && text.maxLines == 4);
      expect(collapsedText, isNotEmpty);
    });

    testWidgets('전체보기/접기 토글로 확장과 축약을 전환할 수 있어야 한다', (tester) async {
      await tester.pumpWidget(buildTestWidget(longMessage));
      await tester.pumpAndSettle();

      await tester.tap(find.text('전체보기'));
      await tester.pumpAndSettle();

      expect(find.text('접기'), findsOneWidget);
      expect(find.text('전체보기'), findsNothing);
      expect(
        tester
            .widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
            .crossFadeState,
        CrossFadeState.showSecond,
      );

      await tester.tap(find.text('접기'));
      await tester.pumpAndSettle();

      expect(find.text('전체보기'), findsOneWidget);
      expect(find.text('접기'), findsNothing);
      expect(
        tester
            .widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
            .crossFadeState,
        CrossFadeState.showFirst,
      );
    });

    testWidgets('짧은 메시지에서는 전체보기/접기 토글이 없어야 한다', (tester) async {
      await tester.pumpWidget(buildTestWidget(shortMessage));
      await tester.pumpAndSettle();

      expect(find.text('전체보기'), findsNothing);
      expect(find.text('접기'), findsNothing);
    });
  });
}
