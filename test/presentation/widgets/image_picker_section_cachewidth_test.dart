import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/image_picker_section.dart';

void main() {
  group('ImagePickerSection cacheWidth', () {
    Widget buildTestWidget({List<String>? imagePaths}) {
      return MaterialApp(
        home: Scaffold(
          body: ImagePickerSection(
            imagePaths: imagePaths ?? ['/fake/preview.png'],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        ),
      );
    }

    testWidgets(
      'preview tile cacheWidth should be 240 (80 × 3)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        final image = tester.widget<Image>(find.byType(Image).first);
        // cacheWidth/cacheHeight are applied via ResizeImage wrapper
        expect(image.image, isA<ResizeImage>());
        final resized = image.image as ResizeImage;
        expect(resized.width, 240);
      },
    );

    testWidgets(
      'preview tile cacheHeight should be 240',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        final image = tester.widget<Image>(find.byType(Image).first);
        expect(image.image, isA<ResizeImage>());
        final resized = image.image as ResizeImage;
        expect(resized.height, 240);
      },
    );

    testWidgets(
      'cache size is 3× display size (80 × 3 = 240)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pump(const Duration(milliseconds: 100));

        final image = tester.widget<Image>(find.byType(Image).first);
        // Display size is 80x80
        expect(image.width, 80);
        expect(image.height, 80);
        // Cache size is 3× display = 240x240
        expect(image.image, isA<ResizeImage>());
        final resized = image.image as ResizeImage;
        expect(resized.width, 240);
        expect(resized.height, 240);
      },
    );
  });
}
