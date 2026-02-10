import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/diary_image_gallery.dart';

void main() {
  setUpAll(() {
    Animate.restartOnHotReload = false;
  });

  group('DiaryImageGallery cacheWidth', () {
    Widget buildTestWidget({
      required List<String> imagePaths,
      double screenWidth = 400,
      double devicePixelRatio = 3.0,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(screenWidth, 800),
            devicePixelRatio: devicePixelRatio,
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: DiaryImageGallery(imagePaths: imagePaths),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'cacheWidth = screen_width/2 * DPR (400w, 3.0 DPR → 600)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(
          imagePaths: ['/fake/image1.png'],
          screenWidth: 400,
          devicePixelRatio: 3.0,
        ));
        await tester.pump(const Duration(milliseconds: 500));

        final image = tester.widget<Image>(find.byType(Image).first);
        // cacheWidth/cacheHeight via ResizeImage: (400 / 2) * 3.0 = 600
        expect(image.image, isA<ResizeImage>());
        final resized = image.image as ResizeImage;
        expect(resized.width, 600);
        expect(resized.height, 600);
      },
    );

    testWidgets(
      'cacheWidth = screen_width/2 * DPR (800w, 2.0 DPR → 800)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestWidget(
          imagePaths: ['/fake/image1.png'],
          screenWidth: 800,
          devicePixelRatio: 2.0,
        ));
        await tester.pump(const Duration(milliseconds: 500));

        final image = tester.widget<Image>(find.byType(Image).first);
        // (800 / 2) * 2.0 = 800
        expect(image.image, isA<ResizeImage>());
        final resized = image.image as ResizeImage;
        expect(resized.width, 800);
        expect(resized.height, 800);
      },
    );

    testWidgets(
      'cacheWidth is null when MediaQuery.size is zero',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(
          imagePaths: ['/fake/image1.png'],
          screenWidth: 0,
          devicePixelRatio: 3.0,
        ));
        await tester.pump(const Duration(milliseconds: 500));

        final image = tester.widget<Image>(find.byType(Image).first);
        // rawPixelSize = (0 / 2) * 3.0 = 0 → guard returns null → no ResizeImage
        expect(image.image, isNot(isA<ResizeImage>()));
      },
    );

    testWidgets(
      'DPR 1.0: 360w → cacheWidth 180',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(
          imagePaths: ['/fake/image1.png'],
          screenWidth: 360,
          devicePixelRatio: 1.0,
        ));
        await tester.pump(const Duration(milliseconds: 500));

        final image = tester.widget<Image>(find.byType(Image).first);
        // (360 / 2) * 1.0 = 180
        expect(image.image, isA<ResizeImage>());
        final resized = image.image as ResizeImage;
        expect(resized.width, 180);
        expect(resized.height, 180);
      },
    );

    testWidgets(
      'cacheWidth and cacheHeight should be equal (square tiles)',
      (tester) async {
        await tester.pumpWidget(buildTestWidget(
          imagePaths: ['/fake/image1.png', '/fake/image2.png'],
          screenWidth: 414,
          devicePixelRatio: 3.0,
        ));
        await tester.pump(const Duration(milliseconds: 500));

        final images = find.byType(Image);
        for (final element in images.evaluate()) {
          final image = element.widget as Image;
          if (image.image is ResizeImage) {
            final resized = image.image as ResizeImage;
            expect(resized.width, resized.height);
          }
        }
      },
    );
  });
}
