import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/fullscreen_image_viewer.dart';

void main() {
  /// 직접 뷰어를 표시하는 위젯 - 애니메이션 비활성화
  Widget buildDirectViewerWidget({
    required List<String> imagePaths,
    int initialIndex = 0,
    String? heroTagPrefix,
  }) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: FullscreenImageViewer(
          imagePaths: imagePaths,
          initialIndex: initialIndex,
          heroTagPrefix: heroTagPrefix,
        ),
      ),
    );
  }

  group('FullscreenImageViewer', () {
    group('기본 표시', () {
      testWidgets('단일 이미지일 때 페이지 인디케이터가 표시되지 않는다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildDirectViewerWidget(imagePaths: ['/fake/path/image1.jpg']),
        );
        await tester.pump();

        // Assert - 페이지 인디케이터 없음
        expect(find.text('1 / 1'), findsNothing);
      });

      testWidgets('여러 이미지일 때 페이지 인디케이터가 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildDirectViewerWidget(
            imagePaths: ['/fake/path/image1.jpg', '/fake/path/image2.jpg'],
          ),
        );
        await tester.pump();

        // Assert
        expect(find.text('1 / 2'), findsOneWidget);
      });

      testWidgets('닫기 버튼이 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildDirectViewerWidget(imagePaths: ['/fake/path/image1.jpg']),
        );
        await tester.pump();

        // Assert
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('PageView가 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildDirectViewerWidget(imagePaths: ['/fake/path/image1.jpg']),
        );
        await tester.pump();

        // Assert
        expect(find.byType(PageView), findsOneWidget);
      });

      testWidgets('InteractiveViewer가 표시된다 (zoom/pan 지원)', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildDirectViewerWidget(imagePaths: ['/fake/path/image1.jpg']),
        );
        await tester.pump();

        // Assert
        expect(find.byType(InteractiveViewer), findsOneWidget);
      });
    });

    group('초기 인덱스', () {
      testWidgets('initialIndex가 0이면 첫 번째 이미지를 표시한다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildDirectViewerWidget(
            imagePaths: ['/fake/path/image1.jpg', '/fake/path/image2.jpg'],
            initialIndex: 0,
          ),
        );
        await tester.pump();

        // Assert
        expect(find.text('1 / 2'), findsOneWidget);
      });

      testWidgets('initialIndex가 1이면 두 번째 이미지를 표시한다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildDirectViewerWidget(
            imagePaths: ['/fake/path/image1.jpg', '/fake/path/image2.jpg'],
            initialIndex: 1,
          ),
        );
        await tester.pump();

        // Assert
        expect(find.text('2 / 2'), findsOneWidget);
      });
    });

    group('Hero 애니메이션', () {
      testWidgets('heroTagPrefix가 주어지면 Hero 위젯이 생성된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildDirectViewerWidget(
            imagePaths: ['/fake/path/image1.jpg'],
            heroTagPrefix: 'test_hero',
          ),
        );
        await tester.pump();

        // Assert
        expect(find.byType(Hero), findsOneWidget);
      });

      testWidgets('heroTagPrefix가 없어도 이미지가 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildDirectViewerWidget(imagePaths: ['/fake/path/image1.jpg']),
        );
        await tester.pump();

        // Assert - Hero가 없어도 InteractiveViewer는 표시됨
        expect(find.byType(InteractiveViewer), findsOneWidget);
      });
    });

    group('빈 이미지 목록', () {
      testWidgets('빈 목록이면 빈 PageView가 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildDirectViewerWidget(imagePaths: []));
        await tester.pump();

        // Assert
        expect(find.byType(PageView), findsOneWidget);
        // 페이지 인디케이터 없음
        expect(find.textContaining('/'), findsNothing);
      });
    });

    group('FullscreenImageViewer 클래스', () {
      test('기본 생성자가 올바르게 동작한다', () {
        // Arrange & Act
        const viewer = FullscreenImageViewer(
          imagePaths: ['/test/path'],
          initialIndex: 0,
          heroTagPrefix: 'test',
        );

        // Assert
        expect(viewer.imagePaths, equals(['/test/path']));
        expect(viewer.initialIndex, equals(0));
        expect(viewer.heroTagPrefix, equals('test'));
      });

      test('기본값이 올바르게 설정된다', () {
        // Arrange & Act
        const viewer = FullscreenImageViewer(imagePaths: ['/test/path']);

        // Assert
        expect(viewer.initialIndex, equals(0));
        expect(viewer.heroTagPrefix, isNull);
      });
    });
  });
}
