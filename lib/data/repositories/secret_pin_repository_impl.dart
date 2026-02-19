import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../domain/repositories/secret_pin_repository.dart';
import '../datasources/local/secure_storage_datasource.dart';
import 'repository_failure_handler.dart';

/// 비밀일기 PIN Repository 구현체
///
/// PIN 저장 방식: SHA-256(rawPin + salt)
/// - salt: Random.secure() 32바이트 base64 인코딩
/// - salt와 hash를 별도 키로 SecureStorage에 저장
class SecretPinRepositoryImpl
    with RepositoryFailureHandler
    implements SecretPinRepository {
  final SecureStorageDataSource _storage;

  SecretPinRepositoryImpl({required SecureStorageDataSource storage})
    : _storage = storage;

  @override
  Future<bool> hasPin() {
    return guardFailure('PIN 확인 실패', _storage.hasPinHash);
  }

  @override
  Future<void> setPin(String rawPin) {
    return guardFailure('PIN 설정 실패', () async {
      final salt = _generateSalt();
      final hash = _hashPin(rawPin, salt);
      await _storage.setPinHash(hash, salt);
    });
  }

  @override
  Future<bool> verifyPin(String rawPin) {
    return guardFailure('PIN 검증 실패', () async {
      final stored = await _storage.getPinHashAndSalt();
      if (stored == null) return false;
      final hash = _hashPin(rawPin, stored.salt);
      return hash == stored.hash;
    });
  }

  @override
  Future<void> deletePin() {
    return guardFailure('PIN 초기화 실패', _storage.deletePinHash);
  }

  /// Random.secure() 기반 32바이트 salt 생성
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// SHA-256(rawPin + salt) 해시 생성
  String _hashPin(String rawPin, String salt) {
    final bytes = utf8.encode(rawPin + salt);
    return sha256.convert(bytes).toString();
  }
}
