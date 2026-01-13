import 'package:mindlog/domain/entities/diary.dart';

/// 테스트용 Diary 픽스처
class DiaryFixtures {
  // 테스트용 고정 시간
  static final DateTime testNow = DateTime(2024, 1, 15, 12, 0);

  /// pending 상태의 일기
  static Diary pending({
    String? id,
    String? content,
    DateTime? createdAt,
    bool isPinned = false,
  }) =>
      Diary(
        id: id ?? 'test-pending-id',
        content: content ?? '오늘 하루는 평범하게 지나갔다. 특별한 일은 없었지만 나름 만족스러운 하루였다.',
        createdAt: createdAt ?? testNow,
        status: DiaryStatus.pending,
        isPinned: isPinned,
      );

  /// 분석 완료된 일기
  static Diary analyzed({
    String? id,
    String? content,
    DateTime? createdAt,
    int sentimentScore = 7,
    bool isEmergency = false,
    bool isPinned = false,
    List<String>? keywords,
    String? empathyMessage,
  }) =>
      Diary(
        id: id ?? 'test-analyzed-id',
        content: content ?? '오늘 프로젝트 발표가 있었는데 잘 마무리해서 기분이 좋다.',
        createdAt: createdAt ?? testNow,
        status: DiaryStatus.analyzed,
        isPinned: isPinned,
        analysisResult: AnalysisResult(
          keywords: keywords ?? ['프로젝트', '발표', '성취감', '만족', '기쁨'],
          sentimentScore: sentimentScore,
          empathyMessage: empathyMessage ?? '프로젝트 발표를 잘 마무리하셨군요. 정말 대단해요!',
          actionItem: '오늘의 성취를 기록해보세요.',
          actionItems: ['잠시 휴식을 취하세요', '오늘의 성취를 기록하세요', '다음 목표를 설정해보세요'],
          analyzedAt: createdAt ?? testNow,
          isEmergency: isEmergency,
          aiCharacterId: 'warmCounselor',
          emotionCategory: const EmotionCategory(
            primary: '기쁨',
            secondary: '성취감',
          ),
          emotionTrigger: const EmotionTrigger(
            category: '직장/학업',
            description: '프로젝트 발표 성공',
          ),
          energyLevel: 8,
        ),
      );

  /// 안전 필터에 의해 차단된 일기
  static Diary safetyBlocked({
    String? id,
    DateTime? createdAt,
  }) =>
      Diary(
        id: id ?? 'test-blocked-id',
        content: '너무 힘들어서 모든 것을 끝내고 싶다는 생각이 들었다.',
        createdAt: createdAt ?? testNow,
        status: DiaryStatus.safetyBlocked,
        analysisResult: AnalysisResult(
          keywords: ['힘듦', '지침', '고통'],
          sentimentScore: 1,
          empathyMessage: '지금 많이 힘드시군요. 당신의 고통이 느껴집니다.',
          actionItem: '자살예방상담전화 1393으로 연락해주세요.',
          analyzedAt: createdAt ?? testNow,
          isEmergency: true,
        ),
      );

  /// 분석 실패한 일기
  static Diary failed({
    String? id,
    DateTime? createdAt,
  }) =>
      Diary(
        id: id ?? 'test-failed-id',
        content: '오늘 날씨가 좋아서 산책을 다녀왔다. 기분이 상쾌해졌다.',
        createdAt: createdAt ?? testNow,
        status: DiaryStatus.failed,
      );

  /// 일주일치 일기 목록 (통계 테스트용)
  static List<Diary> weekOfDiaries({DateTime? baseDate}) {
    final base = baseDate ?? testNow;
    return List.generate(7, (index) {
      final date = base.subtract(Duration(days: index));
      final score = (5 + (index % 5)).clamp(1, 10);
      return analyzed(
        id: 'diary-day-$index',
        createdAt: date,
        sentimentScore: score,
        keywords: _keywordsForDay(index),
      );
    });
  }

  /// 한 달치 일기 목록 (통계 테스트용)
  static List<Diary> monthOfDiaries({DateTime? baseDate}) {
    final base = baseDate ?? testNow;
    return List.generate(30, (index) {
      final date = base.subtract(Duration(days: index));
      final score = ((index % 10) + 1).clamp(1, 10);
      return analyzed(
        id: 'diary-month-$index',
        createdAt: date,
        sentimentScore: score,
        keywords: _keywordsForDay(index % 7),
      );
    });
  }

  /// 빈 일기 목록
  static List<Diary> empty() => [];

  /// 혼합된 상태의 일기 목록 (pending + analyzed + failed)
  static List<Diary> mixed() => [
        analyzed(id: 'mix-1', createdAt: testNow),
        pending(id: 'mix-2', createdAt: testNow.subtract(const Duration(hours: 1))),
        failed(id: 'mix-3', createdAt: testNow.subtract(const Duration(hours: 2))),
        analyzed(id: 'mix-4', createdAt: testNow.subtract(const Duration(hours: 3))),
        safetyBlocked(id: 'mix-5', createdAt: testNow.subtract(const Duration(hours: 4))),
      ];

  /// 고정된 일기와 일반 일기 혼합
  static List<Diary> withPinned() => [
        analyzed(id: 'pinned-1', isPinned: true, createdAt: testNow.subtract(const Duration(days: 3))),
        analyzed(id: 'normal-1', isPinned: false, createdAt: testNow),
        analyzed(id: 'pinned-2', isPinned: true, createdAt: testNow.subtract(const Duration(days: 1))),
        analyzed(id: 'normal-2', isPinned: false, createdAt: testNow.subtract(const Duration(hours: 6))),
      ];

  static List<String> _keywordsForDay(int dayIndex) {
    const keywordSets = [
      ['행복', '만족', '기쁨', '웃음', '감사'],
      ['피곤', '휴식', '일상', '평범', '무난'],
      ['스트레스', '업무', '압박', '긴장', '집중'],
      ['운동', '건강', '활력', '상쾌', '에너지'],
      ['가족', '사랑', '따뜻함', '행복', '소중'],
      ['친구', '대화', '즐거움', '웃음', '추억'],
      ['성장', '배움', '도전', '발전', '노력'],
    ];
    return keywordSets[dayIndex % keywordSets.length];
  }
}
