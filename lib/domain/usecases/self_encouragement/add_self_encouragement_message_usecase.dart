import '../../entities/self_encouragement_message.dart';
import '../../repositories/settings_repository.dart';
import '../../../core/errors/failures.dart';

/// 개인 응원 메시지 추가 UseCase
class AddSelfEncouragementMessageUseCase {
  final SettingsRepository _repository;

  AddSelfEncouragementMessageUseCase(this._repository);

  /// 새 메시지 추가
  ///
  /// - 빈 메시지 불가
  /// - 최대 글자 수 초과 불가 (100자)
  /// - 최대 메시지 개수 초과 불가 (10개)
  Future<void> execute(SelfEncouragementMessage message) async {
    // 유효성 검사: 빈 내용
    if (message.content.trim().isEmpty) {
      throw const ValidationFailure(message: '메시지 내용을 입력해주세요');
    }

    // 유효성 검사: 최대 글자 수
    if (message.content.length > SelfEncouragementMessage.maxContentLength) {
      throw const ValidationFailure(message: '메시지는 100자 이내로 작성해주세요');
    }

    // 기존 메시지 개수 확인
    final existingMessages = await _repository.getSelfEncouragementMessages();
    if (existingMessages.length >= SelfEncouragementMessage.maxMessageCount) {
      throw const ValidationFailure(message: '최대 10개까지만 등록할 수 있습니다');
    }

    await _repository.addSelfEncouragementMessage(message);
  }
}
