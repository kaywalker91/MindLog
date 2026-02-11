import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/presentation/widgets/result_card/emotion_insight_card.dart';

void main() {
  setUpAll(() {
    Animate.restartOnHotReload = false;
  });

  Widget buildTestWidget(AnalysisResult result) {
    return MaterialApp(
      home: Scaffold(body: EmotionInsightCard(result: result)),
    );
  }

  AnalysisResult buildResult({
    EmotionCategory? category,
    EmotionTrigger? trigger,
  }) {
    return AnalysisResult(
      analyzedAt: DateTime(2026, 2, 11),
      emotionCategory: category,
      emotionTrigger: trigger,
      empathyMessage: '테스트 메시지',
    );
  }

  group('EmotionInsightCard', () {
    testWidgets('감정 분류/원인 정보를 표시하고 자세히 보기를 표시하지 않아야 한다', (tester) async {
      final result = buildResult(
        category: const EmotionCategory(primary: '기쁨', secondary: '안도'),
        trigger: const EmotionTrigger(
          category: '일/업무',
          description: '이직 준비의 불확실성과 기대',
        ),
      );

      await tester.pumpWidget(buildTestWidget(result));
      await tester.pumpAndSettle();

      expect(find.text('감정 분류'), findsOneWidget);
      expect(find.text('기쁨 → 안도'), findsOneWidget);
      expect(find.text('감정 원인 · 일/업무'), findsOneWidget);
      expect(find.text('이직 준비의 불확실성과 기대'), findsOneWidget);
      expect(find.text('자세히 보기'), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('감정 분류와 원인이 없으면 아무것도 렌더링하지 않아야 한다', (tester) async {
      final result = buildResult();

      await tester.pumpWidget(buildTestWidget(result));
      await tester.pumpAndSettle();

      expect(find.text('감정 분류'), findsNothing);
      expect(find.textContaining('감정 원인'), findsNothing);
      expect(find.text('자세히 보기'), findsNothing);
    });
  });
}
