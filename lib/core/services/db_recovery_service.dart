import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local/sqlite_local_datasource.dart';

/// DB 복원 감지 및 복구 서비스
///
/// 앱 재설치 시 OS가 백업에서 DB 파일을 복원하면,
/// SharedPreferences와 DB의 세션 ID가 불일치합니다.
/// 이를 감지하여 DB 연결을 리셋하고 Provider 캐시를 무효화합니다.
///
/// 동작 원리:
/// 1. SharedPreferences에 세션 ID 저장 (앱 설치마다 새로 생성)
/// 2. DB app_metadata 테이블에도 세션 ID 저장
/// 3. 앱 시작 시 두 값 비교
/// 4. 불일치 → DB 복원으로 판단 → 강제 리셋
class DbRecoveryService {
  DbRecoveryService._();

  static const String _sessionIdKey = 'db_session_id';
  static bool _checked = false;

  /// DB 복원 여부 확인 및 처리
  ///
  /// 반환값: true면 복원이 감지되어 리셋됨, false면 정상
  static Future<bool> checkAndRecoverIfNeeded(
    SqliteLocalDataSource dataSource,
  ) async {
    if (_checked) return false;
    _checked = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsSessionId = prefs.getString(_sessionIdKey);
      final dbSessionId = await dataSource.getMetadata(_sessionIdKey);

      if (kDebugMode) {
        debugPrint('[DbRecoveryService] Prefs session: $prefsSessionId');
        debugPrint('[DbRecoveryService] DB session: $dbSessionId');
      }

      // 케이스 1: 둘 다 없음 → 신규 설치
      if (prefsSessionId == null && dbSessionId == null) {
        await _initializeSession(prefs, dataSource);
        if (kDebugMode) {
          debugPrint('[DbRecoveryService] New install detected, session initialized');
        }
        return false;
      }

      // 케이스 2: Prefs만 있음 → DB가 복원됨 (이전 앱의 DB 없이 복원)
      if (prefsSessionId != null && dbSessionId == null) {
        await _handleRecovery(prefs, dataSource);
        if (kDebugMode) {
          debugPrint('[DbRecoveryService] DB restored (empty), session reinitialized');
        }
        return true;
      }

      // 케이스 3: DB만 있음 → Prefs가 초기화됨 (앱 재설치 후 DB 복원)
      if (prefsSessionId == null && dbSessionId != null) {
        await _handleRecovery(prefs, dataSource);
        if (kDebugMode) {
          debugPrint('[DbRecoveryService] Prefs cleared, DB restored - recovery triggered');
        }
        return true;
      }

      // 케이스 4: 둘 다 있지만 불일치 → 복원 감지
      if (prefsSessionId != dbSessionId) {
        await _handleRecovery(prefs, dataSource);
        if (kDebugMode) {
          debugPrint('[DbRecoveryService] Session mismatch - recovery triggered');
        }
        return true;
      }

      // 케이스 5: 일치 → 정상
      if (kDebugMode) {
        debugPrint('[DbRecoveryService] Session matched, no recovery needed');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DbRecoveryService] Error during check: $e');
      }
      // 에러 발생 시 안전하게 진행 (복원 처리 안 함)
      return false;
    }
  }

  /// 세션 초기화 (신규 설치)
  static Future<void> _initializeSession(
    SharedPreferences prefs,
    SqliteLocalDataSource dataSource,
  ) async {
    final newSessionId = _generateSessionId();
    await prefs.setString(_sessionIdKey, newSessionId);
    await dataSource.setMetadata(_sessionIdKey, newSessionId);
  }

  /// 복원 처리: DB 리셋 + 세션 재초기화
  static Future<void> _handleRecovery(
    SharedPreferences prefs,
    SqliteLocalDataSource dataSource,
  ) async {
    // DB 연결 강제 리셋
    await SqliteLocalDataSource.forceReconnect();

    // 새 세션 ID 생성 및 저장
    final newSessionId = _generateSessionId();
    await prefs.setString(_sessionIdKey, newSessionId);
    await dataSource.setMetadata(_sessionIdKey, newSessionId);
  }

  /// 세션 ID 생성 (uuid 패키지 없이 구현)
  static String _generateSessionId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 테스트용: 체크 상태 리셋
  @visibleForTesting
  static void resetForTesting() {
    _checked = false;
  }
}
