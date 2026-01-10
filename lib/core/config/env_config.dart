import 'package:flutter/foundation.dart';

/// 환경 변수 설정 클래스
///
/// 빌드 타임에 --dart-define으로 주입된 환경 변수를 관리합니다.
/// 보안상 .env 파일을 assets에 포함하지 않고, 빌드 시점에 주입합니다.
///
/// 사용법:
/// ```bash
/// # 개발 환경
/// flutter run --dart-define=GROQ_API_KEY=your_key
///
/// # 릴리즈 빌드
/// flutter build apk --dart-define=GROQ_API_KEY=your_key
/// ```
///
/// 로컬 개발 환경:
/// lib/core/config/dev_api_keys.dart 파일을 생성하고 API 키를 설정하세요.
/// dev_api_keys.example.dart를 참고하세요.
class EnvConfig {
  EnvConfig._();

  /// dart-define으로 주입된 Groq API Key
  static const String _dartDefineApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  /// 개발용 API 키 (dart-define으로도 주입 가능)
  static const String _devApiKey = String.fromEnvironment(
    'DEV_GROQ_API_KEY',
    defaultValue: '',
  );

  /// Groq API Key 가져오기
  /// 우선순위: GROQ_API_KEY > DEV_GROQ_API_KEY
  static String get groqApiKey {
    // 1. dart-define으로 주입된 값 우선
    if (_dartDefineApiKey.isNotEmpty) {
      return _dartDefineApiKey;
    }

    // 2. 개발용 키 폴백 (debug 모드에서만)
    if (kDebugMode && _devApiKey.isNotEmpty) {
      return _devApiKey;
    }

    return '';
  }

  /// 개발 모드 여부
  static const bool isDevelopment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  ) == 'development';

  /// API 키 유효성 검사
  static bool get hasValidGroqApiKey => groqApiKey.isNotEmpty;

  /// API 키 소스 정보 (디버깅용)
  static String get apiKeySource {
    if (_dartDefineApiKey.isNotEmpty) {
      return 'dart-define';
    }
    if (kDebugMode && _devApiKey.isNotEmpty) {
      return 'DEV_GROQ_API_KEY (development only)';
    }
    return 'not configured';
  }

  /// 디버그 정보 (API 키 마스킹)
  static String get debugInfo {
    final key = groqApiKey;
    final maskedKey = key.isEmpty
        ? '(not set)'
        : '${key.substring(0, 4)}****';

    return '''
EnvConfig:
  - GROQ_API_KEY: $maskedKey
  - Source: $apiKeySource
  - Environment: ${isDevelopment ? 'Development' : 'Production'}
''';
  }
}

