import '../../repositories/settings_repository.dart';
import '../../../core/errors/failures.dart';

/// 개인 응원 메시지 삭제 UseCase
class DeleteSelfEncouragementMessageUseCase {
  final SettingsRepository _repository;

  DeleteSelfEncouragementMessageUseCase(this._repository);

  /// 메시지 삭제
  ///
  /// Throws:
  /// - [ValidationFailure] 빈 ID
  /// - [CacheFailure] 로컬 저장소 쓰기 실패
  /// - [UnknownFailure] 예기치 않은 오류
  Future<void> execute(String messageId) async {
    // 유효성 검사: 빈 ID
    if (messageId.trim().isEmpty) {
      throw const ValidationFailure(message: '삭제할 메시지를 찾을 수 없습니다');
    }

    try {
      await _repository.deleteSelfEncouragementMessage(messageId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }
}
