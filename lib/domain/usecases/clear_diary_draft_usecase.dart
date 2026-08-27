import '../../core/errors/failures.dart';
import '../repositories/diary_draft_repository.dart';

/// 일기 임시저장(초안) 삭제 유스케이스
class ClearDiaryDraftUseCase {
  final DiaryDraftRepository _repository;

  ClearDiaryDraftUseCase(this._repository);

  Future<void> execute() async {
    try {
      await _repository.clearDraft();
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }
}
