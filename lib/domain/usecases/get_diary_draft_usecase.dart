import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/clock.dart';
import '../entities/diary_draft.dart';
import '../repositories/diary_draft_repository.dart';

/// 일기 임시저장(초안) 조회 유스케이스
///
/// 저장된 초안을 조회하며, TTL(7일)이 만료된 경우 초안을 삭제하고 null을 반환합니다.
class GetDiaryDraftUseCase {
  final DiaryDraftRepository _repository;
  final Clock _clock;

  GetDiaryDraftUseCase(
    this._repository, {
    Clock clock = const SystemClock(),
  }) : _clock = clock;

  Future<DiaryDraft?> execute() async {
    try {
      final draft = await _repository.getDraft();
      if (draft == null) {
        return null;
      }

      if (draft.isExpired(_clock.now(), AppConstants.diaryDraftTtl)) {
        await _repository.clearDraft();
        return null;
      }

      return draft;
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }
}
