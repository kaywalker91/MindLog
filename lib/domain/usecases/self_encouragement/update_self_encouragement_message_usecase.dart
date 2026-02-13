import '../../entities/self_encouragement_message.dart';
import '../../repositories/settings_repository.dart';
import '../../../core/errors/failures.dart';

/// 개인 응원 메시지 수정 UseCase
class UpdateSelfEncouragementMessageUseCase {
  final SettingsRepository _repository;

  UpdateSelfEncouragementMessageUseCase(this._repository);

  /// 기존 메시지 수정
  ///
  /// - 빈 메시지 불가
  /// - 최대 글자 수 초과 불가 (100자)
  Future<void> execute(SelfEncouragementMessage message) async {
    // 유효성 검사: 빈 내용
    if (message.content.trim().isEmpty) {
      throw const ValidationFailure(message: '메시지 내용을 입력해주세요');
    }

    // 유효성 검사: 최대 글자 수
    if (message.content.length > SelfEncouragementMessage.maxContentLength) {
      throw const ValidationFailure(message: '메시지는 100자 이내로 작성해주세요');
    }

    await _repository.updateSelfEncouragementMessage(message);
  }
}
