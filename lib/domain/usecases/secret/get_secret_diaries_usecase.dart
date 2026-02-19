import '../../../core/errors/failures.dart';
import '../../entities/diary.dart';
import '../../repositories/diary_repository.dart';

/// 비밀일기 목록 조회 유스케이스
class GetSecretDiariesUseCase {
  final DiaryRepository _repository;

  GetSecretDiariesUseCase(this._repository);

  Future<List<Diary>> execute() async {
    try {
      return await _repository.getSecretDiaries();
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }
}
