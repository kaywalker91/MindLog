import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mindlog/core/services/update_service.dart';

void main() {
  group('UpdateConfig', () {
    test('fromJson은 유효한 JSON을 올바르게 파싱한다', () {
      // Given
      final json = {
        'latestVersion': '1.5.0',
        'minSupportedVersion': '1.2.0',
        'forceUpdate': false,
        'androidUrl': 'https://play.google.com/store/apps/details?id=com.example',
        'iosUrl': 'https://apps.apple.com/app/id123456',
        'changelog': {
          '1.5.0': ['새로운 기능 추가', '버그 수정'],
          '1.4.0': ['성능 개선'],
        },
      };

      // When
      final config = UpdateConfig.fromJson(json);

      // Then
      expect(config.latestVersion, '1.5.0');
      expect(config.minSupportedVersion, '1.2.0');
      expect(config.forceUpdate, false);
      expect(config.androidUrl, 'https://play.google.com/store/apps/details?id=com.example');
      expect(config.iosUrl, 'https://apps.apple.com/app/id123456');
      expect(config.changelog['1.5.0'], ['새로운 기능 추가', '버그 수정']);
    });

    test('fromJson은 minSupportedVersion 누락 시 latestVersion을 사용한다', () {
      // Given
      final json = {
        'latestVersion': '1.5.0',
        'forceUpdate': false,
      };

      // When
      final config = UpdateConfig.fromJson(json);

      // Then
      expect(config.minSupportedVersion, '1.5.0');
    });

    test('fromJson은 latestVersion 누락 시 예외를 던진다', () {
      // Given
      final json = {'forceUpdate': false};

      // When & Then
      expect(
        () => UpdateConfig.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson은 빈 latestVersion에 대해 예외를 던진다', () {
      // Given
      final json = {
        'latestVersion': '   ',
        'forceUpdate': false,
      };

      // When & Then
      expect(
        () => UpdateConfig.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('storeUrlFor는 플랫폼별 올바른 URL을 반환한다', () {
      // Given
      final config = UpdateConfig.fromJson({
        'latestVersion': '1.5.0',
        'androidUrl': 'https://android.url',
        'iosUrl': 'https://ios.url',
      });

      // When & Then
      expect(config.storeUrlFor(TargetPlatform.android), 'https://android.url');
      expect(config.storeUrlFor(TargetPlatform.iOS), 'https://ios.url');
    });

    test('storeUrlFor는 해당 플랫폼 URL 없을 시 대체 URL을 반환한다', () {
      // Given: iOS URL만 있는 경우
      final config = UpdateConfig.fromJson({
        'latestVersion': '1.5.0',
        'iosUrl': 'https://ios.url',
      });

      // When & Then: Android 요청 시 iOS URL 반환
      expect(config.storeUrlFor(TargetPlatform.android), 'https://ios.url');
    });

    test('notesFor는 해당 버전의 변경 사항을 반환한다', () {
      // Given
      final config = UpdateConfig.fromJson({
        'latestVersion': '1.5.0',
        'changelog': {
          '1.5.0': ['기능 A', '기능 B'],
        },
      });

      // When & Then
      expect(config.notesFor('1.5.0'), ['기능 A', '기능 B']);
      expect(config.notesFor('1.4.0'), isEmpty);
    });
  });

  group('UpdateService', () {
    late UpdateService service;

    setUp(() {
      service = const UpdateService();
    });

    group('버전 비교 로직 (evaluate)', () {
      test('현재 버전이 최신이면 upToDate를 반환한다', () {
        // Given
        final config = UpdateConfig.fromJson({
          'latestVersion': '1.5.0',
          'minSupportedVersion': '1.2.0',
        });

        // When
        final result = service.evaluate(
          currentVersion: '1.5.0',
          config: config,
        );

        // Then
        expect(result.availability, UpdateAvailability.upToDate);
        expect(result.isRequired, false);
      });

      test('현재 버전이 최신보다 높으면 upToDate를 반환한다', () {
        // Given: 개발 버전이 최신보다 높은 경우
        final config = UpdateConfig.fromJson({
          'latestVersion': '1.5.0',
          'minSupportedVersion': '1.2.0',
        });

        // When
        final result = service.evaluate(
          currentVersion: '1.6.0',
          config: config,
        );

        // Then
        expect(result.availability, UpdateAvailability.upToDate);
      });

      test('현재 버전이 최신보다 낮으면 updateAvailable을 반환한다', () {
        // Given
        final config = UpdateConfig.fromJson({
          'latestVersion': '1.5.0',
          'minSupportedVersion': '1.2.0',
        });

        // When
        final result = service.evaluate(
          currentVersion: '1.4.0',
          config: config,
        );

        // Then
        expect(result.availability, UpdateAvailability.updateAvailable);
        expect(result.isRequired, false);
      });

      test('현재 버전이 최소 지원 버전보다 낮으면 updateRequired를 반환한다', () {
        // Given
        final config = UpdateConfig.fromJson({
          'latestVersion': '1.5.0',
          'minSupportedVersion': '1.2.0',
        });

        // When
        final result = service.evaluate(
          currentVersion: '1.1.0',
          config: config,
        );

        // Then
        expect(result.availability, UpdateAvailability.updateRequired);
        expect(result.isRequired, true);
      });

      test('forceUpdate가 true이면 updateRequired를 반환한다', () {
        // Given
        final config = UpdateConfig.fromJson({
          'latestVersion': '1.5.0',
          'minSupportedVersion': '1.0.0',
          'forceUpdate': true,
        });

        // When
        final result = service.evaluate(
          currentVersion: '1.4.0',
          config: config,
        );

        // Then
        expect(result.availability, UpdateAvailability.updateRequired);
        expect(result.isRequired, true);
      });
    });

    group('버전 문자열 파싱', () {
      test('빌드 번호가 포함된 버전을 올바르게 비교한다', () {
        // Given: 1.4.10+17
        final config = UpdateConfig.fromJson({
          'latestVersion': '1.5.0',
          'minSupportedVersion': '1.3.0',
        });

        // When
        final result = service.evaluate(
          currentVersion: '1.4.10+17',
          config: config,
        );

        // Then: 빌드 번호는 무시되고 1.4.10 < 1.5.0 이므로 updateAvailable
        expect(result.availability, UpdateAvailability.updateAvailable);
      });

      test('다양한 버전 형식을 올바르게 처리한다', () {
        // 1.0 vs 1.0.0
        final config = UpdateConfig.fromJson({
          'latestVersion': '1.0.0',
          'minSupportedVersion': '1.0',
        });

        final result = service.evaluate(
          currentVersion: '1.0',
          config: config,
        );

        expect(result.availability, UpdateAvailability.upToDate);
      });

      test('Major.Minor.Patch 모두 비교한다', () {
        final config = UpdateConfig.fromJson({
          'latestVersion': '2.1.3',
          'minSupportedVersion': '1.0.0',
        });

        // 2.1.2 < 2.1.3
        var result = service.evaluate(currentVersion: '2.1.2', config: config);
        expect(result.availability, UpdateAvailability.updateAvailable);

        // 2.0.9 < 2.1.3
        result = service.evaluate(currentVersion: '2.0.9', config: config);
        expect(result.availability, UpdateAvailability.updateAvailable);

        // 1.9.9 < 2.1.3
        result = service.evaluate(currentVersion: '1.9.9', config: config);
        expect(result.availability, UpdateAvailability.updateAvailable);
      });
    });

    group('fetchConfig', () {
      test('유효한 응답을 올바르게 파싱한다', () async {
        // Given
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'latestVersion': '1.5.0',
              'minSupportedVersion': '1.2.0',
              'forceUpdate': false,
            }),
            200,
            headers: {
              'content-type': 'application/json; charset=utf-8',
            },
          );
        });

        // When
        final config = await service.fetchConfig(client: mockClient);

        // Then
        expect(config.latestVersion, '1.5.0');
        expect(config.minSupportedVersion, '1.2.0');
      });

      test('HTTP 에러 시 예외를 던진다', () async {
        // Given
        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        // When & Then
        expect(
          () => service.fetchConfig(client: mockClient),
          throwsA(isA<Exception>()),
        );
      });

      test('잘못된 JSON 시 예외를 던진다', () async {
        // Given
        final mockClient = MockClient((request) async {
          return http.Response('not valid json', 200);
        });

        // When & Then
        expect(
          () => service.fetchConfig(client: mockClient),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('checkForUpdate', () {
      test('전체 업데이트 확인 플로우가 정상 동작한다', () async {
        // Given
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'latestVersion': '2.0.0',
              'minSupportedVersion': '1.5.0',
              'forceUpdate': false,
              'androidUrl': 'https://play.google.com/test',
              'changelog': {
                '2.0.0': ['새 기능'],
              },
            }),
            200,
            headers: {
              'content-type': 'application/json; charset=utf-8',
            },
          );
        });

        // When
        final result = await service.checkForUpdate(
          currentVersion: '1.4.0',
          client: mockClient,
        );

        // Then
        expect(result.availability, UpdateAvailability.updateRequired);
        expect(result.currentVersion, '1.4.0');
        expect(result.latestVersion, '2.0.0');
        expect(result.minSupportedVersion, '1.5.0');
        expect(result.notes, ['새 기능']);
      });
    });
  });

  group('UpdateCheckResult', () {
    test('isRequired가 올바르게 동작한다', () {
      // Given
      const resultRequired = UpdateCheckResult(
        availability: UpdateAvailability.updateRequired,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        minSupportedVersion: '1.5.0',
        storeUrl: null,
        notes: [],
      );

      const resultAvailable = UpdateCheckResult(
        availability: UpdateAvailability.updateAvailable,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        minSupportedVersion: '0.9.0',
        storeUrl: null,
        notes: [],
      );

      // When & Then
      expect(resultRequired.isRequired, true);
      expect(resultAvailable.isRequired, false);
    });
  });
}
