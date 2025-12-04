import '../entities/diary.dart';

/// 일기 저장소 인터페이스 (Domain Layer)
abstract class DiaryRepository {
  /// 일기 저장 (로컬 DB)
  Future<Diary> saveDiary(Diary diary);

  /// 일기 분석 요청 (Gemini API)
  Future<AnalysisResult> analyzeDiary(String content);

  /// 분석 결과 업데이트
  Future<Diary> updateDiaryWithAnalysis(String diaryId, AnalysisResult result);

  /// 일기 상태 업데이트
  Future<Diary> updateDiaryStatus(String diaryId, DiaryStatus status);

  /// 특정 일기 조회
  Future<Diary?> getDiaryById(String id);

  /// 모든 일기 조회 (최신순)
  Future<List<Diary>> getAllDiaries();

  /// 오늘 작성한 일기 조회
  Future<List<Diary>> getTodayDiaries();

  /// 추천 행동 완료 상태 토글
  Future<Diary> toggleActionComplete(String diaryId);

  /// 일기 삭제
  Future<void> deleteDiary(String diaryId);
}
