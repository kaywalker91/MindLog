import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../../domain/entities/diary.dart';
import '../../../core/errors/exceptions.dart';

/// SQLite 로컬 데이터 소스
class SqliteLocalDataSource {
  static const int _currentVersion = 7;
  static Database? _database;

  /// 테스트용 Database 주입 (인메모리 DB 테스트용)
  /// 프로덕션에서는 사용하지 않음
  @visibleForTesting
  static Database? testDatabase;

  /// 테스트용 데이터베이스 초기화 (기존 연결 종료 후 재설정)
  static Future<void> resetForTesting() async {
    await forceReconnect();
  }

  /// DB 연결 강제 리셋
  ///
  /// 앱 재설치 시 OS가 복원한 DB 파일을 읽기 위해 캐시된 연결을 해제합니다.
  /// 이 메서드는 앱 시작 시 호출되어야 합니다.
  ///
  /// 문제 상황:
  /// - static [_database]는 앱 프로세스 동안 캐싱됨
  /// - 앱 삭제 후 재설치 시 OS가 백업에서 DB 파일 복원
  /// - 기존 캐시 연결은 복원된 파일이 아닌 이전 상태 유지
  /// - 결과: 일기 목록은 보이지만 통계에 반영 안 됨
  static Future<void> forceReconnect() async {
    if (_database != null) {
      try {
        await _database!.close();
      } catch (e) {
        // 이미 닫힌 연결은 무시 (복원 시나리오에서 발생 가능)
      }
      _database = null;
    }
  }

  /// 데이터베이스 인스턴스 초기화
  static Future<Database> _getDatabase() async {
    // 테스트용 DB가 주입된 경우 사용
    if (testDatabase != null) return testDatabase!;
    if (_database != null) return _database!;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'mindlog.db');

    _database = await openDatabase(
      path,
      version: _currentVersion,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
    return _database!;
  }

  /// 데이터베이스 테이블 생성
  /// 테스트에서 직접 호출 가능하도록 @visibleForTesting 추가
  @visibleForTesting
  static Future<void> onCreate(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';

    await db.execute('''
      CREATE TABLE diaries (
        id $idType,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL,
        analysis_result TEXT,
        is_pinned INTEGER DEFAULT 0,
        image_paths TEXT,
        is_secret INTEGER DEFAULT 0
      )
    ''');

    // 인덱스 생성 (성능 최적화)
    await db.execute(
      'CREATE INDEX idx_diaries_created_at ON diaries(created_at)',
    );
    await db.execute('CREATE INDEX idx_diaries_status ON diaries(status)');
    // 복합 인덱스: 통계 쿼리 최적화 (status + created_at 동시 조건)
    await db.execute(
      'CREATE INDEX idx_diaries_status_created_at ON diaries(status, created_at)',
    );
    // 복합 인덱스: 목록 조회 최적화 (is_pinned DESC, created_at DESC 정렬)
    await db.execute(
      'CREATE INDEX idx_diaries_pinned_created ON diaries(is_pinned DESC, created_at DESC)',
    );

    // 앱 메타데이터 테이블 (세션 추적용)
    await db.execute('''
      CREATE TABLE app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// 데이터베이스 마이그레이션
  /// 테스트에서 직접 호출 가능하도록 @visibleForTesting 추가
  @visibleForTesting
  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // 버전 1 → 2: 복합 인덱스 추가 (통계 쿼리 최적화)
    if (oldVersion < 2) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_diaries_status_created_at ON diaries(status, created_at)',
      );
    }

    // 버전 2 → 3: is_pinned 컬럼 추가 (일기 고정 기능)
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE diaries ADD COLUMN is_pinned INTEGER DEFAULT 0',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_diaries_is_pinned ON diaries(is_pinned)',
      );
    }

    // 버전 3 → 4: 복합 인덱스 추가 (목록 조회 최적화)
    // getAllDiaries(), getTodayDiaries()에서 'is_pinned DESC, created_at DESC' 정렬 최적화
    if (oldVersion < 4) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_diaries_pinned_created ON diaries(is_pinned DESC, created_at DESC)',
      );
      // 단일 is_pinned 인덱스는 복합 인덱스로 대체되므로 제거 (선택적)
      // SQLite는 DROP INDEX IF EXISTS를 지원하므로 안전하게 제거
      await db.execute('DROP INDEX IF EXISTS idx_diaries_is_pinned');
    }

    // 버전 4 → 5: app_metadata 테이블 추가 (DB 복원 감지용)
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }

    // 버전 5 → 6: image_paths 컬럼 추가 (이미지 첨부 기능)
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE diaries ADD COLUMN image_paths TEXT');
    }

    // 버전 6 → 7: is_secret 컬럼 추가 (비밀일기 기능)
    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE diaries ADD COLUMN is_secret INTEGER DEFAULT 0',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_diaries_is_secret ON diaries(is_secret)',
      );
    }
  }

  /// 메타데이터 저장
  Future<void> setMetadata(String key, String value) async {
    return _runDb('메타데이터 저장 실패', (db) async {
      await db.insert('app_metadata', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// 메타데이터 조회
  Future<String?> getMetadata(String key) async {
    return _runDb('메타데이터 조회 실패', (db) async {
      final result = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return result.first['value'] as String?;
    });
  }

  /// 일기 저장
  Future<void> saveDiary(Diary diary) async {
    return _runDb('일기 저장 실패', (db) async {
      final analysisResultJson = diary.analysisResult?.toJson();

      await db.insert('diaries', {
        'id': diary.id,
        'content': diary.content,
        'created_at': diary.createdAt.toIso8601String(),
        'status': diary.status.name,
        'analysis_result': analysisResultJson != null
            ? jsonEncode(analysisResultJson)
            : null,
        'is_pinned': diary.isPinned ? 1 : 0,
        'image_paths': diary.imagePaths != null
            ? jsonEncode(diary.imagePaths)
            : null,
        'is_secret': diary.isSecret ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  /// 일기 읽기 (ID 기준)
  Future<Diary?> getDiaryById(String diaryId) async {
    return _runDb('일기 조회 실패', (db) async {
      final maps = await db.query(
        'diaries',
        where: 'id = ?',
        whereArgs: [diaryId],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      return _mapToDiary(maps.first);
    });
  }

  /// 모든 일기 조회 (비밀일기 제외)
  Future<List<Diary>> getAllDiaries() async {
    return _runDb('일기 목록 조회 실패', (db) async {
      final maps = await db.query(
        'diaries',
        where: 'is_secret = 0',
        orderBy: 'is_pinned DESC, created_at DESC',
      );

      return maps.map(_mapToDiary).toList();
    });
  }

  /// 오늘 작성된 일기 조회 (비밀일기 제외)
  Future<List<Diary>> getTodayDiaries() async {
    return _runDb('오늘 일기 조회 실패', (db) async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final maps = await db.query(
        'diaries',
        where: 'created_at >= ? AND is_secret = 0',
        whereArgs: [todayStart.toIso8601String()],
        orderBy: 'is_pinned DESC, created_at DESC',
      );

      return maps.map(_mapToDiary).toList();
    });
  }

  /// 비밀일기 목록 조회 (고정 우선, 최신순)
  Future<List<Diary>> getSecretDiaries() async {
    return _runDb('비밀일기 목록 조회 실패', (db) async {
      final maps = await db.query(
        'diaries',
        where: 'is_secret = 1',
        orderBy: 'is_pinned DESC, created_at DESC',
      );

      return maps.map(_mapToDiary).toList();
    });
  }

  /// 일기 비밀 여부 업데이트
  Future<void> updateDiarySecret(String diaryId, bool isSecret) async {
    return _runDb('일기 비밀 상태 업데이트 실패', (db) async {
      await db.update(
        'diaries',
        {'is_secret': isSecret ? 1 : 0},
        where: 'id = ?',
        whereArgs: [diaryId],
      );
    });
  }

  /// 일기 분석 결과 업데이트
  Future<void> updateDiaryWithAnalysis(
    String diaryId,
    AnalysisResult analysisResult,
  ) async {
    return _runDb('일기 업데이트 실패', (db) async {
      await db.update(
        'diaries',
        {
          'status': DiaryStatus.analyzed.name,
          'analysis_result': jsonEncode(analysisResult.toJson()),
        },
        where: 'id = ?',
        whereArgs: [diaryId],
      );
    });
  }

  /// 일기 상태 업데이트
  Future<void> updateDiaryStatus(String diaryId, DiaryStatus status) async {
    return _runDb('일기 상태 업데이트 실패', (db) async {
      await db.update(
        'diaries',
        {'status': status.name},
        where: 'id = ?',
        whereArgs: [diaryId],
      );
    });
  }

  /// 일기 상단 고정 상태 업데이트
  Future<void> updateDiaryPin(String diaryId, bool isPinned) async {
    return _runDb('일기 고정 상태 업데이트 실패', (db) async {
      await db.update(
        'diaries',
        {'is_pinned': isPinned ? 1 : 0},
        where: 'id = ?',
        whereArgs: [diaryId],
      );
    });
  }

  /// 일기 삭제
  Future<void> deleteDiary(String diaryId) async {
    return _runDb('일기 삭제 실패', (db) async {
      final deleted = await db.delete(
        'diaries',
        where: 'id = ?',
        whereArgs: [diaryId],
      );

      if (deleted == 0) {
        throw DataNotFoundException('삭제할 일기를 찾을 수 없습니다: $diaryId');
      }
    });
  }

  /// 모든 일기 삭제
  Future<void> deleteAllDiaries() async {
    return _runDb('모든 일기 삭제 실패', (db) async {
      await db.delete('diaries');
    });
  }

  /// 데이터베이스 닫기
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// 날짜 범위로 분석된 일기 조회 (통계용 최적화 쿼리)
  Future<List<Diary>> getAnalyzedDiariesInRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _runDb('날짜 범위 일기 조회 실패', (db) async {
      String whereClause =
          "(status = 'analyzed' OR status = 'safetyBlocked') AND is_secret = 0";
      final List<String> whereArgs = [];

      if (startDate != null) {
        whereClause += ' AND created_at >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        whereClause += ' AND created_at <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final maps = await db.query(
        'diaries',
        where: whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: 'created_at DESC',
      );

      return maps.map(_mapToDiary).toList();
    });
  }

  /// 공통 DB 호출 래퍼 (예외 메시지 표준화)
  Future<T> _runDb<T>(
    String errorMessage,
    Future<T> Function(Database db) action,
  ) async {
    try {
      final db = await _getDatabase();
      return await action(db);
    } on DataNotFoundException {
      rethrow;
    } catch (e) {
      throw CacheException('$errorMessage: $e');
    }
  }

  /// 데이터베이스 Map을 Diary 엔티티로 변환
  Diary _mapToDiary(Map<String, dynamic> map) {
    AnalysisResult? analysisResult;
    final analysisResultStr = map['analysis_result'] as String?;

    if (analysisResultStr != null && analysisResultStr.isNotEmpty) {
      try {
        final analysisResultMap =
            jsonDecode(analysisResultStr) as Map<String, dynamic>;
        analysisResult = AnalysisResult.fromJson(analysisResultMap);
      } catch (e) {
        analysisResult = null;
      }
    }

    // DateTime 파싱 안전 처리: 잘못된 형식은 현재 시간으로 대체
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(map['created_at'] as String);
    } catch (e) {
      createdAt = DateTime.now();
    }

    // DiaryStatus 파싱 안전 처리: 알 수 없는 상태는 pending으로 대체
    final statusStr = map['status'] as String?;
    final status = DiaryStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => DiaryStatus.pending,
    );

    // image_paths 파싱 안전 처리
    List<String>? imagePaths;
    final imagePathsStr = map['image_paths'] as String?;
    if (imagePathsStr != null && imagePathsStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(imagePathsStr);
        if (decoded is List) {
          imagePaths = decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        imagePaths = null;
      }
    }

    return Diary(
      id: map['id'] as String,
      content: map['content'] as String,
      createdAt: createdAt,
      status: status,
      analysisResult: analysisResult,
      isPinned: (map['is_pinned'] as int?) == 1,
      imagePaths: imagePaths,
      isSecret: (map['is_secret'] as int?) == 1,
    );
  }
}
