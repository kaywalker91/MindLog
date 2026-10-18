/// 앱 전역 상수
class AppConstants {
  AppConstants._();

  // 앱 정보
  static const String _appName = 'MindLog';
  static const String _appVersion = '1.4.6';
  static const String _appNameLong = 'MindLog - 마음 케어 다이어리';
  static const String _updateConfigUrl =
      'https://kaywalker91.github.io/MindLog/update.json';

  // 일기 입력 제한
  static const int _diaryMinLength = 10;
  static const int _diaryMaxLength = 5000;

  // 일기 임시저장(Draft) — REQ-006
  // 초안은 min length를 적용하지 않는다 (10자는 제출 게이트이지 초안 게이트가 아님)
  static const int _diaryDraftTtlDays = 7;
  static const int _diaryDraftDebounceMs = 800;

  // Groq Model (최신 안정 버전)
  static const String _groqModel = 'openai/gpt-oss-120b';

  // 이미지 설정
  static const int _maxImagesPerDiary = 5;

  static const int _maxImageSizeBytes = 4 * 1024 * 1024; // 4MB (로컬 사진 저장 상한)
  static const int _imageCompressQuality = 85;
  static const int _imageMaxWidth = 1920;

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

  /// 임시저장 초안 보존 기간 (경과 시 조회하며 자동 폐기)
  static Duration get diaryDraftTtl => const Duration(days: _diaryDraftTtlDays);

  /// 임시저장 텍스트 디바운스 간격
  static Duration get diaryDraftDebounce =>
      const Duration(milliseconds: _diaryDraftDebounceMs);

  /// Groq Model
  static String get groqModel => _groqModel;

  /// 일기당 최대 이미지 수 (저장·갤러리)
  static int get maxImagesPerDiary => _maxImagesPerDiary;

  /// 이미지 최대 크기 (바이트)
  static int get maxImageSizeBytes => _maxImageSizeBytes;

  /// 이미지 압축 품질 (0-100)
  static int get imageCompressQuality => _imageCompressQuality;

  /// 이미지 최대 너비 (픽셀)
  static int get imageMaxWidth => _imageMaxWidth;

  /// 감정 점수 범위
  static int get sentimentScoreMin => _sentimentScoreMin;
  static int get sentimentScoreMax => _sentimentScoreMax;
}
