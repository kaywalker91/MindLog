import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/clock.dart';
import '../entities/diary_draft.dart';
import '../repositories/diary_draft_repository.dart';

/// 일기 임시저장(초안) 저장 유스케이스
///
/// 작성 중인 일기 내용과 첨부 이미지를 임시저장합니다.
/// - 본문과 이미지가 모두 비어있으면 기존 초안을 삭제하고 저장하지 않습니다.
/// - 최소 글자 수 제한은 적용하지 않으며, 최대 글자 수 초과 시 [ValidationFailure]를 던집니다.
class SaveDiaryDraftUseCase {
  final DiaryDraftRepository _repository;
  final Clock _clock;

  SaveDiaryDraftUseCase(this._repository, {Clock clock = const SystemClock()})
    : _clock = clock;

  Future<void> execute(
    String content, {
    required DateTime entryDate,
    List<String>? imagePaths,
  }) async {
    final trimmedContent = content.trim();
    final normalizedImagePaths = (imagePaths != null && imagePaths.isNotEmpty)
        ? imagePaths
        : null;

    if (trimmedContent.isEmpty && normalizedImagePaths == null) {
      try {
        await _repository.clearDraft();
        return;
      } on Failure {
        rethrow;
      } catch (e) {
        throw UnknownFailure(message: e.toString());
      }
    }

    if (trimmedContent.length > AppConstants.diaryMaxLength) {
      throw ValidationFailure(
        message: '최대 ${AppConstants.diaryMaxLength}자까지 입력 가능합니다.',
      );
    }

    try {
      final draft = DiaryDraft(
        content: trimmedContent,
        entryDate: entryDate,
        updatedAt: _clock.now(),
        imagePaths: normalizedImagePaths,
      );
      await _repository.saveDraft(draft);
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }
}
