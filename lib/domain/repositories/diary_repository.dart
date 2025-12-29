import '../../core/constants/ai_character.dart';
import '../entities/diary.dart';

/// 일기 저장소 인터페이스 (Domain Layer)
abstract class DiaryRepository {
  /// 일기 생성 (content 기준)
  Future<Diary> createDiary(String content);

  /// 일기 분석 요청
  Future<Diary> analyzeDiary(
    String diaryId, {
    required AiCharacter character,
  });

  /// 일기 전체 업데이트 (상태 및 분석 결과 포함)
  Future<void> updateDiary(Diary diary);

  /// 특정 일기 조회
  Future<Diary?> getDiaryById(String diaryId);

  /// 모든 일기 조회 (최신순)
  Future<List<Diary>> getAllDiaries();

  /// 오늘 작성한 일기 조회
  Future<List<Diary>> getTodayDiaries();

  /// 추천 행동 완료 상태 표시
  Future<void> markActionCompleted(String diaryId);

  /// 일기 삭제
  Future<void> deleteDiary(String diaryId);

  /// 모든 일기 삭제
  Future<void> deleteAllDiaries();
}
