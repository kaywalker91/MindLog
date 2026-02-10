import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/fullscreen_image_viewer.dart';

void main() {
  group('FullscreenImageViewer no-cache (zoom support)', () {
    Widget buildTestWidget({List<String>? imagePaths}) {
      return MaterialApp(
        home: FullscreenImageViewer(
          imagePaths: imagePaths ?? ['/fake/fullscreen.png'],
          initialIndex: 0,
        ),
      );
    }

    testWidgets(
      'fullscreen Image should NOT have cacheWidth (no ResizeImage)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 500));

        final images = find.byType(Image);
        expect(images, findsWidgets);

        final image = tester.widget<Image>(images.first);
        // Fullscreen images must NOT use ResizeImage for zoom support
        expect(image.image, isNot(isA<ResizeImage>()));
      },
    );

    testWidgets(
      'fullscreen Image should NOT have cacheHeight (no ResizeImage)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 500));

        final images = find.byType(Image);
        expect(images, findsWidgets);

        final image = tester.widget<Image>(images.first);
        expect(image.image, isNot(isA<ResizeImage>()));
      },
    );
  });
}
