import '../../../core/errors/failures.dart';
import '../../repositories/diary_repository.dart';

/// 일기 비밀 설정/해제 유스케이스
class SetDiarySecretUseCase {
  final DiaryRepository _repository;

  SetDiarySecretUseCase(this._repository);

  Future<void> execute(String diaryId, {required bool isSecret}) async {
    if (diaryId.isEmpty) {
      throw const ValidationFailure(message: '일기 ID가 유효하지 않습니다.');
    }
    try {
      await _repository.setDiarySecret(diaryId, isSecret);
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }
}
