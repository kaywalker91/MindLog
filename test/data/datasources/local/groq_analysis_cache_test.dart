import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/data/datasources/local/sqlite_local_datasource.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqliteLocalDataSource dataSource;
  late Database testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // v8 스키마: groq_analysis_cache 테이블 포함
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
            is_pinned INTEGER DEFAULT 0,
            image_paths TEXT,
            is_secret INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE app_metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE groq_analysis_cache (
            cache_key TEXT PRIMARY KEY,
            response_json TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            last_used_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_groq_cache_last_used ON groq_analysis_cache(last_used_at)',
        );
      },
    );
    SqliteLocalDataSource.testDatabase = testDb;
    dataSource = SqliteLocalDataSource();
  });

  tearDown(() async {
    SqliteLocalDataSource.testDatabase = null;
    await testDb.close();
  });

  group('groq_analysis_cache CRUD', () {
    test('miss는 null을 반환해야 한다', () async {
      final result = await dataSource.getGroqCachedResponse('nonexistent_key');
      expect(result, isNull);
    });

    test('put 후 동일 키 get은 저장된 JSON을 반환해야 한다', () async {
      const json = '{"keywords":["기쁨"],"sentiment_score":7}';
      await dataSource.putGroqCachedResponse('key1', json);

      final result = await dataSource.getGroqCachedResponse('key1');
      expect(result, equals(json));
    });

    test('동일 키로 put 시 덮어써야 한다 (REPLACE)', () async {
      await dataSource.putGroqCachedResponse('key1', '{"v":1}');
      await dataSource.putGroqCachedResponse('key1', '{"v":2}');

      final result = await dataSource.getGroqCachedResponse('key1');
      expect(result, equals('{"v":2}'));
    });

    test('get 호출 시 last_used_at이 갱신되어야 한다', () async {
      await dataSource.putGroqCachedResponse('key1', '{"v":1}');

      final initial = await testDb.query(
        'groq_analysis_cache',
        columns: ['last_used_at'],
        where: 'cache_key = ?',
        whereArgs: ['key1'],
      );
      final initialUsedAt = initial.first['last_used_at'] as int;

      // 시간 차이를 위해 약간 대기
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await dataSource.getGroqCachedResponse('key1');

      final after = await testDb.query(
        'groq_analysis_cache',
        columns: ['last_used_at'],
        where: 'cache_key = ?',
        whereArgs: ['key1'],
      );
      final afterUsedAt = after.first['last_used_at'] as int;

      expect(afterUsedAt, greaterThan(initialUsedAt));
    });

    test('clearGroqCache는 모든 항목을 삭제해야 한다', () async {
      await dataSource.putGroqCachedResponse('key1', '{"v":1}');
      await dataSource.putGroqCachedResponse('key2', '{"v":2}');

      await dataSource.clearGroqCache();

      expect(await dataSource.getGroqCachedResponse('key1'), isNull);
      expect(await dataSource.getGroqCachedResponse('key2'), isNull);
    });

    test('손상된 JSON도 그대로 저장/반환되어야 한다 (정합성은 호출자 책임)', () async {
      const corrupted = 'not_valid_json{{{';
      await dataSource.putGroqCachedResponse('key1', corrupted);

      final result = await dataSource.getGroqCachedResponse('key1');
      expect(result, equals(corrupted));
    });
  });
}
