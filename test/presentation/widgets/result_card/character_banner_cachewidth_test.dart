import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/presentation/widgets/result_card/character_banner.dart';

void main() {
  group('CharacterBanner cacheWidth', () {
    Widget buildTestWidget(AiCharacter character) {
      return MaterialApp(
        home: Scaffold(body: CharacterBanner(character: character)),
      );
    }

    testWidgets('character image cacheWidth should be 132 (44 × 3)', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(AiCharacter.warmCounselor));
      await tester.pump(const Duration(milliseconds: 100));

      final image = tester.widget<Image>(find.byType(Image).first);
      expect(image.image, isA<ResizeImage>());
      final resized = image.image as ResizeImage;
      expect(resized.width, 132);
    });

    testWidgets('character image cacheHeight should be 132', (tester) async {
      await tester.pumpWidget(buildTestWidget(AiCharacter.warmCounselor));
      await tester.pump(const Duration(milliseconds: 100));

      final image = tester.widget<Image>(find.byType(Image).first);
      expect(image.image, isA<ResizeImage>());
      final resized = image.image as ResizeImage;
      expect(resized.height, 132);
    });

    testWidgets('cache size is 3× display size (44 × 3 = 132)', (tester) async {
      await tester.pumpWidget(buildTestWidget(AiCharacter.realisticCoach));
      await tester.pump(const Duration(milliseconds: 100));

      final image = tester.widget<Image>(find.byType(Image).first);
      expect(image.width, 44);
      expect(image.height, 44);
      expect(image.image, isA<ResizeImage>());
      final resized = image.image as ResizeImage;
      expect(resized.width, 132);
      expect(resized.height, 132);
    });

    testWidgets('all AiCharacter values should have consistent cacheWidth', (
      tester,
    ) async {
      for (final character in AiCharacter.values) {
        await tester.pumpWidget(buildTestWidget(character));
        await tester.pump(const Duration(milliseconds: 100));

        final image = tester.widget<Image>(find.byType(Image).first);
        expect(
          image.image,
          isA<ResizeImage>(),
          reason: '${character.name} should use ResizeImage',
        );
        final resized = image.image as ResizeImage;
        expect(
          resized.width,
          132,
          reason: '${character.name} should have cacheWidth 132',
        );
        expect(
          resized.height,
          132,
          reason: '${character.name} should have cacheHeight 132',
        );
      }
    });
  });
}
