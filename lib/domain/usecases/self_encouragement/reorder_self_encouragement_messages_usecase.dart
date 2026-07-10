import '../../../core/errors/failures.dart';
import '../../repositories/settings_repository.dart';

/// 개인 응원 메시지 순서 변경 UseCase
class ReorderSelfEncouragementMessagesUseCase {
  final SettingsRepository _repository;

  ReorderSelfEncouragementMessagesUseCase(this._repository);

  /// 메시지 순서 변경
  ///
  /// [orderedIds] 는 변경된 표시 순서대로의 메시지 ID 목록.
  ///
  /// Throws:
  /// - [ValidationFailure] 빈 순서 목록
  /// - [CacheFailure] 로컬 저장소 쓰기 실패
  /// - [UnknownFailure] 예기치 않은 오류
  Future<void> execute(List<String> orderedIds) async {
    if (orderedIds.isEmpty) {
      throw const ValidationFailure(message: '정렬할 메시지가 없습니다');
    }

    try {
      await _repository.reorderSelfEncouragementMessages(orderedIds);
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }
}
