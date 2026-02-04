import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/app_constants.dart';
import 'package:mindlog/core/errors/exceptions.dart';
import 'package:mindlog/core/services/image_service.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    // 테스트용 임시 디렉토리 생성
    tempDir = await Directory.systemTemp.createTemp('image_service_test_');
  });

  tearDown(() async {
    // 테스트 후 임시 디렉토리 정리
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ImageService', () {
    group('AppConstants 이미지 설정', () {
      test('groqVisionModel이 올바르게 정의되어 있다', () {
        expect(
          AppConstants.groqVisionModel,
          'meta-llama/llama-4-scout-17b-16e-instruct',
        );
      });

      test('maxImagesPerDiary가 5개로 정의되어 있다', () {
        expect(AppConstants.maxImagesPerDiary, 5);
      });

      test('maxImageSizeBytes가 4MB로 정의되어 있다', () {
        expect(AppConstants.maxImageSizeBytes, 4 * 1024 * 1024);
      });

      test('imageCompressQuality가 85로 정의되어 있다', () {
        expect(AppConstants.imageCompressQuality, 85);
      });

      test('imageMaxWidth가 1920으로 정의되어 있다', () {
        expect(AppConstants.imageMaxWidth, 1920);
      });
    });

    group('getImageSize', () {
      test('존재하는 파일의 크기를 반환한다', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test_image.jpg'));
        final testData = List.filled(1024, 0); // 1KB 데이터
        await testFile.writeAsBytes(testData);

        // Act
        final size = await ImageService.getImageSize(testFile.path);

        // Assert
        expect(size, 1024);
      });

      test('존재하지 않는 파일은 0을 반환한다', () async {
        // Arrange
        final nonExistentPath = path.join(tempDir.path, 'non_existent.jpg');

        // Act
        final size = await ImageService.getImageSize(nonExistentPath);

        // Assert
        expect(size, 0);
      });
    });

    group('readImageBytes', () {
      test('존재하는 파일의 바이트를 반환한다', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test_image.jpg'));
        final testData = [255, 216, 255, 224]; // JPEG 시그니처
        await testFile.writeAsBytes(testData);

        // Act
        final bytes = await ImageService.readImageBytes(testFile.path);

        // Assert
        expect(bytes.length, 4);
        expect(bytes[0], 255);
        expect(bytes[1], 216);
      });

      test('존재하지 않는 파일은 ImageProcessingException을 던진다', () async {
        // Arrange
        final nonExistentPath = path.join(tempDir.path, 'non_existent.jpg');

        // Act & Assert
        expect(
          () => ImageService.readImageBytes(nonExistentPath),
          throwsA(isA<ImageProcessingException>()),
        );
      });
    });

    group('deleteImage', () {
      test('존재하는 파일을 삭제한다', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'to_delete.jpg'));
        await testFile.writeAsBytes([1, 2, 3]);
        expect(await testFile.exists(), true);

        // Act
        await ImageService.deleteImage(testFile.path);

        // Assert
        expect(await testFile.exists(), false);
      });

      test('존재하지 않는 파일 삭제 시 예외를 던지지 않는다', () async {
        // Arrange
        final nonExistentPath = path.join(tempDir.path, 'non_existent.jpg');

        // Act & Assert (예외 없이 완료되어야 함)
        await expectLater(ImageService.deleteImage(nonExistentPath), completes);
      });
    });

    group('encodeToBase64DataUrl', () {
      test('JPEG 파일을 올바른 Data URL로 인코딩한다', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.jpg'));
        final testData = [255, 216, 255, 224]; // JPEG 시그니처
        await testFile.writeAsBytes(testData);

        // Act
        final dataUrl = await ImageService.encodeToBase64DataUrl(testFile.path);

        // Assert
        expect(dataUrl.startsWith('data:image/jpeg;base64,'), true);
        final base64Part = dataUrl.split(',')[1];
        final decoded = base64Decode(base64Part);
        expect(decoded, testData);
      });

      test('PNG 파일을 올바른 Data URL로 인코딩한다', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.png'));
        final testData = [137, 80, 78, 71]; // PNG 시그니처
        await testFile.writeAsBytes(testData);

        // Act
        final dataUrl = await ImageService.encodeToBase64DataUrl(testFile.path);

        // Assert
        expect(dataUrl.startsWith('data:image/png;base64,'), true);
      });

      test('WebP 파일을 올바른 Data URL로 인코딩한다', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.webp'));
        final testData = [82, 73, 70, 70]; // RIFF 시그니처
        await testFile.writeAsBytes(testData);

        // Act
        final dataUrl = await ImageService.encodeToBase64DataUrl(testFile.path);

        // Assert
        expect(dataUrl.startsWith('data:image/webp;base64,'), true);
      });

      test('HEIC 파일을 올바른 Data URL로 인코딩한다', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.heic'));
        final testData = [0, 0, 0, 24]; // HEIC 시그니처
        await testFile.writeAsBytes(testData);

        // Act
        final dataUrl = await ImageService.encodeToBase64DataUrl(testFile.path);

        // Assert
        expect(dataUrl.startsWith('data:image/heic;base64,'), true);
      });

      test('확장자 없는 파일은 JPEG로 처리된다', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test'));
        final testData = [255, 216, 255, 224];
        await testFile.writeAsBytes(testData);

        // Act
        final dataUrl = await ImageService.encodeToBase64DataUrl(testFile.path);

        // Assert
        expect(dataUrl.startsWith('data:image/jpeg;base64,'), true);
      });

      test('존재하지 않는 파일은 ImageProcessingException을 던진다', () async {
        // Arrange
        final nonExistentPath = path.join(tempDir.path, 'non_existent.jpg');

        // Act & Assert
        expect(
          () => ImageService.encodeToBase64DataUrl(nonExistentPath),
          throwsA(isA<ImageProcessingException>()),
        );
      });
    });

    group('encodeMultipleToBase64DataUrls', () {
      test('여러 이미지를 순서대로 인코딩한다', () async {
        // Arrange
        final files = <File>[];
        for (int i = 0; i < 3; i++) {
          final file = File(path.join(tempDir.path, 'test_$i.jpg'));
          await file.writeAsBytes([255, 216, 255, i]);
          files.add(file);
        }

        // Act
        final dataUrls = await ImageService.encodeMultipleToBase64DataUrls(
          files.map((f) => f.path).toList(),
        );

        // Assert
        expect(dataUrls.length, 3);
        for (int i = 0; i < 3; i++) {
          expect(dataUrls[i].startsWith('data:image/jpeg;base64,'), true);
          final base64Part = dataUrls[i].split(',')[1];
          final decoded = base64Decode(base64Part);
          expect(decoded[3], i); // 각 파일의 마지막 바이트가 인덱스와 일치
        }
      });

      test('빈 목록은 빈 결과를 반환한다', () async {
        // Act
        final dataUrls = await ImageService.encodeMultipleToBase64DataUrls([]);

        // Assert
        expect(dataUrls, isEmpty);
      });

      test('하나의 파일이 없으면 예외를 던진다', () async {
        // Arrange
        final existingFile = File(path.join(tempDir.path, 'existing.jpg'));
        await existingFile.writeAsBytes([255, 216, 255, 224]);
        final nonExistentPath = path.join(tempDir.path, 'non_existent.jpg');

        // Act & Assert
        expect(
          () => ImageService.encodeMultipleToBase64DataUrls([
            existingFile.path,
            nonExistentPath,
          ]),
          throwsA(isA<ImageProcessingException>()),
        );
      });
    });

    group('deleteDiaryImages', () {
      test('일기 이미지 디렉토리 전체를 삭제한다', () async {
        // 이 테스트는 실제 앱 Documents 디렉토리에 의존하므로
        // 통합 테스트에서 수행하는 것이 적절함
        // 여기서는 메서드가 예외 없이 완료되는지만 확인
        await expectLater(
          ImageService.deleteDiaryImages('non_existent_diary_id'),
          completes,
        );
      });
    });

    group('copyToAppDirectory', () {
      test('존재하지 않는 원본 파일은 ImageProcessingException을 던진다', () async {
        // Arrange
        final nonExistentPath = path.join(tempDir.path, 'non_existent.jpg');

        // Act & Assert
        expect(
          () => ImageService.copyToAppDirectory(
            sourcePath: nonExistentPath,
            diaryId: 'test-diary-id',
            index: 0,
          ),
          throwsA(isA<ImageProcessingException>()),
        );
      });
    });

    group('compressIfNeeded', () {
      test('존재하지 않는 파일은 ImageProcessingException을 던진다', () async {
        // Arrange
        final nonExistentPath = path.join(tempDir.path, 'non_existent.jpg');

        // Act & Assert
        expect(
          () => ImageService.compressIfNeeded(nonExistentPath),
          throwsA(isA<ImageProcessingException>()),
        );
      });

      test('4MB 이하 파일은 원본 경로를 그대로 반환한다', () async {
        // Arrange - 1KB 테스트 파일 생성
        final testFile = File(path.join(tempDir.path, 'small_image.jpg'));
        final testData = List.filled(1024, 255); // 1KB
        await testFile.writeAsBytes(testData);

        // Act
        final result = await ImageService.compressIfNeeded(testFile.path);

        // Assert
        expect(result, testFile.path);
      });
    });
  });

  group('ImageProcessingException', () {
    test('메시지 없이 생성할 수 있다', () {
      final exception = ImageProcessingException();
      expect(exception.message, isNull);
      expect(exception.toString(), 'ImageProcessingException: null');
    });

    test('메시지와 함께 생성할 수 있다', () {
      final exception = ImageProcessingException('테스트 오류');
      expect(exception.message, '테스트 오류');
      expect(exception.toString(), 'ImageProcessingException: 테스트 오류');
    });
  });
}
