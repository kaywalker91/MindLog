import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/presentation/widgets/result_card/character_banner.dart';
import 'package:mindlog/presentation/widgets/result_card/sentiment_dashboard.dart';

/// Result Card 서브 위젯 테스트
///
/// flutter_animate 위젯은 타이머 이슈로 인해 테스트에서 제외됩니다.
/// 애니메이션이 없는 CharacterBanner와 비즈니스 로직 테스트만 수행합니다.
void main() {
  group('CharacterBanner', () {
    Widget buildTestWidget({required AiCharacter character}) {
      return MaterialApp(
        home: Scaffold(
          body: CharacterBanner(character: character),
        ),
      );
    }

    group('렌더링', () {
      testWidgets('AI 캐릭터 라벨이 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          character: AiCharacter.warmCounselor,
        ));

        expect(find.text('AI 캐릭터'), findsOneWidget);
      });

      testWidgets('캐릭터 이름이 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          character: AiCharacter.warmCounselor,
        ));

        expect(find.text(AiCharacter.warmCounselor.displayName), findsOneWidget);
      });

      testWidgets('캐릭터 설명이 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          character: AiCharacter.realisticCoach,
        ));

        expect(find.text(AiCharacter.realisticCoach.description), findsOneWidget);
      });
    });

    group('다양한 캐릭터', () {
      testWidgets('warmCounselor 캐릭터가 올바르게 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          character: AiCharacter.warmCounselor,
        ));
        expect(find.text(AiCharacter.warmCounselor.displayName), findsOneWidget);
      });

      testWidgets('realisticCoach 캐릭터가 올바르게 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          character: AiCharacter.realisticCoach,
        ));
        expect(find.text(AiCharacter.realisticCoach.displayName), findsOneWidget);
      });

      testWidgets('cheerfulFriend 캐릭터가 올바르게 표시되어야 한다', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          character: AiCharacter.cheerfulFriend,
        ));
        expect(find.text(AiCharacter.cheerfulFriend.displayName), findsOneWidget);
      });
    });
  });

  group('EmotionAnimationConfig', () {
    test('낮은 점수(1-4): 느린 등장 + shake 애니메이션', () {
      final config = EmotionAnimationConfig.forScore(3);

      expect(config.scaleDuration.inMilliseconds, 800);
      expect(config.hasShake, isTrue);
      expect(config.hasRotation, isFalse);
      expect(config.scaleBegin, 0.7);
    });

    test('중간 점수(5-7): 부드러운 등장', () {
      final config = EmotionAnimationConfig.forScore(6);

      expect(config.scaleDuration.inMilliseconds, 600);
      expect(config.hasShake, isFalse);
      expect(config.hasRotation, isFalse);
      expect(config.scaleBegin, 0.8);
    });

    test('높은 점수(8-10): 빠른 등장 + rotation 애니메이션', () {
      final config = EmotionAnimationConfig.forScore(9);

      expect(config.scaleDuration.inMilliseconds, 400);
      expect(config.hasShake, isFalse);
      expect(config.hasRotation, isTrue);
      expect(config.scaleBegin, 0.5);
    });

    test('경계값 점수(4): 낮은 점수 설정 사용', () {
      final config = EmotionAnimationConfig.forScore(4);
      expect(config.hasShake, isTrue);
    });

    test('경계값 점수(8): 높은 점수 설정 사용', () {
      final config = EmotionAnimationConfig.forScore(8);
      expect(config.hasRotation, isTrue);
    });

    test('점수 1: 가장 낮은 점수도 shake 사용', () {
      final config = EmotionAnimationConfig.forScore(1);
      expect(config.hasShake, isTrue);
      expect(config.scaleBegin, 0.7);
    });

    test('점수 10: 가장 높은 점수도 rotation 사용', () {
      final config = EmotionAnimationConfig.forScore(10);
      expect(config.hasRotation, isTrue);
      expect(config.scaleBegin, 0.5);
    });
  });
}
