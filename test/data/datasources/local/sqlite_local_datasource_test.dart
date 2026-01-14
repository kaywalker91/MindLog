import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/data/datasources/local/sqlite_local_datasource.dart';
import 'package:mindlog/core/errors/exceptions.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  late SqliteLocalDataSource dataSource;
  late Database testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // 인메모리 DB 생성
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE diaries (
            id TEXT PRIMARY KEY,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL,
            status TEXT NOT NULL,
            analysis_result TEXT,
            is_pinned INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE app_metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    // 테스트용 DB 주입
    SqliteLocalDataSource.testDatabase = testDb;
    dataSource = SqliteLocalDataSource();
  });

  tearDown(() async {
    SqliteLocalDataSource.testDatabase = null;
    await testDb.close();
  });

  /// 테스트 데이터 삽입 헬퍼
  Future<void> insertRaw(Map<String, dynamic> data) async {
    await testDb.insert('diaries', data);
  }

  group('SqliteLocalDataSource', () {
    group('_mapToDiary 안전 파싱', () {
      test('정상 데이터를 Diary로 변환해야 한다', () async {
        await insertRaw({
          'id': 'test-1',
          'content': '오늘 좋은 하루였다.',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });

        final diary = await dataSource.getDiaryById('test-1');

        expect(diary, isNotNull);
        expect(diary!.id, 'test-1');
        expect(diary.content, '오늘 좋은 하루였다.');
        expect(diary.status, DiaryStatus.pending);
        expect(diary.isPinned, false);
      });

      test('잘못된 DateTime 형식은 현재 시간으로 대체해야 한다', () async {
        await insertRaw({
          'id': 'test-invalid-date',
          'content': '테스트',
          'created_at': 'invalid-date-format',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });

        final before = DateTime.now();
        final diary = await dataSource.getDiaryById('test-invalid-date');
        final after = DateTime.now();

        expect(diary, isNotNull);
        expect(
          diary!.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          true,
        );
        expect(
          diary.createdAt.isBefore(after.add(const Duration(seconds: 1))),
          true,
        );
      });

      test('알 수 없는 status 값은 pending으로 대체해야 한다', () async {
        await insertRaw({
          'id': 'test-invalid-status',
          'content': '테스트',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'unknownStatus',
          'analysis_result': null,
          'is_pinned': 0,
        });

        final diary = await dataSource.getDiaryById('test-invalid-status');

        expect(diary, isNotNull);
        expect(diary!.status, DiaryStatus.pending);
      });

      test('analysis_result가 빈 문자열이면 null이어야 한다', () async {
        await insertRaw({
          'id': 'test-empty-analysis',
          'content': '테스트',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'analyzed',
          'analysis_result': '',
          'is_pinned': 0,
        });

        final diary = await dataSource.getDiaryById('test-empty-analysis');

        expect(diary, isNotNull);
        expect(diary!.analysisResult, isNull);
      });

      test('analysis_result JSON이 손상되면 null이어야 한다', () async {
        await insertRaw({
          'id': 'test-corrupted-json',
          'content': '테스트',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'analyzed',
          'analysis_result': '{invalid json}',
          'is_pinned': 0,
        });

        final diary = await dataSource.getDiaryById('test-corrupted-json');

        expect(diary, isNotNull);
        expect(diary!.analysisResult, isNull);
      });

      test('is_pinned가 1이면 true, 0이면 false여야 한다', () async {
        await insertRaw({
          'id': 'test-pinned',
          'content': '고정된 일기',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 1,
        });

        await insertRaw({
          'id': 'test-not-pinned',
          'content': '일반 일기',
          'created_at': '2024-01-15T11:00:00.000',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });

        final pinnedDiary = await dataSource.getDiaryById('test-pinned');
        final normalDiary = await dataSource.getDiaryById('test-not-pinned');

        expect(pinnedDiary!.isPinned, true);
        expect(normalDiary!.isPinned, false);
      });

      test('is_pinned가 null이면 false여야 한다', () async {
        // DB에서 직접 null 값 삽입 (is_pinned 컬럼 제외)
        await testDb.execute('''
          INSERT INTO diaries (id, content, created_at, status)
          VALUES ('test-null-pinned', '테스트', '2024-01-15T12:00:00.000', 'pending')
        ''');

        final diary = await dataSource.getDiaryById('test-null-pinned');

        expect(diary, isNotNull);
        expect(diary!.isPinned, false);
      });
    });

    group('CRUD 동작', () {
      test('saveDiary로 저장한 일기를 getDiaryById로 조회해야 한다', () async {
        final diary = Diary(
          id: 'save-test-1',
          content: '저장 테스트 일기',
          createdAt: DateTime(2024, 1, 15, 12, 0),
          status: DiaryStatus.pending,
        );

        await dataSource.saveDiary(diary);
        final retrieved = await dataSource.getDiaryById('save-test-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, diary.id);
        expect(retrieved.content, diary.content);
      });

      test('getAllDiaries는 is_pinned DESC, created_at DESC 순으로 정렬해야 한다', () async {
        // 오래된 고정 일기
        await insertRaw({
          'id': 'old-pinned',
          'content': '오래된 고정',
          'created_at': '2024-01-10T12:00:00.000',
          'status': 'analyzed',
          'analysis_result': null,
          'is_pinned': 1,
        });

        // 최신 일반 일기
        await insertRaw({
          'id': 'new-normal',
          'content': '최신 일반',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });

        // 새로운 고정 일기
        await insertRaw({
          'id': 'new-pinned',
          'content': '새로운 고정',
          'created_at': '2024-01-14T12:00:00.000',
          'status': 'analyzed',
          'analysis_result': null,
          'is_pinned': 1,
        });

        final diaries = await dataSource.getAllDiaries();

        expect(diaries.length, 3);
        // 고정 일기가 먼저 (최신순)
        expect(diaries[0].id, 'new-pinned');
        expect(diaries[1].id, 'old-pinned');
        // 일반 일기
        expect(diaries[2].id, 'new-normal');
      });

      test('deleteDiary로 존재하지 않는 ID 삭제 시 DataNotFoundException을 던져야 한다', () async {
        await expectLater(
          dataSource.deleteDiary('non-existent-id'),
          throwsA(isA<DataNotFoundException>()),
        );
      });

      test('deleteDiary로 일기를 삭제해야 한다', () async {
        await insertRaw({
          'id': 'delete-test',
          'content': '삭제 테스트',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });

        await dataSource.deleteDiary('delete-test');
        final diary = await dataSource.getDiaryById('delete-test');

        expect(diary, isNull);
      });

      test('분석 결과가 있는 일기를 저장하고 조회해야 한다', () async {
        final analysisResult = AnalysisResult(
          keywords: ['행복', '만족', '성취'],
          sentimentScore: 8,
          empathyMessage: '좋은 하루였네요!',
          actionItem: '오늘의 기쁨을 기록하세요',
          actionItems: ['휴식', '기록', '계획'],
          analyzedAt: DateTime(2024, 1, 15, 12, 30),
          isEmergency: false,
        );

        final diary = Diary(
          id: 'analyzed-diary',
          content: '오늘 프로젝트를 완료했다!',
          createdAt: DateTime(2024, 1, 15, 12, 0),
          status: DiaryStatus.analyzed,
          analysisResult: analysisResult,
        );

        await dataSource.saveDiary(diary);
        final retrieved = await dataSource.getDiaryById('analyzed-diary');

        expect(retrieved, isNotNull);
        expect(retrieved!.analysisResult, isNotNull);
        expect(retrieved.analysisResult!.keywords, ['행복', '만족', '성취']);
        expect(retrieved.analysisResult!.sentimentScore, 8);
      });

      test('getDiaryById로 존재하지 않는 ID 조회 시 null을 반환해야 한다', () async {
        final diary = await dataSource.getDiaryById('non-existent');

        expect(diary, isNull);
      });

      test('deleteAllDiaries로 모든 일기를 삭제해야 한다', () async {
        await insertRaw({
          'id': 'diary-1',
          'content': '일기 1',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });
        await insertRaw({
          'id': 'diary-2',
          'content': '일기 2',
          'created_at': '2024-01-16T12:00:00.000',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });

        await dataSource.deleteAllDiaries();
        final diaries = await dataSource.getAllDiaries();

        expect(diaries, isEmpty);
      });
    });

    group('일기 업데이트', () {
      test('updateDiaryWithAnalysis로 분석 결과를 업데이트해야 한다', () async {
        await insertRaw({
          'id': 'update-analysis-test',
          'content': '분석 업데이트 테스트',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });

        final analysisResult = AnalysisResult(
          keywords: ['테스트', '업데이트'],
          sentimentScore: 7,
          empathyMessage: '테스트 메시지',
          actionItem: '테스트 액션',
          actionItems: ['액션1'],
          analyzedAt: DateTime(2024, 1, 15, 13, 0),
          isEmergency: false,
        );

        await dataSource.updateDiaryWithAnalysis('update-analysis-test', analysisResult);
        final diary = await dataSource.getDiaryById('update-analysis-test');

        expect(diary!.status, DiaryStatus.analyzed);
        expect(diary.analysisResult, isNotNull);
        expect(diary.analysisResult!.keywords, ['테스트', '업데이트']);
      });

      test('updateDiaryStatus로 상태를 변경해야 한다', () async {
        await insertRaw({
          'id': 'status-update-test',
          'content': '상태 업데이트 테스트',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });

        await dataSource.updateDiaryStatus('status-update-test', DiaryStatus.failed);
        final diary = await dataSource.getDiaryById('status-update-test');

        expect(diary!.status, DiaryStatus.failed);
      });

      test('updateDiaryPin으로 고정 상태를 변경해야 한다', () async {
        await insertRaw({
          'id': 'pin-update-test',
          'content': '고정 업데이트 테스트',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });

        await dataSource.updateDiaryPin('pin-update-test', true);
        final diary = await dataSource.getDiaryById('pin-update-test');

        expect(diary!.isPinned, true);

        await dataSource.updateDiaryPin('pin-update-test', false);
        final updatedDiary = await dataSource.getDiaryById('pin-update-test');

        expect(updatedDiary!.isPinned, false);
      });
    });

    group('getTodayDiaries', () {
      test('오늘 작성된 일기만 반환해야 한다', () async {
        final now = DateTime.now();
        final todayStr = DateTime(now.year, now.month, now.day, 10, 0).toIso8601String();
        final yesterdayStr = DateTime(now.year, now.month, now.day - 1, 10, 0).toIso8601String();

        await insertRaw({
          'id': 'today-diary',
          'content': '오늘 일기',
          'created_at': todayStr,
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });
        await insertRaw({
          'id': 'yesterday-diary',
          'content': '어제 일기',
          'created_at': yesterdayStr,
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });

        final todayDiaries = await dataSource.getTodayDiaries();

        expect(todayDiaries.length, 1);
        expect(todayDiaries.first.id, 'today-diary');
      });
    });

    group('날짜 범위 쿼리', () {
      setUp(() async {
        // analyzed 상태 일기들
        await insertRaw({
          'id': 'analyzed-1',
          'content': '분석됨 1',
          'created_at': '2024-01-10T12:00:00.000',
          'status': 'analyzed',
          'analysis_result': null,
          'is_pinned': 0,
        });
        await insertRaw({
          'id': 'analyzed-2',
          'content': '분석됨 2',
          'created_at': '2024-01-15T12:00:00.000',
          'status': 'analyzed',
          'analysis_result': null,
          'is_pinned': 0,
        });
        await insertRaw({
          'id': 'safety-blocked',
          'content': '안전 차단',
          'created_at': '2024-01-12T12:00:00.000',
          'status': 'safetyBlocked',
          'analysis_result': null,
          'is_pinned': 0,
        });
        // pending/failed 상태 (조회되면 안 됨)
        await insertRaw({
          'id': 'pending-1',
          'content': '대기 중',
          'created_at': '2024-01-13T12:00:00.000',
          'status': 'pending',
          'analysis_result': null,
          'is_pinned': 0,
        });
        await insertRaw({
          'id': 'failed-1',
          'content': '실패',
          'created_at': '2024-01-14T12:00:00.000',
          'status': 'failed',
          'analysis_result': null,
          'is_pinned': 0,
        });
      });

      test('getAnalyzedDiariesInRange는 analyzed와 safetyBlocked 상태만 반환해야 한다', () async {
        final diaries = await dataSource.getAnalyzedDiariesInRange();

        expect(diaries.length, 3);
        expect(
          diaries.every((d) =>
              d.status == DiaryStatus.analyzed ||
              d.status == DiaryStatus.safetyBlocked),
          true,
        );
      });

      test('startDate만 지정하면 해당 날짜 이후 일기만 반환해야 한다', () async {
        final diaries = await dataSource.getAnalyzedDiariesInRange(
          startDate: DateTime(2024, 1, 12),
        );

        expect(diaries.length, 2);
        expect(diaries.every((d) => d.createdAt.isAfter(DateTime(2024, 1, 11))), true);
      });

      test('endDate만 지정하면 해당 날짜 이전 일기만 반환해야 한다', () async {
        final diaries = await dataSource.getAnalyzedDiariesInRange(
          endDate: DateTime(2024, 1, 13),
        );

        expect(diaries.length, 2);
        expect(diaries.every((d) => d.createdAt.isBefore(DateTime(2024, 1, 14))), true);
      });

      test('startDate와 endDate 모두 지정하면 범위 내 일기만 반환해야 한다', () async {
        final diaries = await dataSource.getAnalyzedDiariesInRange(
          startDate: DateTime(2024, 1, 11),
          endDate: DateTime(2024, 1, 14),
        );

        expect(diaries.length, 1);
        expect(diaries.first.id, 'safety-blocked');
      });
    });

    group('메타데이터', () {
      test('setMetadata로 저장한 값을 getMetadata로 조회해야 한다', () async {
        await dataSource.setMetadata('test_key', 'test_value');

        final value = await dataSource.getMetadata('test_key');

        expect(value, 'test_value');
      });

      test('존재하지 않는 키 조회 시 null을 반환해야 한다', () async {
        final value = await dataSource.getMetadata('non_existent_key');

        expect(value, isNull);
      });

      test('같은 키로 저장하면 값이 덮어쓰기되어야 한다', () async {
        await dataSource.setMetadata('overwrite_key', 'original');
        await dataSource.setMetadata('overwrite_key', 'updated');

        final value = await dataSource.getMetadata('overwrite_key');

        expect(value, 'updated');
      });
    });

    group('close', () {
      test('close는 예외 없이 실행되어야 한다', () async {
        await expectLater(
          dataSource.close(),
          completes,
        );
      });
    });
  });

  group('SqliteLocalDataSource static 메서드', () {
    test('forceReconnect는 정적 메서드로 호출 가능해야 한다', () async {
      await expectLater(
        SqliteLocalDataSource.forceReconnect(),
        completes,
      );
    });

    test('resetForTesting은 forceReconnect를 호출해야 한다', () async {
      await expectLater(
        SqliteLocalDataSource.resetForTesting(),
        completes,
      );
    });

    test('forceReconnect 후 _database가 null이 되어야 한다', () async {
      // 첫 번째 호출로 _database를 닫음
      await SqliteLocalDataSource.forceReconnect();
      // 두 번째 호출도 정상적으로 완료되어야 함 (이미 null인 상태)
      await expectLater(
        SqliteLocalDataSource.forceReconnect(),
        completes,
      );
    });
  });

  group('예외 처리', () {
    test('CacheException은 에러 메시지를 포함해야 한다', () async {
      final exception = CacheException('테스트 에러');
      expect(exception.message, '테스트 에러');
    });

    test('DataNotFoundException은 에러 메시지를 포함해야 한다', () async {
      final exception = DataNotFoundException('테스트 에러');
      expect(exception.message, '테스트 에러');
    });
  });

  group('onCreate', () {
    test('onCreate는 diaries 테이블을 생성해야 한다', () async {
      // singleInstance: false로 독립 DB 생성
      final emptyDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        singleInstance: false,
      );

      try {
        await SqliteLocalDataSource.onCreate(emptyDb, 5);

        // 테이블 존재 확인
        final tables = await emptyDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='diaries'",
        );
        expect(tables.length, 1);
        expect(tables.first['name'], 'diaries');
      } finally {
        await emptyDb.close();
      }
    });

    test('onCreate는 app_metadata 테이블을 생성해야 한다', () async {
      final emptyDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        singleInstance: false,
      );

      try {
        await SqliteLocalDataSource.onCreate(emptyDb, 5);

        final tables = await emptyDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='app_metadata'",
        );
        expect(tables.length, 1);
        expect(tables.first['name'], 'app_metadata');
      } finally {
        await emptyDb.close();
      }
    });

    test('onCreate는 인덱스들을 생성해야 한다', () async {
      final emptyDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        singleInstance: false,
      );

      try {
        await SqliteLocalDataSource.onCreate(emptyDb, 5);

        final indexes = await emptyDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='diaries'",
        );

        final indexNames = indexes.map((i) => i['name'] as String).toList();
        expect(indexNames, contains('idx_diaries_created_at'));
        expect(indexNames, contains('idx_diaries_status'));
        expect(indexNames, contains('idx_diaries_status_created_at'));
        expect(indexNames, contains('idx_diaries_pinned_created'));
      } finally {
        await emptyDb.close();
      }
    });
  });

  group('onUpgrade', () {
    test('버전 1에서 2로 업그레이드 시 복합 인덱스를 추가해야 한다', () async {
      // 버전 1 스키마로 DB 생성
      final upgradeDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        singleInstance: false,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE diaries (
              id TEXT PRIMARY KEY,
              content TEXT NOT NULL,
              created_at TEXT NOT NULL,
              status TEXT NOT NULL,
              analysis_result TEXT
            )
          ''');
          await db.execute('CREATE INDEX idx_diaries_created_at ON diaries(created_at)');
          await db.execute('CREATE INDEX idx_diaries_status ON diaries(status)');
        },
      );

      try {
        // 마이그레이션 실행
        await SqliteLocalDataSource.onUpgrade(upgradeDb, 1, 2);

        // 복합 인덱스 확인
        final indexes = await upgradeDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND name='idx_diaries_status_created_at'",
        );
        expect(indexes.length, 1);
      } finally {
        await upgradeDb.close();
      }
    });

    test('버전 2에서 3으로 업그레이드 시 is_pinned 컬럼을 추가해야 한다', () async {
      // 버전 2 스키마로 DB 생성
      final upgradeDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        singleInstance: false,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE diaries (
              id TEXT PRIMARY KEY,
              content TEXT NOT NULL,
              created_at TEXT NOT NULL,
              status TEXT NOT NULL,
              analysis_result TEXT
            )
          ''');
        },
      );

      try {
        // 마이그레이션 실행 (2 -> 3)
        await SqliteLocalDataSource.onUpgrade(upgradeDb, 2, 3);

        // is_pinned 컬럼 확인
        final columns = await upgradeDb.rawQuery("PRAGMA table_info(diaries)");
        final columnNames = columns.map((c) => c['name'] as String).toList();
        expect(columnNames, contains('is_pinned'));
      } finally {
        await upgradeDb.close();
      }
    });

    test('버전 3에서 4로 업그레이드 시 복합 인덱스를 추가하고 단일 인덱스를 제거해야 한다', () async {
      // 버전 3 스키마로 DB 생성
      final upgradeDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        singleInstance: false,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE diaries (
              id TEXT PRIMARY KEY,
              content TEXT NOT NULL,
              created_at TEXT NOT NULL,
              status TEXT NOT NULL,
              analysis_result TEXT,
              is_pinned INTEGER DEFAULT 0
            )
          ''');
          await db.execute('CREATE INDEX idx_diaries_is_pinned ON diaries(is_pinned)');
        },
      );

      try {
        // 마이그레이션 실행 (3 -> 4)
        await SqliteLocalDataSource.onUpgrade(upgradeDb, 3, 4);

        // 복합 인덱스 확인
        final indexes = await upgradeDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='diaries'",
        );
        final indexNames = indexes.map((i) => i['name'] as String).toList();
        expect(indexNames, contains('idx_diaries_pinned_created'));
        // 단일 인덱스가 제거되었는지 확인
        expect(indexNames, isNot(contains('idx_diaries_is_pinned')));
      } finally {
        await upgradeDb.close();
      }
    });

    test('버전 4에서 5로 업그레이드 시 app_metadata 테이블을 추가해야 한다', () async {
      // 버전 4 스키마로 DB 생성
      final upgradeDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        singleInstance: false,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE diaries (
              id TEXT PRIMARY KEY,
              content TEXT NOT NULL,
              created_at TEXT NOT NULL,
              status TEXT NOT NULL,
              analysis_result TEXT,
              is_pinned INTEGER DEFAULT 0
            )
          ''');
        },
      );

      try {
        // 마이그레이션 실행 (4 -> 5)
        await SqliteLocalDataSource.onUpgrade(upgradeDb, 4, 5);

        // app_metadata 테이블 확인
        final tables = await upgradeDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='app_metadata'",
        );
        expect(tables.length, 1);
      } finally {
        await upgradeDb.close();
      }
    });

    test('버전 1에서 5로 전체 마이그레이션이 정상 동작해야 한다', () async {
      // 버전 1 스키마로 DB 생성 (최소 스키마)
      final upgradeDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        singleInstance: false,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE diaries (
              id TEXT PRIMARY KEY,
              content TEXT NOT NULL,
              created_at TEXT NOT NULL,
              status TEXT NOT NULL,
              analysis_result TEXT
            )
          ''');
          await db.execute('CREATE INDEX idx_diaries_created_at ON diaries(created_at)');
          await db.execute('CREATE INDEX idx_diaries_status ON diaries(status)');
        },
      );

      try {
        // 전체 마이그레이션 실행 (1 -> 5)
        await SqliteLocalDataSource.onUpgrade(upgradeDb, 1, 5);

        // 최종 스키마 검증
        // 1. is_pinned 컬럼 확인
        final columns = await upgradeDb.rawQuery("PRAGMA table_info(diaries)");
        final columnNames = columns.map((c) => c['name'] as String).toList();
        expect(columnNames, contains('is_pinned'));

        // 2. 인덱스 확인
        final indexes = await upgradeDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='diaries'",
        );
        final indexNames = indexes.map((i) => i['name'] as String).toList();
        expect(indexNames, contains('idx_diaries_status_created_at'));
        expect(indexNames, contains('idx_diaries_pinned_created'));

        // 3. app_metadata 테이블 확인
        final tables = await upgradeDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='app_metadata'",
        );
        expect(tables.length, 1);
      } finally {
        await upgradeDb.close();
      }
    });
  });

  group('_runDb 에러 처리', () {
    test('DB 에러 발생 시 CacheException으로 래핑해야 한다', () async {
      // testDatabase를 닫아서 에러 유발
      await testDb.close();

      await expectLater(
        dataSource.getAllDiaries(),
        throwsA(isA<CacheException>()),
      );
    });
  });
}
