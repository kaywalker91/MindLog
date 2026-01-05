import 'env_config.dart';

/// 환경 변수 서비스
///
/// 우선순위:
/// 1. --dart-define으로 주입된 값 (EnvConfig) - 보안 권장
///
/// 프로덕션과 개발 환경 모두 --dart-define을 사용하세요.
class EnvironmentService {
  EnvironmentService._();

  static bool _initialized = false;

  /// 환경 변수 초기화
  ///
  /// dart-define만 사용하므로 초기화는 no-op입니다.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// Groq API Key 가져오기 (dart-define)
  static String get groqApiKey {
    return EnvConfig.groqApiKey;
  }

  /// API 키 설정 상태 확인
  static bool get hasValidApiKey => groqApiKey.isNotEmpty;

  /// 현재 환경 변수 소스
  static String get apiKeySource {
    if (EnvConfig.hasValidGroqApiKey) {
      return 'dart-define (secure)';
    }
    return 'not configured';
  }
}
