import '../../entities/self_encouragement_message.dart';
import '../../repositories/settings_repository.dart';
import '../../../core/errors/failures.dart';

/// 저장된 개인 응원 메시지 목록 조회 UseCase
class GetSelfEncouragementMessagesUseCase {
  final SettingsRepository _repository;

  GetSelfEncouragementMessagesUseCase(this._repository);

  /// 저장된 모든 개인 응원 메시지를 displayOrder 순으로 조회
  ///
  /// Throws:
  /// - [CacheFailure] 로컬 저장소 읽기 실패
  /// - [UnknownFailure] 예기치 않은 오류
  Future<List<SelfEncouragementMessage>> execute() async {
    try {
      final messages = await _repository.getSelfEncouragementMessages();
      // displayOrder 순으로 정렬
      messages.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return messages;
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }
}
