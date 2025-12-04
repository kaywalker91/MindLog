import '../entities/diary.dart';
import '../repositories/diary_repository.dart';

/// 일기 분석 UseCase
///
/// 일기 작성 → 저장 → 분석 → 결과 업데이트의 전체 플로우를 담당합니다.
class AnalyzeDiaryUseCase {
  final DiaryRepository _repository;

  AnalyzeDiaryUseCase(this._repository);

  /// 일기 작성 및 분석 실행
  ///
  /// 1. 일기를 pending 상태로 즉시 저장 (데이터 유실 방지)
  /// 2. Gemini API로 분석 요청
  /// 3. 분석 결과로 일기 업데이트
  ///
  /// [content] 사용자가 입력한 일기 내용
  ///
  /// 반환값: 분석이 완료된 Diary 객체
  Future<Diary> execute(String content) async {
    // 1. 일기를 pending 상태로 먼저 저장
    final diary = Diary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      createdAt: DateTime.now(),
      status: DiaryStatus.pending,
    );

    final savedDiary = await _repository.saveDiary(diary);

    try {
      // 2. Gemini API로 분석 요청
      final analysisResult = await _repository.analyzeDiary(content);

      // 3. 분석 결과로 일기 업데이트
      final analyzedDiary = await _repository.updateDiaryWithAnalysis(
        savedDiary.id,
        analysisResult,
      );

      return analyzedDiary;
    } catch (e) {
      // 분석 실패 시 상태 업데이트
      await _repository.updateDiaryStatus(savedDiary.id, DiaryStatus.failed);
      rethrow;
    }
  }
}
