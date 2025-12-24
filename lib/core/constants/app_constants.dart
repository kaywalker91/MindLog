

/// 앱 전역 상수
class AppConstants {
  AppConstants._();

  // 앱 정보
  static const String _appName = 'MindLog';
  static const String _appVersion = '1.0.0';
  static const String _appNameLong = 'MindLog - 마음 케어 다이어리';
  static const String _updateConfigUrl = 'https://kaywalker91.github.io/MindLog/update.json';

  // 일기 입력 제한
  static const int _diaryMinLength = 10;
  static const int _diaryMaxLength = 5000;

  // Gemini API 설정
  // 최신 Gemini 1.5 Flash Stable 버전 (alias 문제 해결)
  static const String _geminiModel = 'gemini-1.5-flash-002';
  
  // Groq Model (최신 안정 버전)
  static const String _groqModel = 'llama-3.3-70b-versatile';
  
  // 감정 점수 범위
  static const int _sentimentScoreMin = 1;
  static const int _sentimentScoreMax = 10;

  /// 앱 이름
  static String get appName => _appName;
  
  /// 앱 전체 버전명
  static String get appVersion => _appVersion;
  
  /// 앱 상세 이름 (표시용)
  static String get appNameLong => _appNameLong;

  /// 업데이트 설정 JSON URL
  static String get updateConfigUrl => _updateConfigUrl;
  
  /// 일기 최소 길이
  static int get diaryMinLength => _diaryMinLength;
  
  /// 일기 최대 길이
  static int get diaryMaxLength => _diaryMaxLength;
  
  /// Gemini API 모델
  static String get geminiModel => _geminiModel;

  /// Groq Model
  static String get groqModel => _groqModel;
  
  /// 감정 점수 범위
  static int get sentimentScoreMin => _sentimentScoreMin;
  static int get sentimentScoreMax => _sentimentScoreMax;
}
