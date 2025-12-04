import '../constants/app_constants.dart';

/// 입력 유효성 검사 유틸리티
class Validators {
  Validators._();

  /// 일기 내용 유효성 검사
  ///
  /// 반환값:
  /// - null: 유효함
  /// - String: 에러 메시지
  static String? validateDiaryContent(String? content) {
    if (content == null || content.trim().isEmpty) {
      return '내용을 입력해주세요.';
    }

    final trimmedContent = content.trim();

    if (trimmedContent.length < AppConstants.diaryMinLength) {
      return '최소 ${AppConstants.diaryMinLength}자 이상 입력해주세요.';
    }

    if (trimmedContent.length > AppConstants.diaryMaxLength) {
      return '최대 ${AppConstants.diaryMaxLength}자까지 입력 가능합니다.';
    }

    return null;
  }

  /// 글자 수 계산
  static int getCharacterCount(String content) {
    return content.trim().length;
  }

  /// 최대 글자 수 도달 여부
  static bool isMaxLengthReached(String content) {
    return content.trim().length >= AppConstants.diaryMaxLength;
  }
}
