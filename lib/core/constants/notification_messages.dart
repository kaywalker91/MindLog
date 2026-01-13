import 'dart:math';

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
    '오늘 하루는 어떠셨나요?',
    '오늘 기분이 어떠셨어요?',
    '오늘 하루 수고하셨어요',
    '오늘은 어떤 하루였나요?',
    '오늘의 마음은 어땠나요?',
    '잠시 마음을 들여다볼까요?',
    '하루를 마무리하는 시간',
    '오늘도 고생 많으셨어요',
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

  /// 마음케어 본문 - 격려/자기돌봄/긍정/공감 메시지
  static const List<String> _mindcareBodies = [
    // 격려/응원
    '오늘도 당신의 하루를 응원해요',
    '작은 것에도 감사하는 하루 되세요',
    '당신은 충분히 잘하고 있어요',
    '오늘 하루도 당신을 믿어요',
    '작은 성취도 큰 의미가 있어요',
    // 자기 돌봄
    '잠시 깊게 숨을 쉬어보세요',
    '오늘 자신에게 친절해보세요',
    '충분히 쉬어도 괜찮아요',
    '당신의 감정은 소중해요',
    '자신을 먼저 챙기는 것도 중요해요',
    // 긍정 관점
    '오늘 하루도 새로운 시작이에요',
    '작은 행복을 발견해보세요',
    '좋은 일이 기다리고 있을 거예요',
    '오늘도 소중한 하루가 될 거예요',
    '당신의 존재 자체가 의미 있어요',
    // 공감/위로
    '힘든 날도 지나갈 거예요',
    '지치면 잠시 쉬어가도 괜찮아요',
    '완벽하지 않아도 괜찮아요',
    '당신의 마음을 응원해요',
    '오늘도 수고한 당신에게 박수를',
  ];

  // ===== 리마인더 API =====

  /// 랜덤 리마인더 제목 반환
  static String getRandomReminderTitle() =>
      _reminderTitles[_random.nextInt(_reminderTitles.length)];

  /// 랜덤 리마인더 본문 반환
  static String getRandomReminderBody() =>
      _reminderBodies[_random.nextInt(_reminderBodies.length)];

  /// 랜덤 리마인더 메시지 쌍 반환
  static ({String title, String body}) getRandomReminderMessage() => (
        title: getRandomReminderTitle(),
        body: getRandomReminderBody(),
      );

  // ===== 마음케어 API =====

  /// 랜덤 마음케어 제목 반환
  static String getRandomMindcareTitle() =>
      _mindcareTitles[_random.nextInt(_mindcareTitles.length)];

  /// 랜덤 마음케어 본문 반환
  static String getRandomMindcareBody() =>
      _mindcareBodies[_random.nextInt(_mindcareBodies.length)];

  /// 랜덤 마음케어 메시지 쌍 반환
  static ({String title, String body}) getRandomMindcareMessage() => (
        title: getRandomMindcareTitle(),
        body: getRandomMindcareBody(),
      );

  // ===== 테스트용 접근자 =====

  static List<String> get reminderTitles => List.unmodifiable(_reminderTitles);
  static List<String> get reminderBodies => List.unmodifiable(_reminderBodies);
  static List<String> get mindcareTitles => List.unmodifiable(_mindcareTitles);
  static List<String> get mindcareBodies => List.unmodifiable(_mindcareBodies);
}
