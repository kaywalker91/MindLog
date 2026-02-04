import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/diary_image_gallery.dart';

void main() {
  /// 테스트용 위젯 생성 - 애니메이션 비활성화를 위해 MediaQuery 래핑
  Widget buildTestWidget({
    required List<String> imagePaths,
    String? galleryId,
  }) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: MediaQuery(
        // 애니메이션 비활성화
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: SingleChildScrollView(
            child: DiaryImageGallery(
              imagePaths: imagePaths,
              galleryId: galleryId,
            ),
          ),
        ),
      ),
    );
  }

  group('DiaryImageGallery', () {
    group('빈 상태', () {
      testWidgets('이미지가 없으면 아무것도 표시하지 않는다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildTestWidget(imagePaths: []));

        // Assert
        expect(find.text('첨부 사진'), findsNothing);
        expect(find.byType(GridView), findsNothing);
      });
    });

    group('헤더 표시', () {
      testWidgets('이미지가 있으면 헤더가 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(imagePaths: ['/fake/path/image1.jpg']),
        );

        // Assert
        expect(find.text('첨부 사진'), findsOneWidget);
        expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      });

      testWidgets('이미지 개수가 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: ['/fake/path/image1.jpg', '/fake/path/image2.jpg'],
          ),
        );

        // Assert
        expect(find.text('2장'), findsOneWidget);
      });

      testWidgets('이미지 1개일 때 "1장"으로 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(imagePaths: ['/fake/path/image1.jpg']),
        );

        // Assert
        expect(find.text('1장'), findsOneWidget);
      });

      testWidgets('이미지 5개일 때 "5장"으로 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: List.generate(5, (i) => '/fake/path/image_$i.jpg'),
          ),
        );

        // Assert
        expect(find.text('5장'), findsOneWidget);
      });
    });

    group('그리드 레이아웃', () {
      testWidgets('이미지가 있으면 GridView가 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(imagePaths: ['/fake/path/image1.jpg']),
        );

        // Assert
        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('GridView는 스크롤되지 않는다 (shrinkWrap)', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: List.generate(5, (i) => '/fake/path/image_$i.jpg'),
          ),
        );

        // Assert
        final gridView = tester.widget<GridView>(find.byType(GridView));
        expect(gridView.shrinkWrap, isTrue);
        expect(gridView.physics, isA<NeverScrollableScrollPhysics>());
      });
    });

    group('galleryId 설정', () {
      testWidgets('galleryId가 주어지면 Hero 태그에 사용된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: ['/fake/path/image1.jpg'],
            galleryId: 'test_gallery',
          ),
        );

        // Assert
        final heroFinder = find.byType(Hero);
        expect(heroFinder, findsOneWidget);

        final hero = tester.widget<Hero>(heroFinder);
        expect(hero.tag, equals('test_gallery_0'));
      });

      testWidgets('galleryId가 없으면 기본값 "diary_gallery"를 사용한다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(imagePaths: ['/fake/path/image1.jpg']),
        );

        // Assert
        final hero = tester.widget<Hero>(find.byType(Hero));
        expect(hero.tag, equals('diary_gallery_0'));
      });

      testWidgets('여러 이미지의 Hero 태그가 인덱스에 따라 달라진다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: ['/fake/path/image1.jpg', '/fake/path/image2.jpg'],
            galleryId: 'multi_gallery',
          ),
        );

        // Assert
        final heroes = tester.widgetList<Hero>(find.byType(Hero)).toList();
        expect(heroes.length, equals(2));
        expect(heroes[0].tag, equals('multi_gallery_0'));
        expect(heroes[1].tag, equals('multi_gallery_1'));
      });
    });
  });
}
