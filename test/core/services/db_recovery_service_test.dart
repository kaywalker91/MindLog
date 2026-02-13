import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindlog/core/services/db_recovery_service.dart';
import 'package:mindlog/data/datasources/local/sqlite_local_datasource.dart';

/// Mock SqliteLocalDataSource for testing
///
/// getMetadata/setMetadata를 인메모리 Map으로 구현합니다.
/// DB 연결 없이 DbRecoveryService의 세션 ID 로직을 테스트할 수 있습니다.
class MockSqliteLocalDataSource extends SqliteLocalDataSource {
  final Map<String, String> _metadata = {};
  bool shouldThrowOnGet = false;
  bool shouldThrowOnSet = false;
  int getMetadataCallCount = 0;
  int setMetadataCallCount = 0;

  @override
  Future<String?> getMetadata(String key) async {
    getMetadataCallCount++;
    if (shouldThrowOnGet) throw Exception('Mock getMetadata error');
    return _metadata[key];
  }

  @override
  Future<void> setMetadata(String key, String value) async {
    setMetadataCallCount++;
    if (shouldThrowOnSet) throw Exception('Mock setMetadata error');
    _metadata[key] = value;
  }

  /// 테스트 헬퍼: 메타데이터 직접 설정
  void putMetadata(String key, String value) {
    _metadata[key] = value;
  }

  /// 테스트 헬퍼: 저장된 메타데이터 조회
  String? getStoredMetadata(String key) {
    return _metadata[key];
  }
}

void main() {
  late MockSqliteLocalDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockSqliteLocalDataSource();
    DbRecoveryService.resetForTesting();
  });

  group('DbRecoveryService', () {
    // ============================================================
    // 케이스 1: 신규 설치 (둘 다 null)
    // ============================================================
    group('케이스 1: 신규 설치', () {
      test('Prefs와 DB 모두 null이면 세션을 초기화하고 false를 반환한다', () async {
        SharedPreferences.setMockInitialValues({});

        final result = await DbRecoveryService.checkAndRecoverIfNeeded(
          mockDataSource,
        );

        expect(result, isFalse);
        // 세션 ID가 Prefs에 저장됨
        final prefs = await SharedPreferences.getInstance();
        final prefsSession = prefs.getString('db_session_id');
        expect(prefsSession, isNotNull);
        expect(prefsSession!.length, equals(32)); // 16 bytes hex = 32 chars

        // 세션 ID가 DB에도 저장됨
        final dbSession = mockDataSource.getStoredMetadata('db_session_id');
        expect(dbSession, isNotNull);
        expect(dbSession, equals(prefsSession));
      });

      test('setMetadata가 호출된다', () async {
        SharedPreferences.setMockInitialValues({});

        await DbRecoveryService.checkAndRecoverIfNeeded(mockDataSource);

        expect(mockDataSource.setMetadataCallCount, equals(1));
      });
    });

    // ============================================================
    // 케이스 2: DB 복원됨 (Prefs만 있음)
    // ============================================================
    group('케이스 2: DB 복원 (Prefs만 존재)', () {
      test('Prefs만 있고 DB가 비어있으면 true를 반환한다', () async {
        SharedPreferences.setMockInitialValues({
          'db_session_id': 'old_prefs_session_id',
        });
        // DB에는 메타데이터 없음 (복원된 빈 DB)

        final result = await DbRecoveryService.checkAndRecoverIfNeeded(
          mockDataSource,
        );

        expect(result, isTrue);
      });

      test('복원 후 새 세션 ID가 양쪽에 저장된다', () async {
        SharedPreferences.setMockInitialValues({
          'db_session_id': 'old_prefs_session_id',
        });

        await DbRecoveryService.checkAndRecoverIfNeeded(mockDataSource);

        final prefs = await SharedPreferences.getInstance();
        final newPrefsSession = prefs.getString('db_session_id');
        final newDbSession = mockDataSource.getStoredMetadata('db_session_id');

        expect(newPrefsSession, isNotNull);
        expect(newDbSession, isNotNull);
        expect(newPrefsSession, equals(newDbSession));
        // 이전 ID와 다름
        expect(newPrefsSession, isNot(equals('old_prefs_session_id')));
      });
    });

    // ============================================================
    // 케이스 3: Prefs 초기화됨 (DB만 있음)
    // ============================================================
    group('케이스 3: Prefs 초기화 (DB만 존재)', () {
      test('DB만 있고 Prefs가 비어있으면 true를 반환한다', () async {
        SharedPreferences.setMockInitialValues({});
        mockDataSource.putMetadata('db_session_id', 'old_db_session_id');

        final result = await DbRecoveryService.checkAndRecoverIfNeeded(
          mockDataSource,
        );

        expect(result, isTrue);
      });

      test('복원 후 새 세션 ID가 양쪽에 저장된다', () async {
        SharedPreferences.setMockInitialValues({});
        mockDataSource.putMetadata('db_session_id', 'old_db_session_id');

        await DbRecoveryService.checkAndRecoverIfNeeded(mockDataSource);

        final prefs = await SharedPreferences.getInstance();
        final newPrefsSession = prefs.getString('db_session_id');
        final newDbSession = mockDataSource.getStoredMetadata('db_session_id');

        expect(newPrefsSession, isNotNull);
        expect(newDbSession, isNotNull);
        expect(newPrefsSession, equals(newDbSession));
        expect(newDbSession, isNot(equals('old_db_session_id')));
      });
    });

    // ============================================================
    // 케이스 4: 세션 불일치
    // ============================================================
    group('케이스 4: 세션 불일치', () {
      test('Prefs와 DB의 세션 ID가 다르면 true를 반환한다', () async {
        SharedPreferences.setMockInitialValues({
          'db_session_id': 'prefs_session_abc',
        });
        mockDataSource.putMetadata('db_session_id', 'db_session_xyz');

        final result = await DbRecoveryService.checkAndRecoverIfNeeded(
          mockDataSource,
        );

        expect(result, isTrue);
      });

      test('불일치 후 새 세션 ID로 동기화된다', () async {
        SharedPreferences.setMockInitialValues({
          'db_session_id': 'prefs_session_abc',
        });
        mockDataSource.putMetadata('db_session_id', 'db_session_xyz');

        await DbRecoveryService.checkAndRecoverIfNeeded(mockDataSource);

        final prefs = await SharedPreferences.getInstance();
        final newPrefsSession = prefs.getString('db_session_id');
        final newDbSession = mockDataSource.getStoredMetadata('db_session_id');

        expect(newPrefsSession, equals(newDbSession));
        expect(newPrefsSession, isNot(equals('prefs_session_abc')));
        expect(newDbSession, isNot(equals('db_session_xyz')));
      });
    });

    // ============================================================
    // 케이스 5: 정상 (세션 일치)
    // ============================================================
    group('케이스 5: 정상 동작', () {
      test('Prefs와 DB의 세션 ID가 같으면 false를 반환한다', () async {
        const sessionId = 'matching_session_id_12345678';
        SharedPreferences.setMockInitialValues({'db_session_id': sessionId});
        mockDataSource.putMetadata('db_session_id', sessionId);

        final result = await DbRecoveryService.checkAndRecoverIfNeeded(
          mockDataSource,
        );

        expect(result, isFalse);
      });

      test('정상 시 세션 ID를 변경하지 않는다', () async {
        const sessionId = 'matching_session_id_12345678';
        SharedPreferences.setMockInitialValues({'db_session_id': sessionId});
        mockDataSource.putMetadata('db_session_id', sessionId);

        await DbRecoveryService.checkAndRecoverIfNeeded(mockDataSource);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('db_session_id'), equals(sessionId));
        expect(
          mockDataSource.getStoredMetadata('db_session_id'),
          equals(sessionId),
        );
        // setMetadata는 호출되지 않음
        expect(mockDataSource.setMetadataCallCount, equals(0));
      });
    });

    // ============================================================
    // _checked 가드 (중복 실행 방지)
    // ============================================================
    group('중복 실행 방지', () {
      test('두 번째 호출은 즉시 false를 반환한다', () async {
        SharedPreferences.setMockInitialValues({});

        // 첫 번째 호출
        await DbRecoveryService.checkAndRecoverIfNeeded(mockDataSource);
        final firstCallCount = mockDataSource.getMetadataCallCount;

        // 두 번째 호출 - _checked가 true이므로 즉시 false
        final result = await DbRecoveryService.checkAndRecoverIfNeeded(
          mockDataSource,
        );

        expect(result, isFalse);
        // getMetadata 추가 호출 없음
        expect(mockDataSource.getMetadataCallCount, equals(firstCallCount));
      });

      test('resetForTesting 후 다시 실행 가능하다', () async {
        SharedPreferences.setMockInitialValues({});

        await DbRecoveryService.checkAndRecoverIfNeeded(mockDataSource);
        DbRecoveryService.resetForTesting();

        // 새 mock으로 리셋 후 재실행
        final newMock = MockSqliteLocalDataSource();
        SharedPreferences.setMockInitialValues({});

        await DbRecoveryService.checkAndRecoverIfNeeded(newMock);
        expect(newMock.getMetadataCallCount, equals(1));
      });
    });

    // ============================================================
    // 에러 핸들링
    // ============================================================
    group('에러 핸들링', () {
      test('getMetadata 에러 시 false를 반환한다 (안전 모드)', () async {
        SharedPreferences.setMockInitialValues({});
        mockDataSource.shouldThrowOnGet = true;

        final result = await DbRecoveryService.checkAndRecoverIfNeeded(
          mockDataSource,
        );

        expect(result, isFalse);
      });

      test('setMetadata 에러 시에도 false를 반환한다', () async {
        SharedPreferences.setMockInitialValues({});
        mockDataSource.shouldThrowOnSet = true;

        final result = await DbRecoveryService.checkAndRecoverIfNeeded(
          mockDataSource,
        );

        // 신규 설치 경로 → setMetadata 에러 → catch → false
        expect(result, isFalse);
      });
    });

    // ============================================================
    // 세션 ID 생성
    // ============================================================
    group('세션 ID 생성', () {
      test('생성된 세션 ID는 32자 hex 문자열이다', () async {
        SharedPreferences.setMockInitialValues({});

        await DbRecoveryService.checkAndRecoverIfNeeded(mockDataSource);

        final sessionId = mockDataSource.getStoredMetadata('db_session_id');
        expect(sessionId, isNotNull);
        expect(sessionId!.length, equals(32));
        // hex 문자만 포함
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(sessionId), isTrue);
      });

      test('매 호출마다 고유한 세션 ID를 생성한다', () async {
        // 첫 번째 호출
        SharedPreferences.setMockInitialValues({});
        await DbRecoveryService.checkAndRecoverIfNeeded(mockDataSource);
        final firstId = mockDataSource.getStoredMetadata('db_session_id');

        // 리셋 후 두 번째 호출
        DbRecoveryService.resetForTesting();
        final newMock = MockSqliteLocalDataSource();
        SharedPreferences.setMockInitialValues({});
        await DbRecoveryService.checkAndRecoverIfNeeded(newMock);
        final secondId = newMock.getStoredMetadata('db_session_id');

        expect(firstId, isNot(equals(secondId)));
      });
    });
  });
}
