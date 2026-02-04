import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/config/env_config.dart';
import 'package:mindlog/core/config/environment_service.dart';

void main() {
  group('EnvConfig', () {
    test('groqApiKey는 문자열을 반환한다', () {
      // dart-define 또는 dev_api_keys.dart에서 가져옴
      final key = EnvConfig.groqApiKey;
      expect(key, isA<String>());
    });

    test('hasValidGroqApiKey는 API 키 존재 여부에 따라 적절한 값을 반환한다', () {
      // dev_api_keys.dart에 키가 설정되어 있으면 true, 아니면 false
      final isValid = EnvConfig.hasValidGroqApiKey;
      expect(isValid, equals(EnvConfig.groqApiKey.isNotEmpty));
    });

    test('isDevelopment 기본값은 true (development)이다', () {
      expect(EnvConfig.isDevelopment, isTrue);
    });

    test('debugInfo는 API 키 정보를 포함한다', () {
      final info = EnvConfig.debugInfo;
      expect(info, contains('GROQ_API_KEY'));
      // 키가 설정되어 있으면 마스킹됨, 아니면 '(not set)'
      if (EnvConfig.groqApiKey.isEmpty) {
        expect(info, contains('(not set)'));
      } else {
        expect(info, contains('****'));
      }
    });

    test('apiKeySource는 설정 상태를 나타낸다', () {
      final source = EnvConfig.apiKeySource;
      expect(source, isA<String>());
      expect(
        source,
        anyOf([
          'dart-define',
          'DEV_GROQ_API_KEY (development only)',
          'not configured',
        ]),
      );
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
      expect(source, anyOf(['dart-define (secure)', 'not configured']));
    });
  });
}
