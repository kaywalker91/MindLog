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
class EnvConfig {
  EnvConfig._();

  /// Groq API Key (Primary AI Provider)
  /// --dart-define=GROQ_API_KEY=xxx 로 주입
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  /// 개발 모드 여부
  static const bool isDevelopment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  ) == 'development';

  /// API 키 유효성 검사
  static bool get hasValidGroqApiKey => groqApiKey.isNotEmpty;

  /// 디버그 정보 (API 키 마스킹)
  static String get debugInfo {
    final groqMasked = groqApiKey.isEmpty
        ? '(not set)'
        : '${groqApiKey.substring(0, 4)}****';

    return '''
EnvConfig:
  - GROQ_API_KEY: $groqMasked
  - Environment: ${isDevelopment ? 'Development' : 'Production'}
''';
  }
}
