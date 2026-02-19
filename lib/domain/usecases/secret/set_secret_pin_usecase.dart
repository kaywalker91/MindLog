import '../../../core/errors/failures.dart';
import '../../repositories/secret_pin_repository.dart';

/// 비밀일기 PIN 설정 유스케이스
///
/// PIN 유효성: 정확히 4자리 숫자만 허용
class SetSecretPinUseCase {
  final SecretPinRepository _repository;

  SetSecretPinUseCase(this._repository);

  Future<void> execute(String pin) async {
    _validatePin(pin);
    try {
      await _repository.setPin(pin);
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  void _validatePin(String pin) {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      throw const ValidationFailure(message: 'PIN은 4자리 숫자여야 합니다.');
    }
  }
}
