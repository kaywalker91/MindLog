import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/prompt_constants.dart';

void main() {
  group('PromptConstants.createAnalysisPromptWithImages', () {
    test('첨부 1장이면 대표 사진 안내를 생략해야 한다', () {
      final prompt = PromptConstants.createAnalysisPromptWithImages(
        '오늘 산책했다',
        attachedImageCount: 1,
        analyzedImageCount: 1,
      );

      expect(prompt, contains('1장의 사진을 첨부'));
      expect(prompt, isNot(contains('대표 사진')));
    });

    test('첨부 2장 이상이면 대표 1장 반영 안내를 포함해야 한다', () {
      final prompt = PromptConstants.createAnalysisPromptWithImages(
        '오늘 산책했다',
        attachedImageCount: 3,
        analyzedImageCount: 1,
      );

      expect(prompt, contains('3장의 사진을 첨부'));
      expect(prompt, contains('대표 사진 1장만 반영'));
    });
  });
}
