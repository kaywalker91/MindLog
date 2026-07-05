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

  // Groq Model (최신 안정 버전)
  static const String _groqModel = 'openai/gpt-oss-120b';

  // Groq Vision Model (이미지 분석용)
  static const String _groqVisionModel = 'qwen/qwen3.6-27b';

  // 이미지 설정
  static const int _maxImagesPerDiary = 5;

  /// Vision API로 전송하는 이미지 상한 (저장 한도와 분리)
  ///
  /// Groq 무료 티어 8K TPM — 복수 이미지 시 413 발생. 대표 1장만 전송한다.
  static const int _maxImagesPerVisionAnalysis = 1;
  static const int _maxImageSizeBytes =
      4 * 1024 * 1024; // 4MB (Groq Vision API 제한)
  static const int _imageCompressQuality = 85;
  static const int _imageMaxWidth = 1920;

  // Vision API 전송용 (저장 품질과 분리 — Groq 8K TPM 한도 대응)
  static const int _visionImageMaxWidth = 384;
  static const int _visionCompressQuality = 55;

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

  /// Groq Model
  static String get groqModel => _groqModel;

  /// Groq Vision Model (이미지 분석용)
  static String get groqVisionModel => _groqVisionModel;

  /// 일기당 최대 이미지 수 (저장·갤러리)
  static int get maxImagesPerDiary => _maxImagesPerDiary;

  /// Vision API 분석에 전송하는 최대 이미지 수
  static int get maxImagesPerVisionAnalysis => _maxImagesPerVisionAnalysis;

  /// 이미지 최대 크기 (바이트)
  static int get maxImageSizeBytes => _maxImageSizeBytes;

  /// 이미지 압축 품질 (0-100)
  static int get imageCompressQuality => _imageCompressQuality;

  /// 이미지 최대 너비 (픽셀)
  static int get imageMaxWidth => _imageMaxWidth;

  /// Vision API 전송용 최대 너비 (픽셀) — TPM 413 방지
  static int get visionImageMaxWidth => _visionImageMaxWidth;

  /// Vision API 전송용 JPEG 품질 (0-100)
  static int get visionCompressQuality => _visionCompressQuality;

  /// 감정 점수 범위
  static int get sentimentScoreMin => _sentimentScoreMin;
  static int get sentimentScoreMax => _sentimentScoreMax;
}
