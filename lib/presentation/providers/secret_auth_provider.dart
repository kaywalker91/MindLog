import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/domain/usecases/secret/verify_secret_pin_usecase.dart';

/// 비밀일기 인증 상태 — in-memory (앱 재시작 시 항상 false)
class SecretAuthNotifier extends StateNotifier<bool> {
  SecretAuthNotifier() : super(false);

  /// PIN 검증 후 잠금 해제. 성공 시 true 반환.
  Future<bool> unlock(String pin, VerifySecretPinUseCase verifyUseCase) async {
    final result = await verifyUseCase.execute(pin);
    if (result) state = true;
    return result;
  }

  /// 비밀일기 잠금 (명시적 잠금 또는 앱 비활성화 시 호출)
  void lock() => state = false;
}

/// 비밀일기 인증 상태 Provider
final secretAuthProvider = StateNotifierProvider<SecretAuthNotifier, bool>(
  (ref) => SecretAuthNotifier(),
);
