/// 앱 전역 상수
class AppConstants {
  AppConstants._();

  // 앱 정보
  static const String appName = 'MindLog';
  static const String appVersion = '1.0.0';

  // 일기 입력 제한
  static const int diaryMinLength = 10;
  static const int diaryMaxLength = 1000;

  // Gemini API 설정
  static const String geminiModel = 'gemini-1.5-flash';

  // 감정 점수 범위
  static const int sentimentScoreMin = 1;
  static const int sentimentScoreMax = 10;
}
