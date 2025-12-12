import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../../domain/entities/diary.dart';
import '../../../core/errors/exceptions.dart';

/// SQLite 로컬 데이터 소스
class SqliteLocalDataSource {
  static Database? _database;

  /// 데이터베이스 인스턴스 초기화
  static Future<Database> _getDatabase() async {
    if (_database != null) return _database!;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'mindlog.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    return _database!;
  }

  /// 데이터베이스 테이블 생성
  static Future<void> _onCreate(Database db, int version) async {
    final idType = 'TEXT PRIMARY KEY';
    
    await db.execute('''
      CREATE TABLE diaries (
        id $idType,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL,
        analysis_result TEXT
      )
    ''');
  }

  /// 일기 저장
  Future<void> saveDiary(Diary diary) async {
    try {
      final db = await _getDatabase();
      
      final analysisResultJson = diary.analysisResult?.toJson();
      
      await db.insert(
        'diaries',
        {
          'id': diary.id,
          'content': diary.content,
          'created_at': diary.createdAt.toIso8601String(),
          'status': diary.status.name,
          'analysis_result': analysisResultJson != null 
              ? jsonEncode(analysisResultJson)
              : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('일기 저장 실패: $e');
    }
  }

  /// 일기 읽기 (ID 기준)
  Future<Diary?> getDiaryById(String diaryId) async {
    try {
      final db = await _getDatabase();
      
      final maps = await db.query(
        'diaries',
        where: 'id = ?',
        whereArgs: [diaryId],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      
      return _mapToDiary(maps.first);
    } catch (e) {
      throw CacheException('일기 조회 실패: $e');
    }
  }

  /// 모든 일기 조회
  Future<List<Diary>> getAllDiaries() async {
    try {
      final db = await _getDatabase();
      
      final maps = await db.query(
        'diaries',
        orderBy: 'created_at DESC',
      );

      return maps.map(_mapToDiary).toList();
    } catch (e) {
      throw CacheException('일기 목록 조회 실패: $e');
    }
  }

  /// 오늘 작성된 일기 조회
  Future<List<Diary>> getTodayDiaries() async {
    try {
      final db = await _getDatabase();
      
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      final maps = await db.query(
        'diaries',
        where: 'created_at >= ?',
        whereArgs: [todayStart.toIso8601String()],
        orderBy: 'created_at DESC',
      );

      return maps.map(_mapToDiary).toList();
    } catch (e) {
      throw CacheException('오늘 일기 조회 실패: $e');
    }
  }

  /// 일기 분석 결과 업데이트
  Future<void> updateDiaryWithAnalysis(String diaryId, AnalysisResult analysisResult) async {
    try {
      final db = await _getDatabase();
      
      await db.update(
        'diaries',
        {
          'status': DiaryStatus.analyzed.name,
          'analysis_result': jsonEncode(analysisResult.toJson()),
        },
        where: 'id = ?',
        whereArgs: [diaryId],
      );
    } catch (e) {
      throw CacheException('일기 업데이트 실패: $e');
    }
  }

  /// 일기 상태 업데이트
  Future<void> updateDiaryStatus(String diaryId, DiaryStatus status) async {
    try {
      final db = await _getDatabase();
      
      await db.update(
        'diaries',
        {'status': status.name},
        where: 'id = ?',
        whereArgs: [diaryId],
      );
    } catch (e) {
      throw CacheException('일기 상태 업데이트 실패: $e');
    }
  }

  /// 일기 삭제
  Future<void> deleteDiary(String diaryId) async {
    try {
      final db = await _getDatabase();

      final deleted = await db.delete(
        'diaries',
        where: 'id = ?',
        whereArgs: [diaryId],
      );

      if (deleted == 0) {
        throw Exception('삭제할 일기를 찾을 수 없습니다: $diaryId');
      }
    } catch (e) {
      throw CacheException('일기 삭제 실패: $e');
    }
  }

  /// 모든 일기 삭제
  Future<void> deleteAllDiaries() async {
    try {
      final db = await _getDatabase();
      await db.delete('diaries');
    } catch (e) {
      throw CacheException('모든 일기 삭제 실패: $e');
    }
  }

  /// 데이터베이스 닫기
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// 데이터베이스 Map을 Diary 엔티티로 변환
  Diary _mapToDiary(Map<String, dynamic> map) {
    AnalysisResult? analysisResult;
    final analysisResultStr = map['analysis_result'] as String?;
    
    if (analysisResultStr != null && analysisResultStr.isNotEmpty) {
      try {
        final analysisResultMap = jsonDecode(analysisResultStr) as Map<String, dynamic>;
        analysisResult = AnalysisResult.fromJson(analysisResultMap);
      } catch (e) {
        // JSON 파싱 실패 시 null로 처리
        analysisResult = null;
      }
    }

    return Diary(
      id: map['id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      status: DiaryStatus.values.firstWhere(
        (status) => status.name == map['status'] as String,
      ),
      analysisResult: analysisResult,
    );
  }

  /// UUID 생성 헬퍼

}
