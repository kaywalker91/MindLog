import 'package:hive_flutter/hive_flutter.dart';
import '../../dto/diary_dto.dart';
import '../../../core/errors/exceptions.dart';

/// Hive 로컬 데이터 소스
class HiveLocalDataSource {
  static const String _diaryBoxName = 'diaries';

  Box<DiaryDto>? _diaryBox;

  /// Hive Box 인스턴스 초기화
  Future<Box<DiaryDto>> get diaryBox async {
    if (_diaryBox != null && _diaryBox!.isOpen) {
      return _diaryBox!;
    }

    _diaryBox = await Hive.openBox<DiaryDto>(_diaryBoxName);
    return _diaryBox!;
  }

  /// Hive 초기화 (앱 시작 시 호출)
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Adapter 등록
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DiaryDtoAdapter());
    }
  }

  /// 일기 저장
  Future<DiaryDto> saveDiary(DiaryDto diary) async {
    try {
      final box = await diaryBox;
      await box.put(diary.diaryId, diary);

      // 저장된 데이터 반환
      final saved = box.get(diary.diaryId);
      if (saved == null) {
        throw DatabaseException('일기 저장 후 조회 실패');
      }
      return saved;
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('일기 저장 실패: $e');
    }
  }

  /// ID로 일기 조회
  Future<DiaryDto?> getDiaryById(String diaryId) async {
    try {
      final box = await diaryBox;
      return box.get(diaryId);
    } catch (e) {
      throw DatabaseException('일기 조회 실패: $e');
    }
  }

  /// 모든 일기 조회 (최신순)
  Future<List<DiaryDto>> getAllDiaries() async {
    try {
      final box = await diaryBox;
      final diaries = box.values.toList();
      diaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return diaries;
    } catch (e) {
      throw DatabaseException('일기 목록 조회 실패: $e');
    }
  }

  /// 오늘 작성한 일기 조회
  Future<List<DiaryDto>> getTodayDiaries() async {
    try {
      final box = await diaryBox;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final diaries = box.values
          .where((diary) =>
              diary.createdAt.isAfter(startOfDay) &&
              diary.createdAt.isBefore(endOfDay))
          .toList();

      diaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return diaries;
    } catch (e) {
      throw DatabaseException('오늘 일기 조회 실패: $e');
    }
  }

  /// 일기 업데이트
  Future<DiaryDto> updateDiary(DiaryDto diary) async {
    try {
      final box = await diaryBox;

      // 기존 데이터 확인
      final existing = box.get(diary.diaryId);
      if (existing == null) {
        throw DatabaseException('업데이트할 일기를 찾을 수 없습니다');
      }

      await box.put(diary.diaryId, diary);

      final updated = box.get(diary.diaryId);
      if (updated == null) {
        throw DatabaseException('일기 업데이트 후 조회 실패');
      }
      return updated;
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('일기 업데이트 실패: $e');
    }
  }

  /// 일기 삭제
  Future<void> deleteDiary(String diaryId) async {
    try {
      final box = await diaryBox;
      await box.delete(diaryId);
    } catch (e) {
      throw DatabaseException('일기 삭제 실패: $e');
    }
  }

  /// Box 닫기
  Future<void> close() async {
    if (_diaryBox != null && _diaryBox!.isOpen) {
      await _diaryBox!.close();
      _diaryBox = null;
    }
  }
}
