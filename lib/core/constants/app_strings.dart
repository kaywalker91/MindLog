/// 앱 내 문자열 상수
class AppStrings {
  AppStrings._();

  // 화면 타이틀
  static const String appName = 'MindLog';
  static const String diaryScreenTitle = '오늘의 마음';
  static const String historyScreenTitle = '기록';
  static const String resultScreenTitle = '분석 결과';

  // 버튼 텍스트
  static const String submitButton = '마음 털어놓기';
  static const String tryAgainButton = '다시 시도하기';
  static const String closeButton = '닫기';

  // 플레이스홀더
  static const String diaryHint = '오늘 하루 어떠셨나요? 마음 속 이야기를 자유롭게 적어보세요...';

  // 에러 메시지
  static const String errorMinLength = '최소 10자 이상 입력해주세요.';
  static const String errorMaxLength = '최대 1,000자까지 입력 가능합니다.';
  static const String errorNetworkFailed = '네트워크 연결을 확인해주세요.';
  static const String errorApiKeyMissing = 'API 키가 설정되지 않았습니다.';
  static const String errorAnalysisFailed = '분석 중 오류가 발생했습니다.';

  // SOS 카드 메시지
  static const String sosTitle = '당신의 마음이 걱정됩니다';
  static const String sosMessage = '힘든 시간을 보내고 계신 것 같아요. 전문가의 도움을 받아보시는 건 어떨까요?';
  static const String sosHotline = '자살예방상담전화: 1393';
  static const String sosMentalHealth = '정신건강위기상담전화: 1577-0199';

  // 분석 결과 레이블
  static const String keywordsLabel = '감정 키워드';
  static const String sentimentLabel = '감정 온도';
  static const String empathyLabel = '위로의 말';
  static const String actionLabel = '추천 액션';
}
