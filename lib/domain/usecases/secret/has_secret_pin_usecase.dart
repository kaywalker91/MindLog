import '../../../core/errors/failures.dart';
import '../../repositories/secret_pin_repository.dart';

/// 비밀일기 PIN 설정 여부 확인 유스케이스
class HasSecretPinUseCase {
  final SecretPinRepository _repository;

  HasSecretPinUseCase(this._repository);

  Future<bool> execute() async {
    try {
      return await _repository.hasPin();
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }
}
