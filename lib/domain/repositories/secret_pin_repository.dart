/// 비밀일기 PIN 저장소 인터페이스 (Domain Layer)
abstract class SecretPinRepository {
  /// PIN이 설정되어 있는지 확인
  Future<bool> hasPin();

  /// PIN 설정 (구현체에서 SHA-256 해싱 처리)
  Future<void> setPin(String rawPin);

  /// PIN 검증 (rawPin을 해싱 후 저장된 해시와 비교)
  Future<bool> verifyPin(String rawPin);

  /// PIN 초기화
  Future<void> deletePin();
}
