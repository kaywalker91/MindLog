import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Top-level function for Isolate processing
/// Must be outside class for compute() to work
Future<String> _encodeToBase64InIsolate(String imagePath) async {
  final file = File(imagePath);
  final bytes = await file.readAsBytes();
  final base64String = base64Encode(bytes);
  final extension = p.extension(imagePath).toLowerCase();
  final mimeType = switch (extension) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.gif' => 'image/gif',
    '.heic' => 'image/heic',
    _ => 'image/jpeg',
  };
  return 'data:$mimeType;base64,$base64String';
}

/// 이미지 처리 서비스
///
/// 일기에 첨부된 이미지의 저장, 압축, 인코딩을 담당합니다.
/// - 앱 디렉토리로 이미지 복사
/// - 4MB 초과 시 자동 압축
/// - Base64 Data URL 인코딩 (Vision API 전송용)
/// - 일기 삭제 시 관련 이미지 정리
class ImageService {
  const ImageService._();

  /// 이미지를 앱 디렉토리로 복사
  ///
  /// [sourcePath] 원본 이미지 경로 (갤러리/카메라에서 선택된 파일)
  /// [diaryId] 일기 고유 ID
  /// [index] 이미지 인덱스 (0부터 시작)
  ///
  /// 반환: 저장된 이미지의 절대 경로
  static Future<String> copyToAppDirectory({
    required String sourcePath,
    required String diaryId,
    required int index,
  }) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw ImageProcessingException('원본 이미지 파일을 찾을 수 없습니다.');
      }

      // 앱 Documents 디렉토리 내 diary_images/{diaryId}/ 폴더 생성
      final appDir = await getApplicationDocumentsDirectory();
      final diaryImagesDir = Directory(
        p.join(appDir.path, 'diary_images', diaryId),
      );
      if (!await diaryImagesDir.exists()) {
        await diaryImagesDir.create(recursive: true);
      }

      // 파일 확장자 추출 (기본값: jpg)
      final extension = p.extension(sourcePath).toLowerCase();
      final validExtension =
          ['.jpg', '.jpeg', '.png', '.webp', '.heic'].contains(extension)
          ? extension
          : '.jpg';

      final destPath = p.join(
        diaryImagesDir.path,
        'image_$index$validExtension',
      );
      final destFile = await sourceFile.copy(destPath);

      return destFile.path;
    } catch (e) {
      if (e is ImageProcessingException) rethrow;
      throw ImageProcessingException('이미지 복사 실패: $e');
    }
  }

  /// 이미지 압축 (4MB 초과 시)
  ///
  /// [imagePath] 압축할 이미지 경로
  ///
  /// 반환: 압축된 이미지 경로 (원본이 4MB 이하면 원본 경로 반환)
  static Future<String> compressIfNeeded(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw ImageProcessingException('압축할 이미지 파일을 찾을 수 없습니다.');
      }

      final fileSize = await file.length();

      // 4MB 이하면 압축 불필요
      if (fileSize <= AppConstants.maxImageSizeBytes) {
        return imagePath;
      }

      // 압축 실행
      final compressedPath = _getCompressedPath(imagePath);
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        compressedPath,
        quality: AppConstants.imageCompressQuality,
        minWidth: AppConstants.imageMaxWidth,
        minHeight: AppConstants.imageMaxWidth,
        format: _getCompressFormat(imagePath),
      );

      if (compressedFile == null) {
        throw ImageProcessingException('이미지 압축에 실패했습니다.');
      }

      // 압축 후에도 4MB 초과 시 품질을 낮춰서 재압축
      final compressedSize = await File(compressedFile.path).length();
      if (compressedSize > AppConstants.maxImageSizeBytes) {
        return _recompressWithLowerQuality(compressedFile.path);
      }

      // 압축 성공 시 원본 삭제하고 압축 파일로 대체
      await file.delete();
      await File(compressedFile.path).rename(imagePath);

      return imagePath;
    } catch (e) {
      if (e is ImageProcessingException) rethrow;
      throw ImageProcessingException('이미지 압축 실패: $e');
    }
  }

  /// 이미지를 Base64 Data URL로 인코딩 (Vision API 전송용)
  ///
  /// [imagePath] 인코딩할 이미지 경로
  ///
  /// 반환: `data:image/{format};base64,{encoded_data}` 형식의 문자열
  ///
  /// Note: compute()로 별도 Isolate에서 실행하여 UI 스레드 블로킹 방지
  static Future<String> encodeToBase64DataUrl(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw ImageProcessingException('인코딩할 이미지 파일을 찾을 수 없습니다.');
      }

      // Isolate에서 Base64 인코딩 실행 (UI 프리징 방지)
      return await compute(_encodeToBase64InIsolate, imagePath);
    } catch (e) {
      if (e is ImageProcessingException) rethrow;
      throw ImageProcessingException('이미지 인코딩 실패: $e');
    }
  }

  /// 여러 이미지를 Base64 Data URL 리스트로 인코딩
  ///
  /// [imagePaths] 인코딩할 이미지 경로 목록
  ///
  /// 반환: Data URL 문자열 리스트
  ///
  /// Note: Future.wait으로 병렬 처리하여 다중 이미지 인코딩 속도 향상
  static Future<List<String>> encodeMultipleToBase64DataUrls(
    List<String> imagePaths,
  ) async {
    // 병렬 처리로 다중 이미지 인코딩 (순차 처리 대비 ~3배 속도 향상)
    return Future.wait(imagePaths.map((path) => encodeToBase64DataUrl(path)));
  }

  /// 일기 관련 이미지 전체 삭제
  ///
  /// [diaryId] 일기 고유 ID
  static Future<void> deleteDiaryImages(String diaryId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final diaryImagesDir = Directory(
        p.join(appDir.path, 'diary_images', diaryId),
      );

      if (await diaryImagesDir.exists()) {
        await diaryImagesDir.delete(recursive: true);
        debugPrint('Deleted images for diary: $diaryId');
      }
    } catch (e) {
      // 이미지 삭제 실패는 무시 (일기 삭제는 성공해야 함)
      debugPrint('Failed to delete images for diary $diaryId: $e');
    }
  }

  /// 특정 이미지 파일 삭제
  ///
  /// [imagePath] 삭제할 이미지 경로
  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to delete image: $e');
    }
  }

  /// 이미지 파일 크기 조회 (바이트)
  static Future<int> getImageSize(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// 이미지 바이트를 읽어서 반환
  static Future<Uint8List> readImageBytes(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw ImageProcessingException('이미지 파일을 찾을 수 없습니다.');
    }
    return await file.readAsBytes();
  }

  // ===== Private Helper Methods =====

  /// 압축 파일 경로 생성
  static String _getCompressedPath(String originalPath) {
    final dir = p.dirname(originalPath);
    final baseName = p.basenameWithoutExtension(originalPath);
    final extension = p.extension(originalPath);
    return p.join(dir, '${baseName}_compressed$extension');
  }

  /// 파일 확장자에 따른 압축 포맷 반환
  static CompressFormat _getCompressFormat(String imagePath) {
    final extension = p.extension(imagePath).toLowerCase();
    switch (extension) {
      case '.png':
        return CompressFormat.png;
      case '.webp':
        return CompressFormat.webp;
      case '.heic':
        return CompressFormat.heic;
      default:
        return CompressFormat.jpeg;
    }
  }

  /// 품질을 낮춰서 재압축 (4MB 이하가 될 때까지)
  static Future<String> _recompressWithLowerQuality(String imagePath) async {
    int quality = 70;
    String currentPath = imagePath;

    while (quality >= 30) {
      final compressedPath = _getCompressedPath(currentPath);
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        currentPath,
        compressedPath,
        quality: quality,
        minWidth: AppConstants.imageMaxWidth,
        minHeight: AppConstants.imageMaxWidth,
        format: _getCompressFormat(currentPath),
      );

      if (compressedFile == null) {
        throw ImageProcessingException('이미지 재압축에 실패했습니다.');
      }

      final compressedSize = await File(compressedFile.path).length();
      if (compressedSize <= AppConstants.maxImageSizeBytes) {
        // 성공 시 원본 삭제
        await File(currentPath).delete();
        return compressedFile.path;
      }

      // 다음 시도를 위해 품질 낮춤
      await File(currentPath).delete();
      currentPath = compressedFile.path;
      quality -= 15;
    }

    throw ImageProcessingException(
      '이미지가 너무 큽니다. ${AppConstants.maxImageSizeBytes ~/ (1024 * 1024)}MB 이하의 이미지를 선택해주세요.',
    );
  }
}
