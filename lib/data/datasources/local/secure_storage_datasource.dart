import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 비밀일기 PIN 해시를 SecureStorage에 저장하는 DataSource
class SecureStorageDataSource {
  static const _hashKey = 'mindlog_secret_pin_hash';
  static const _saltKey = 'mindlog_secret_pin_salt';

  final FlutterSecureStorage _storage;

  SecureStorageDataSource({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  /// PIN 해시가 저장되어 있는지 확인
  Future<bool> hasPinHash() async {
    final hash = await _storage.read(key: _hashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// PIN 해시와 salt 저장
  Future<void> setPinHash(String hash, String salt) async {
    await Future.wait([
      _storage.write(key: _hashKey, value: hash),
      _storage.write(key: _saltKey, value: salt),
    ]);
  }

  /// 저장된 PIN 해시와 salt 조회
  Future<({String hash, String salt})?> getPinHashAndSalt() async {
    final results = await Future.wait([
      _storage.read(key: _hashKey),
      _storage.read(key: _saltKey),
    ]);
    final hash = results[0];
    final salt = results[1];
    if (hash == null || salt == null) return null;
    return (hash: hash, salt: salt);
  }

  /// PIN 해시 삭제 (PIN 초기화)
  Future<void> deletePinHash() async {
    await Future.wait([
      _storage.delete(key: _hashKey),
      _storage.delete(key: _saltKey),
    ]);
  }
}
