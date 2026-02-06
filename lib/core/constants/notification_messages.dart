import 'dart:math';

/// 시간대 구분 (아침/오후/저녁/밤)
enum TimeSlot {
  /// 06:00 - 11:59
  morning,

  /// 12:00 - 17:59
  afternoon,

  /// 18:00 - 21:59
  evening,

  /// 22:00 - 05:59
  night,
}

/// 마음케어 CBT 기법별 카테고리
enum MindcareCategory {
  /// 행동 활성화 (가벼운 활동 제안)
  behavioralActivation,

  /// 마인드풀니스 (현재 순간 집중)
  mindfulness,

  /// 그라운딩 기법 (감각 자각)
  grounding,

  /// 인지적 재구조화 (생각 전환)
  cognitiveReframe,

  /// 자기 자비 (자기 돌봄)
  selfCompassion,

  /// 사회적 연결 (관계 활성화)
  socialConnection,

  /// 감사 실천
  gratitude,

  /// 신체 자각 (호흡/스트레칭)
  bodyAwareness,
}

/// 감정 레벨 (최근 감정 점수 기반)
enum EmotionLevel {
  /// 1-3점: 낮은 감정 상태 → 위로/공감 중심
  low,

  /// 4-6점: 보통 감정 상태 → 균형 잡힌 메시지
  medium,

  /// 7-10점: 높은 감정 상태 → 긍정 유지/격려
  high,
}

/// 알림 메시지 상수 및 랜덤 선택 유틸리티
///
/// 테스트 주입 패턴 적용:
/// - [setRandom]으로 테스트에서 결정론적 동작 보장
/// - [resetForTesting]으로 기본 Random 복원
class NotificationMessages {
  NotificationMessages._();

  static Random _random = Random();

  /// 테스트용: Random 인스턴스 설정
  static void setRandom(Random random) => _random = random;

  /// 테스트용: 기본 Random으로 리셋
  static void resetForTesting() => _random = Random();

  // ===== 리마인더 메시지 (로컬 알림) =====

  /// 리마인더 제목 - 질문형/공감형으로 관심 유발
  static const List<String> _reminderTitles = [
    '{name}님, 오늘 하루는 어떠셨나요?',
    '오늘 기분이 어떠셨어요?',
    '{name}님, 오늘 하루 수고하셨어요',
    '오늘은 어떤 하루였나요?',
    '오늘의 마음은 어땠나요?',
    '잠시 마음을 들여다볼까요?',
    '하루를 마무리하는 시간',
    '{name}님, 오늘도 고생 많으셨어요',
  ];

  /// 리마인더 본문 - 행동 유도형으로 작성 촉진
  static const List<String> _reminderBodies = [
    '마음을 기록해보세요',
    '오늘의 감정을 적어볼까요?',
    '마음 일기를 써보세요',
    '잠깐 마음을 정리해보세요',
    '오늘의 이야기를 들려주세요',
    '감정을 글로 표현해보세요',
    '하루의 감정을 기록해보세요',
    '마음을 털어놓으면 가벼워져요',
  ];

  // ===== 마음케어 메시지 (FCM/Push) =====

  /// 마음케어 제목 - 따뜻한 인사/주제 소개
  static const List<String> _mindcareTitles = [
    '오늘의 마음 케어',
    '좋은 아침이에요',
    '오늘도 힘내세요',
    '마음 챙김 시간',
    '오늘 하루도 응원해요',
    '작은 위로 전해드려요',
    '마음 한 스푼',
    '오늘의 격려',
  ];

  /// 마음케어 본문 - CBT 기법별 구조화
  ///
  /// 각 카테고리에 맞는 심리학적 기법 기반 메시지.
  /// 모든 메시지를 통합한 [_mindcareBodies]와
  /// 카테고리별 접근용 [_mindcareBodiesByCategory] 제공.

  // ── 행동 활성화 (Behavioral Activation) ──
  static const List<String> _behavioralActivationBodies = [
    '잠깐 기지개를 펴볼까요?',
    '좋아하는 음료 한 잔 어때요?',
    '창밖을 잠시 바라봐요',
    '가볍게 스트레칭 해보세요',
    '좋아하는 음악 한 곡 들어볼까요?',
    '5분만 바깥 공기를 마셔봐요',
  ];

  // ── 마인드풀니스 (Mindfulness) ──
  static const List<String> _mindfulnessBodies = [
    '지금 이 순간에 집중해보세요',
    '5초만 깊게 숨 쉬어볼까요?',
    '지금 느끼는 감정에 귀 기울여보세요',
    '잠시 멈추고 현재를 느껴보세요',
    '지금 들리는 소리에 귀 기울여보세요',
    '이 순간, 있는 그대로 충분해요',
  ];

  // ── 그라운딩 (Grounding) ──
  static const List<String> _groundingBodies = [
    '주변에서 좋아하는 색 3가지를 찾아보세요',
    '발바닥이 바닥에 닿는 느낌을 느껴보세요',
    '지금 손에 닿는 것의 질감을 느껴봐요',
    '주위에서 들리는 소리를 하나씩 세어보세요',
    '깊게 숨 쉬며 향기를 느껴보세요',
  ];

  // ── 인지적 재구조화 (Cognitive Reframe) ──
  static const List<String> _cognitiveReframeBodies = [
    '오늘 하루도 새로운 시작이에요',
    '작은 성취도 큰 의미가 있어요',
    '힘든 날도 지나갈 거예요',
    '완벽하지 않아도 괜찮아요',
    '실패도 성장의 일부예요',
    '다른 시각으로 바라보면 답이 보여요',
  ];

  // ── 자기 자비 (Self-Compassion) ──
  static const List<String> _selfCompassionBodies = [
    '오늘 자신에게 친절해보세요',
    '충분히 쉬어도 괜찮아요',
    '당신의 감정은 소중해요',
    '자신을 먼저 챙기는 것도 중요해요',
    '지치면 잠시 쉬어가도 괜찮아요',
    '있는 그대로의 당신이 좋아요',
  ];

  // ── 사회적 연결 (Social Connection) ──
  static const List<String> _socialConnectionBodies = [
    '소중한 사람이 떠오르나요?',
    '따뜻한 말 한마디의 힘을 믿어요',
    '누군가에게 안부를 전해보세요',
    '연결의 소중함을 기억해요',
    '함께하는 시간이 마음을 채워줘요',
  ];

  // ── 감사 실천 (Gratitude) ──
  static const List<String> _gratitudeBodies = [
    '작은 것에도 감사하는 하루 되세요',
    '오늘 감사한 것 하나를 떠올려봐요',
    '당신의 존재 자체가 의미 있어요',
    '오늘도 소중한 하루가 될 거예요',
    '좋은 일이 기다리고 있을 거예요',
  ];

  // ── 신체 자각 (Body Awareness) ──
  static const List<String> _bodyAwarenessBodies = [
    '잠시 깊게 숨을 쉬어보세요',
    '어깨에 힘을 빼고 내려놓아보세요',
    '턱을 부드럽게 풀어주세요',
    '가볍게 목을 돌려보세요',
    '호흡에 집중하면 마음이 편안해져요',
  ];

  /// CBT 카테고리별 메시지 맵
  static const Map<MindcareCategory, List<String>> _mindcareBodiesByCategory = {
    MindcareCategory.behavioralActivation: _behavioralActivationBodies,
    MindcareCategory.mindfulness: _mindfulnessBodies,
    MindcareCategory.grounding: _groundingBodies,
    MindcareCategory.cognitiveReframe: _cognitiveReframeBodies,
    MindcareCategory.selfCompassion: _selfCompassionBodies,
    MindcareCategory.socialConnection: _socialConnectionBodies,
    MindcareCategory.gratitude: _gratitudeBodies,
    MindcareCategory.bodyAwareness: _bodyAwarenessBodies,
  };

  /// 통합 마음케어 본문 (기존 API 호환)
  static final List<String> _mindcareBodies = [
    ..._behavioralActivationBodies,
    ..._mindfulnessBodies,
    ..._groundingBodies,
    ..._cognitiveReframeBodies,
    ..._selfCompassionBodies,
    ..._socialConnectionBodies,
    ..._gratitudeBodies,
    ..._bodyAwarenessBodies,
  ];

  // ===== 시간대별 마음케어 메시지 =====

  /// 아침 시간대 제목 (06:00-11:59)
  static const List<String> _morningTitles = [
    '좋은 아침이에요',
    '오늘도 힘내세요',
    '새로운 하루가 시작됐어요',
    '활기찬 하루 되세요',
    '상쾌한 아침이에요',
  ];

  /// 아침 시간대 본문
  static const List<String> _morningBodies = [
    '오늘 하루도 당신을 응원해요',
    '작은 것에도 감사하는 하루 되세요',
    '오늘 하루도 새로운 시작이에요',
    '좋은 일이 기다리고 있을 거예요',
    '가볍게 스트레칭으로 시작해보세요',
    '오늘의 작은 목표를 세워볼까요?',
  ];

  /// 오후 시간대 제목 (12:00-17:59)
  static const List<String> _afternoonTitles = [
    '잠시 쉬어가요',
    '마음 한 스푼',
    '오후도 파이팅',
    '잠깐 여유를 가져봐요',
    '좋은 오후예요',
  ];

  /// 오후 시간대 본문
  static const List<String> _afternoonBodies = [
    '잠시 깊게 숨을 쉬어보세요',
    '오늘 자신에게 친절해보세요',
    '충분히 쉬어도 괜찮아요',
    '작은 행복을 발견해보세요',
    '좋아하는 음료 한 잔 어때요?',
    '창밖을 잠시 바라봐요',
  ];

  /// 저녁 시간대 제목 (18:00-21:59)
  static const List<String> _eveningTitles = [
    '오늘의 마음 케어',
    '하루를 마무리해요',
    '오늘 하루 수고했어요',
    '저녁 마음 챙김',
    '오늘 하루는 어땠나요?',
  ];

  /// 저녁 시간대 본문
  static const List<String> _eveningBodies = [
    '오늘의 감정을 기록해보세요',
    '마음을 글로 표현해보세요',
    '하루의 감정을 정리해봐요',
    '오늘도 수고한 당신에게 박수를',
    '잠시 멈추고 현재를 느껴보세요',
    '당신의 하루를 들려주세요',
  ];

  /// 밤 시간대 제목 (22:00-05:59)
  static const List<String> _nightTitles = [
    '편안한 밤 되세요',
    '푹 쉬세요',
    '오늘도 수고했어요',
    '좋은 꿈 꾸세요',
    '고요한 밤이에요',
  ];

  /// 밤 시간대 본문
  static const List<String> _nightBodies = [
    '편안한 밤 보내세요',
    '내일은 더 좋은 하루가 될 거예요',
    '푹 쉬고 내일 만나요',
    '당신의 하루를 응원했어요',
    '오늘 하루도 감사해요',
    '따뜻한 잠자리 되세요',
  ];

  // ===== Cheer Me 제목 (로컬 알림 - 개인 응원) =====

  /// Cheer Me 알림 제목 - 따뜻한 인사 + 응원 톤
  static const List<String> _cheerMeTitles = [
    '{name}님의 응원 메시지',
    '{name}님, 오늘도 파이팅!',
    '{name}님을 위한 응원 한마디',
    '{name}님에게 보내는 응원',
    '{name}님, 힘을 드릴게요',
    '{name}님, 오늘도 빛나는 하루!',
    '{name}님의 마음 응원',
    '{name}님, 잠깐 쉬어가요',
  ];

  /// Cheer Me 알림 제목 반환 (이름 개인화 적용)
  static String getCheerMeTitle(String? userName) {
    final template = _cheerMeTitles[_random.nextInt(_cheerMeTitles.length)];
    return applyNamePersonalization(template, userName);
  }

  // ===== 리마인더 API =====

  /// 랜덤 리마인더 제목 반환
  static String getRandomReminderTitle() =>
      _reminderTitles[_random.nextInt(_reminderTitles.length)];

  /// 랜덤 리마인더 본문 반환
  static String getRandomReminderBody() =>
      _reminderBodies[_random.nextInt(_reminderBodies.length)];

  /// 랜덤 리마인더 메시지 쌍 반환
  static ({String title, String body}) getRandomReminderMessage() =>
      (title: getRandomReminderTitle(), body: getRandomReminderBody());

  // ===== 마음케어 API =====

  /// 랜덤 마음케어 제목 반환
  static String getRandomMindcareTitle() =>
      _mindcareTitles[_random.nextInt(_mindcareTitles.length)];

  /// 랜덤 마음케어 본문 반환
  static String getRandomMindcareBody() =>
      _mindcareBodies[_random.nextInt(_mindcareBodies.length)];

  /// 랜덤 마음케어 메시지 쌍 반환
  static ({String title, String body}) getRandomMindcareMessage() =>
      (title: getRandomMindcareTitle(), body: getRandomMindcareBody());

  // ===== 시간대 기반 마음케어 API =====

  /// 현재 시간 기준 TimeSlot 반환
  static TimeSlot getCurrentTimeSlot([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 6 && hour < 12) return TimeSlot.morning;
    if (hour >= 12 && hour < 18) return TimeSlot.afternoon;
    if (hour >= 18 && hour < 22) return TimeSlot.evening;
    return TimeSlot.night;
  }

  /// 시간대별 제목 맵
  static List<String> _getTitlesForSlot(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return _morningTitles;
      case TimeSlot.afternoon:
        return _afternoonTitles;
      case TimeSlot.evening:
        return _eveningTitles;
      case TimeSlot.night:
        return _nightTitles;
    }
  }

  /// 시간대별 본문 맵
  static List<String> _getBodiesForSlot(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return _morningBodies;
      case TimeSlot.afternoon:
        return _afternoonBodies;
      case TimeSlot.evening:
        return _eveningBodies;
      case TimeSlot.night:
        return _nightBodies;
    }
  }

  /// 시간대 기반 마음케어 메시지 반환
  /// [slot]이 null이면 현재 시간 기준으로 자동 선택
  static ({String title, String body}) getMindcareMessageByTimeSlot([
    TimeSlot? slot,
  ]) {
    final timeSlot = slot ?? getCurrentTimeSlot();
    final titles = _getTitlesForSlot(timeSlot);
    final bodies = _getBodiesForSlot(timeSlot);
    return (
      title: titles[_random.nextInt(titles.length)],
      body: bodies[_random.nextInt(bodies.length)],
    );
  }

  // ===== 테스트용 접근자 =====

  static List<String> get cheerMeTitles => List.unmodifiable(_cheerMeTitles);
  static List<String> get reminderTitles => List.unmodifiable(_reminderTitles);
  static List<String> get reminderBodies => List.unmodifiable(_reminderBodies);
  static List<String> get mindcareTitles => List.unmodifiable(_mindcareTitles);
  static List<String> get mindcareBodies => List.unmodifiable(_mindcareBodies);

  // 시간대별 메시지 접근자
  static List<String> get morningTitles => List.unmodifiable(_morningTitles);
  static List<String> get morningBodies => List.unmodifiable(_morningBodies);
  static List<String> get afternoonTitles =>
      List.unmodifiable(_afternoonTitles);
  static List<String> get afternoonBodies =>
      List.unmodifiable(_afternoonBodies);
  static List<String> get eveningTitles => List.unmodifiable(_eveningTitles);
  static List<String> get eveningBodies => List.unmodifiable(_eveningBodies);
  static List<String> get nightTitles => List.unmodifiable(_nightTitles);
  static List<String> get nightBodies => List.unmodifiable(_nightBodies);

  /// 시간대별 제목 목록 반환 (테스트용)
  static List<String> getTitlesForSlot(TimeSlot slot) =>
      List.unmodifiable(_getTitlesForSlot(slot));

  /// 시간대별 본문 목록 반환 (테스트용)
  static List<String> getBodiesForSlot(TimeSlot slot) =>
      List.unmodifiable(_getBodiesForSlot(slot));

  // ===== 이름 개인화 API =====

  /// 개인화 템플릿 패턴
  /// - "{name}님, " → 이름이 있으면 "지수님, ", 없으면 제거
  /// - "{name}" → 이름이 있으면 "지수", 없으면 제거
  static final RegExp _nameWithSuffixPattern = RegExp(r'\{name\}님[,의은을이]?\s*');
  static final RegExp _nameOnlyPattern = RegExp(r'\{name\}');

  /// 메시지에 이름 개인화 적용
  ///
  /// [message] - 개인화할 메시지 (title 또는 body)
  /// [userName] - 사용자 이름 (null 또는 빈 문자열이면 폴백)
  ///
  /// 예시:
  /// - "{name}님, 오늘 하루 수고하셨어요" + "지수" → "지수님, 오늘 하루 수고하셨어요"
  /// - "{name}님, 오늘 하루 수고하셨어요" + null → "오늘 하루 수고하셨어요"
  static String applyNamePersonalization(String message, String? userName) {
    if (userName != null && userName.trim().isNotEmpty) {
      // 이름이 있으면 {name}을 실제 이름으로 치환
      return message.replaceAll(_nameOnlyPattern, userName.trim());
    } else {
      // 이름이 없으면 "{name}님, " 또는 "{name}" 패턴 제거
      return message
          .replaceAll(_nameWithSuffixPattern, '')
          .replaceAll(_nameOnlyPattern, '');
    }
  }

  /// 메시지 쌍에 이름 개인화 적용
  static ({String title, String body}) applyNameToMessage(
    ({String title, String body}) message,
    String? userName,
  ) {
    return (
      title: applyNamePersonalization(message.title, userName),
      body: applyNamePersonalization(message.body, userName),
    );
  }

  // ===== 감정 기반 메시지 API =====

  /// 감정 레벨별 메시지 본문 - 공감/위로 (낮은 감정 상태용)
  static const List<String> _empathyBodies = [
    '힘든 날도 지나갈 거예요',
    '지치면 잠시 쉬어가도 괜찮아요',
    '완벽하지 않아도 괜찮아요',
    '당신의 마음을 응원해요',
    '당신의 감정은 소중해요',
    '자신을 먼저 챙기는 것도 중요해요',
    '충분히 쉬어도 괜찮아요',
    '잠시 깊게 숨을 쉬어보세요',
    '오늘 자신에게 친절해보세요',
    '지금 느끼는 감정에 귀 기울여보세요',
  ];

  /// 감정 레벨별 메시지 본문 - 격려/긍정 (높은 감정 상태용)
  static const List<String> _encouragementBodies = [
    '오늘도 당신의 하루를 응원해요',
    '당신은 충분히 잘하고 있어요',
    '오늘 하루도 당신을 믿어요',
    '작은 성취도 큰 의미가 있어요',
    '좋은 일이 기다리고 있을 거예요',
    '오늘도 소중한 하루가 될 거예요',
    '당신의 존재 자체가 의미 있어요',
    '오늘도 수고한 당신에게 박수를',
    '작은 것에도 감사하는 하루 되세요',
    '오늘 하루도 새로운 시작이에요',
  ];

  /// 감정 점수(1-10)를 EmotionLevel로 변환
  static EmotionLevel getEmotionLevel(double avgScore) {
    if (avgScore <= 3) return EmotionLevel.low;
    if (avgScore <= 6) return EmotionLevel.medium;
    return EmotionLevel.high;
  }

  /// 감정 레벨에 따른 메시지 본문 목록 반환
  static List<String> _getBodiesForEmotionLevel(EmotionLevel level) {
    switch (level) {
      case EmotionLevel.low:
        return _empathyBodies;
      case EmotionLevel.high:
        return _encouragementBodies;
      case EmotionLevel.medium:
        // 중간 레벨: 모든 일반 마음케어 본문 사용
        return _mindcareBodies;
    }
  }

  /// 감정 레벨 기반 마음케어 메시지 반환
  ///
  /// [avgScore] - 최근 감정 점수 평균 (1-10)
  /// [slot] - 시간대 (선택, null이면 현재 시간 기준)
  ///
  /// 반환 전략:
  /// - 낮은 감정(1-3): 공감/위로 메시지 80% 우선
  /// - 보통 감정(4-6): 모든 카테고리 균등
  /// - 높은 감정(7-10): 격려/긍정 메시지 60% 우선
  static ({String title, String body}) getMindcareMessageByEmotion(
    double avgScore, [
    TimeSlot? slot,
  ]) {
    final timeSlot = slot ?? getCurrentTimeSlot();
    final emotionLevel = getEmotionLevel(avgScore);

    // 제목: 시간대 기반 선택 (기존 로직 유지)
    final titles = _getTitlesForSlot(timeSlot);
    final title = titles[_random.nextInt(titles.length)];

    // 본문: 감정 레벨에 따른 가중치 적용
    final bodies = _selectBodiesWithWeight(emotionLevel, timeSlot);
    final body = bodies[_random.nextInt(bodies.length)];

    return (title: title, body: body);
  }

  /// 감정 레벨과 시간대를 고려한 본문 목록 선택
  ///
  /// 가중치 전략:
  /// - low: 공감/위로 80%, 시간대별 20%
  /// - medium: 시간대별 50%, 일반 50%
  /// - high: 격려/긍정 60%, 시간대별 40%
  static List<String> _selectBodiesWithWeight(
    EmotionLevel level,
    TimeSlot slot,
  ) {
    final emotionBodies = _getBodiesForEmotionLevel(level);
    final slotBodies = _getBodiesForSlot(slot);

    switch (level) {
      case EmotionLevel.low:
        // 공감/위로 80%: 4배 가중치
        return [
          ...emotionBodies,
          ...emotionBodies,
          ...emotionBodies,
          ...emotionBodies,
          ...slotBodies,
        ];
      case EmotionLevel.high:
        // 격려/긍정 60%: 3배 가중치, 시간대별 40%: 2배 가중치
        return [
          ...emotionBodies,
          ...emotionBodies,
          ...emotionBodies,
          ...slotBodies,
          ...slotBodies,
        ];
      case EmotionLevel.medium:
        // 균등 분배
        return [...slotBodies, ...emotionBodies];
    }
  }

  // ===== CBT 카테고리 기반 API =====

  /// 특정 CBT 카테고리의 메시지 반환
  static ({String title, String body}) getMindcareMessageByCategory(
    MindcareCategory category, [
    TimeSlot? slot,
  ]) {
    final timeSlot = slot ?? getCurrentTimeSlot();
    final titles = _getTitlesForSlot(timeSlot);
    final bodies = _mindcareBodiesByCategory[category] ?? _mindcareBodies;

    return (
      title: titles[_random.nextInt(titles.length)],
      body: bodies[_random.nextInt(bodies.length)],
    );
  }

  // ===== 감정 기반 테스트용 접근자 =====

  static List<String> get empathyBodies => List.unmodifiable(_empathyBodies);
  static List<String> get encouragementBodies =>
      List.unmodifiable(_encouragementBodies);

  /// 감정 레벨별 본문 목록 반환 (테스트용)
  static List<String> getBodiesForEmotionLevel(EmotionLevel level) =>
      List.unmodifiable(_getBodiesForEmotionLevel(level));

  /// CBT 카테고리별 본문 목록 반환 (테스트용)
  static List<String> getBodiesForCategory(MindcareCategory category) =>
      List.unmodifiable(_mindcareBodiesByCategory[category] ?? []);

  /// 전체 카테고리 목록 반환 (테스트용)
  static Map<MindcareCategory, List<String>> get mindcareBodiesByCategory =>
      Map.unmodifiable(_mindcareBodiesByCategory);
}
