import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';

/// 일기 내용 유효성 검사 결과
class DiaryValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String sanitizedContent;

  const DiaryValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.sanitizedContent,
  });

  factory DiaryValidationResult.valid(String content) => DiaryValidationResult(
        isValid: true,
        sanitizedContent: content.trim(),
      );

  factory DiaryValidationResult.invalid(String message) => DiaryValidationResult(
        isValid: false,
        errorMessage: message,
        sanitizedContent: '',
      );
}

/// 일기 내용 유효성 검사 유스케이스
///
/// Single Responsibility: 입력 유효성 검사만 담당
/// - 빈 내용 체크
/// - 최소/최대 길이 검증
/// - 입력값 정제 (trim)
class ValidateDiaryContentUseCase {
  /// 일기 내용 유효성 검사 실행
  ///
  /// [content] 검사할 일기 내용
  ///
  /// 반환값: [DiaryValidationResult] 유효성 검사 결과
  ///
  /// 유효하지 않은 경우 [ValidationFailure]를 throw
  DiaryValidationResult execute(String content) {
    final trimmedContent = content.trim();

    // 빈 내용 체크
    if (trimmedContent.isEmpty) {
      throw const ValidationFailure(message: '일기 내용을 입력해주세요.');
    }

    final minLength = AppConstants.diaryMinLength;
    final maxLength = AppConstants.diaryMaxLength;

    // 최소 길이 체크
    if (trimmedContent.length < minLength) {
      throw ValidationFailure(message: '최소 $minLength자 이상 입력해주세요.');
    }

    // 최대 길이 체크
    if (trimmedContent.length > maxLength) {
      throw ValidationFailure(message: '최대 $maxLength자까지 입력 가능합니다.');
    }

    return DiaryValidationResult.valid(trimmedContent);
  }

  /// 유효성 검사만 수행 (예외를 던지지 않음)
  ///
  /// UI에서 실시간 유효성 피드백에 사용
  DiaryValidationResult validate(String content) {
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      return DiaryValidationResult.invalid('일기 내용을 입력해주세요.');
    }

    final minLength = AppConstants.diaryMinLength;
    final maxLength = AppConstants.diaryMaxLength;

    if (trimmedContent.length < minLength) {
      return DiaryValidationResult.invalid('최소 $minLength자 이상 입력해주세요.');
    }

    if (trimmedContent.length > maxLength) {
      return DiaryValidationResult.invalid('최대 $maxLength자까지 입력 가능합니다.');
    }

    return DiaryValidationResult.valid(trimmedContent);
  }
}
