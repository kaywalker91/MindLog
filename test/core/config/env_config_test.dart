import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/config/env_config.dart';
import 'package:mindlog/core/config/environment_service.dart';

void main() {
  group('EnvConfig', () {
    test('groqApiKey는 빈 문자열이 기본값이다', () {
      // dart-define 없이 실행 시 빈 문자열
      expect(EnvConfig.groqApiKey, isEmpty);
    });

    test('hasValidGroqApiKey는 빈 API 키에 대해 false를 반환한다', () {
      expect(EnvConfig.hasValidGroqApiKey, isFalse);
    });

    test('isDevelopment 기본값은 true (development)이다', () {
      expect(EnvConfig.isDevelopment, isTrue);
    });

    test('debugInfo는 마스킹된 정보를 포함한다', () {
      final info = EnvConfig.debugInfo;
      expect(info, contains('GROQ_API_KEY'));
      expect(info, contains('(not set)'));
    });
  });

  group('EnvironmentService', () {
    setUpAll(() async {
      // 테스트 환경에서 dart-define 기반 초기화만 수행
      await EnvironmentService.initialize();
    });

    test('groqApiKey는 문자열을 반환한다', () {
      // EnvironmentService는 EnvConfig에서 값을 가져옴
      final key = EnvironmentService.groqApiKey;
      expect(key, isA<String>());
    });

    test('apiKeySource는 설정 상태를 나타내는 문자열을 반환한다', () {
      final source = EnvironmentService.apiKeySource;
      expect(source, isA<String>());
      // 테스트 환경에서는 dart-define 없이 실행되므로
      expect(
        source,
        anyOf([
          'dart-define (secure)',
          'not configured',
        ]),
      );
    });
  });
}
