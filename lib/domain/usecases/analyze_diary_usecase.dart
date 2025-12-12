import '../entities/diary.dart';
import '../repositories/diary_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/safety_constants.dart';

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

      // 2. 사전 안전 필터링 - 응급 키워드 감지 시 즉시 SOS 분기
      if (SafetyConstants.containsEmergencyKeyword(content)) {
        // 응급 상황 분석 결과 생성
        final emergencyResult = AnalysisResult(
          keywords: SafetyConstants.getDetectedKeywords(content).take(3).toList(),
          sentimentScore: 1,
          empathyMessage: SafetyConstants.emergencyMessage,
          actionItem: '전문 상담사와 대화해 보세요. 1393(자살예방상담전화)으로 연락할 수 있습니다.',
          analyzedAt: DateTime.now(),
          isEmergency: true,
        );

        // 로컬 DB 업데이트 (safetyBlocked 상태)
        final emergencyDiary = diary.copyWith(
          status: DiaryStatus.safetyBlocked,
          analysisResult: emergencyResult,
        );

        // DB에 업데이트된 일기 저장
        await _repository.updateDiary(emergencyDiary);

        return emergencyDiary;
      }

      // 3. AI 분석 요청 (응급 상황이 아닌 경우)
      try {
        final diaryId = diary.id;
        final analyzedDiary = await _repository.analyzeDiary(diaryId);

        // AI 응답에서도 응급 상황 체크 (이중 안전망)
        if (analyzedDiary.analysisResult?.isEmergency == true) {
          return analyzedDiary.copyWith(status: DiaryStatus.safetyBlocked);
        }

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
