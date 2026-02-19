import '../../../core/errors/failures.dart';
import '../../repositories/secret_pin_repository.dart';

/// 비밀일기 PIN 검증 유스케이스
///
/// 반환값: true → 인증 성공, false → 인증 실패(PIN 불일치 또는 미설정)
class VerifySecretPinUseCase {
  final SecretPinRepository _repository;

  VerifySecretPinUseCase(this._repository);

  Future<bool> execute(String pin) async {
    _validatePin(pin);
    try {
      return await _repository.verifyPin(pin);
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
