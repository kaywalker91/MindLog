import '../entities/diary.dart';
import '../repositories/diary_repository.dart';
import '../../core/errors/failures.dart';

/// 일기 분석 유스케이스
class AnalyzeDiaryUseCase {
  final DiaryRepository _repository;

  AnalyzeDiaryUseCase(this._repository);

  /// 일기 작성 및 분석 실행
  /// 
  /// [content] 사용자가 입력한 일기 내용
  /// 
  /// 반환값: 분석이 완료된 Diary 엔티티
  Future<Diary> execute(String content) async {
    try {
      // 입력 유효성 검사
      if (content.trim().isEmpty) {
        throw const ValidationFailure(message: '일기 내용을 입력해주세요.');
      }

      if (content.length < 10) {
        throw const ValidationFailure(message: '최소 10자 이상 입력해주세요.');
      }

      if (content.length > 1000) {
        throw const ValidationFailure(message: '최대 1000자까지 입력 가능합니다.');
      }

      // 1. 로컬에 일기 저장 (pending 상태)
      final diary = await _repository.createDiary(content);

      // 2. AI 분석 요청
      try {
        // UUID 생성
        final diaryId = diary.id;
        final analyzedDiary = await _repository.analyzeDiary(diaryId);
        return analyzedDiary;
      } catch (e) {
        // 분석 실패해도 일기는 저장되어야 함
        return diary;
      }
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw UnknownFailure(message: e.toString());
    }
  }
}
