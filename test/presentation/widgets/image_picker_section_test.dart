import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/app_constants.dart';
import 'package:mindlog/presentation/widgets/image_picker_section.dart';

void main() {
  /// 테스트용 위젯 생성
  Widget buildTestWidget({
    required List<String> imagePaths,
    required void Function(String) onImageAdded,
    required void Function(int) onImageRemoved,
    bool isLoading = false,
  }) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ImagePickerSection(
            imagePaths: imagePaths,
            onImageAdded: onImageAdded,
            onImageRemoved: onImageRemoved,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }

  group('ImagePickerSection', () {
    group('초기 상태', () {
      testWidgets('이미지가 없을 때 안내 텍스트를 표시한다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: [],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Assert
        expect(find.text('사진 첨부'), findsOneWidget);
        expect(
          find.text('0/${AppConstants.maxImagesPerDiary}'),
          findsOneWidget,
        );
        expect(find.text('사진을 첨부하면 AI가 이미지도 함께 분석해요'), findsOneWidget);
      });

      testWidgets('추가 버튼이 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: [],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Assert
        expect(find.text('추가'), findsOneWidget);
        expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
      });

      testWidgets('사진 아이콘이 헤더에 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: [],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Assert
        expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      });
    });

    group('이미지 카운터', () {
      testWidgets('이미지 1개일 때 카운터가 올바르게 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: ['/fake/path/image1.jpg'],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Assert
        expect(
          find.text('1/${AppConstants.maxImagesPerDiary}'),
          findsOneWidget,
        );
      });

      testWidgets('이미지 3개일 때 카운터가 올바르게 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: [
              '/fake/path/image1.jpg',
              '/fake/path/image2.jpg',
              '/fake/path/image3.jpg',
            ],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Assert
        expect(
          find.text('3/${AppConstants.maxImagesPerDiary}'),
          findsOneWidget,
        );
      });

      testWidgets('이미지가 있으면 안내 텍스트가 숨겨진다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: ['/fake/path/image.jpg'],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Assert
        expect(find.text('사진을 첨부하면 AI가 이미지도 함께 분석해요'), findsNothing);
      });
    });

    group('최대 이미지 제한', () {
      testWidgets('최대 개수에 도달하면 추가 버튼이 숨겨진다', (tester) async {
        // Arrange
        final imagePaths = List.generate(
          AppConstants.maxImagesPerDiary,
          (i) => '/fake/path/image_$i.jpg',
        );

        // Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: imagePaths,
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Assert
        expect(find.text('추가'), findsNothing);
        expect(
          find.text(
            '${AppConstants.maxImagesPerDiary}/${AppConstants.maxImagesPerDiary}',
          ),
          findsOneWidget,
        );
      });

      testWidgets('최대 개수 미만이면 추가 버튼이 표시된다', (tester) async {
        // Arrange
        final imagePaths = List.generate(
          AppConstants.maxImagesPerDiary - 1,
          (i) => '/fake/path/image_$i.jpg',
        );

        // Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: imagePaths,
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Assert
        expect(find.text('추가'), findsOneWidget);
      });
    });

    group('로딩 상태', () {
      testWidgets('로딩 중에는 추가 버튼이 숨겨진다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: [],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
            isLoading: true,
          ),
        );

        // Assert
        expect(find.text('추가'), findsNothing);
      });

      testWidgets('로딩 중에는 삭제 버튼이 비활성화된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: ['/fake/path/image.jpg'],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
            isLoading: true,
          ),
        );

        // Assert - 삭제 버튼(X 아이콘)이 표시되지 않아야 함
        expect(find.byIcon(Icons.close), findsNothing);
      });

      testWidgets('로딩 중이 아니면 삭제 버튼이 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: ['/fake/path/image.jpg'],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
            isLoading: false,
          ),
        );

        // Assert - 삭제 버튼 표시
        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });

    group('콜백 테스트', () {
      testWidgets('이미지 삭제 버튼 탭 시 onImageRemoved가 호출된다', (tester) async {
        // Arrange
        int? removedIndex;

        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: ['/fake/path/image.jpg'],
            onImageAdded: (_) {},
            onImageRemoved: (index) => removedIndex = index,
          ),
        );

        // Act - 삭제 버튼 탭
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        // Assert
        expect(removedIndex, 0);
      });

      testWidgets('여러 이미지 중 두 번째 삭제 버튼 탭 시 올바른 인덱스로 콜백', (tester) async {
        // Arrange
        int? removedIndex;

        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: [
              '/fake/path/image1.jpg',
              '/fake/path/image2.jpg',
              '/fake/path/image3.jpg',
            ],
            onImageAdded: (_) {},
            onImageRemoved: (index) => removedIndex = index,
          ),
        );

        // Act - 두 번째 삭제 버튼 탭 (인덱스 1)
        final closeButtons = find.byIcon(Icons.close);
        await tester.tap(closeButtons.at(1));
        await tester.pump();

        // Assert
        expect(removedIndex, 1);
      });

      testWidgets('추가 버튼 탭 시 바텀시트가 표시된다', (tester) async {
        // Arrange
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: [],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Act
        await tester.tap(find.text('추가'));
        await tester.pumpAndSettle();

        // Assert - 바텀시트 옵션들이 표시됨
        expect(find.text('갤러리에서 선택'), findsOneWidget);
        expect(find.text('카메라로 촬영'), findsOneWidget);
      });

      testWidgets('바텀시트에 아이콘이 표시된다', (tester) async {
        // Arrange
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: [],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Act
        await tester.tap(find.text('추가'));
        await tester.pumpAndSettle();

        // Assert - 바텀시트 내 카메라 아이콘 확인
        expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      });

      testWidgets('바텀시트 갤러리 옵션 탭 시 시트가 닫힌다', (tester) async {
        // Arrange
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: [],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Act - 추가 버튼 탭 후 갤러리 옵션 탭
        await tester.tap(find.text('추가'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('갤러리에서 선택'));
        await tester.pumpAndSettle();

        // Assert - 바텀시트가 닫힘 (갤러리 옵션 사라짐)
        expect(find.text('갤러리에서 선택'), findsNothing);
      });

      testWidgets('바텀시트 카메라 옵션 탭 시 시트가 닫힌다', (tester) async {
        // Arrange
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: [],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Act
        await tester.tap(find.text('추가'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('카메라로 촬영'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('카메라로 촬영'), findsNothing);
      });
    });

    group('여러 이미지 표시', () {
      testWidgets('여러 이미지만큼 삭제 버튼이 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          buildTestWidget(
            imagePaths: [
              '/fake/path/image1.jpg',
              '/fake/path/image2.jpg',
              '/fake/path/image3.jpg',
            ],
            onImageAdded: (_) {},
            onImageRemoved: (_) {},
          ),
        );

        // Assert - 이미지 수만큼 삭제 버튼이 존재
        expect(find.byIcon(Icons.close), findsNWidgets(3));
      });
    });

    // Note: 이미지 에러 처리 테스트는 실제 디바이스에서 Image.file이
    // 파일을 로드할 때만 errorBuilder가 호출되므로, 통합 테스트에서 확인합니다.

    group('AppConstants 이미지 상수 검증', () {
      test('maxImagesPerDiary가 5로 정의되어 있다', () {
        expect(AppConstants.maxImagesPerDiary, 5);
      });
    });
  });
}
