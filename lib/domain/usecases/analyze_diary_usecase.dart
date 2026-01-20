import '../entities/diary.dart';
import '../repositories/diary_repository.dart';
import '../repositories/settings_repository.dart';
import '../../core/constants/ai_character.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/safety_constants.dart';
import '../../core/utils/clock.dart';
import 'validate_diary_content_usecase.dart';

/// 일기 분석 유스케이스
///
/// 책임: 일기 저장 및 AI 분석 실행
/// 유효성 검사는 [ValidateDiaryContentUseCase]에 위임
/// 시간 의존성은 [Clock]을 통해 주입받아 테스트 가능성 향상
class AnalyzeDiaryUseCase {
  final DiaryRepository _repository;
  final SettingsRepository _settingsRepository;
  final ValidateDiaryContentUseCase _validateUseCase;
  final Clock _clock;

  AnalyzeDiaryUseCase(
    this._repository,
    this._settingsRepository, {
    ValidateDiaryContentUseCase? validateUseCase,
    Clock? clock,
  })  : _validateUseCase = validateUseCase ?? ValidateDiaryContentUseCase(),
        _clock = clock ?? const SystemClock();

  /// 일기 작성 및 분석 실행
  ///
  /// [content] 사용자가 입력한 일기 내용
  ///
  /// 반환값: 분석이 완료된 Diary 엔티티
  Future<Diary> execute(String content) async {
    try {
      // 입력 유효성 검사 (ValidateDiaryContentUseCase에 위임)
      final validationResult = _validateUseCase.execute(content);
      final validatedContent = validationResult.sanitizedContent;

      // 1. 로컬에 일기 저장 (pending 상태)
      final diary = await _repository.createDiary(validatedContent);
      final character = await _settingsRepository.getSelectedAiCharacter();
      final userName = await _settingsRepository.getUserName();

      // 2. 사전 안전 필터링 - 응급 키워드 감지 시 즉시 SOS 분기
      if (SafetyConstants.containsEmergencyKeyword(validatedContent)) {
        // 응급 상황 분석 결과 생성
        final emergencyResult = AnalysisResult(
          keywords: SafetyConstants.getDetectedKeywords(validatedContent).take(5).toList(),
          sentimentScore: 1,
          empathyMessage: SafetyConstants.emergencyMessage,
          actionItem: '전문 상담사와 대화해 보세요. 1393(자살예방상담전화)으로 연락할 수 있습니다.',
          actionItems: [
            '🚀 지금 바로 1393에 전화해보세요',
            '☀️ 가까운 사람에게 연락해보세요',
            '📅 전문 상담 예약을 고려해보세요',
          ],
          analyzedAt: _clock.now(),
          isEmergency: true,
          aiCharacterId: character.id,
          emotionCategory: const EmotionCategory(
            primary: '공포',
            secondary: '절망',
          ),
          emotionTrigger: const EmotionTrigger(
            category: '자아',
            description: '심리적으로 힘든 상황',
          ),
          energyLevel: 1,
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

      // 3. AI 분석 요청 (응급 상황이 아닌 경우, 유저 이름 전달)
      final diaryId = diary.id;
      final analyzedDiary = await _repository.analyzeDiary(
        diaryId,
        character: character,
        userName: userName,
      );

      // AI 응답에서도 응급 상황 체크 (이중 안전망)
      if (analyzedDiary.analysisResult?.isEmergency == true) {
        return analyzedDiary.copyWith(status: DiaryStatus.safetyBlocked);
      }

      return analyzedDiary;
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw UnknownFailure(message: e.toString());
    }
  }
}
