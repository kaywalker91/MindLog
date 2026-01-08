// import 'dev_api_keys.dart' as dev_keys;

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
/// 개발 환경 폴백:
/// dart-define이 없으면 lib/core/config/dev_api_keys.dart에서 읽습니다.
/// dev_api_keys.dart는 .gitignore에 포함되어 있습니다.
class EnvConfig {
  EnvConfig._();

  /// dart-define으로 주입된 Groq API Key
  static const String _dartDefineApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  /// Groq API Key 가져오기
  /// 우선순위: dart-define > dev_api_keys.dart (개발용)
  static String get groqApiKey {
    // 1. dart-define으로 주입된 값 우선
    if (_dartDefineApiKey.isNotEmpty) {
      return _dartDefineApiKey;
    }

    // 2. 개발 모드에서만 dev_api_keys.dart 폴백 (CI 빌드 오류로 인해 주석 처리)
    // if (kDebugMode && dev_keys.devGroqApiKey.isNotEmpty) {
    //   return dev_keys.devGroqApiKey;
    // }

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
    // if (kDebugMode && dev_keys.devGroqApiKey.isNotEmpty) {
    //   return 'dev_api_keys.dart (development only)';
    // }
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

