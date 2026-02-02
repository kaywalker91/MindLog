import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/update_service.dart';
import 'package:mindlog/presentation/providers/update_state_provider.dart';

void main() {
  group('UpdateState.shouldShowBadge', () {
    group('24시간 suppress 로직', () {
      test('dismiss되지 않은 업데이트는 뱃지가 표시되어야 한다', () {
        // Arrange
        const state = UpdateState(
          result: UpdateCheckResult(
            availability: UpdateAvailability.updateAvailable,
            currentVersion: '1.0.0',
            latestVersion: '1.1.0',
            minSupportedVersion: '1.0.0',
            storeUrl: 'https://example.com',
            notes: [],
          ),
          dismissedVersion: null,
          dismissedAt: null,
        );

        // Assert
        expect(state.shouldShowBadge, isTrue);
      });

      test('다른 버전으로 dismiss된 경우 뱃지가 표시되어야 한다', () {
        // Arrange
        const state = UpdateState(
          result: UpdateCheckResult(
            availability: UpdateAvailability.updateAvailable,
            currentVersion: '1.0.0',
            latestVersion: '1.2.0',
            minSupportedVersion: '1.0.0',
            storeUrl: 'https://example.com',
            notes: [],
          ),
          dismissedVersion: '1.1.0', // 이전 버전 dismiss
          dismissedAt: null,
        );

        // Assert
        expect(state.shouldShowBadge, isTrue);
      });

      test('같은 버전이 dismiss된 후 24시간 미경과 시 뱃지가 숨겨져야 한다', () {
        // Arrange
        final now = DateTime.now();
        final state = UpdateState(
          result: const UpdateCheckResult(
            availability: UpdateAvailability.updateAvailable,
            currentVersion: '1.0.0',
            latestVersion: '1.1.0',
            minSupportedVersion: '1.0.0',
            storeUrl: 'https://example.com',
            notes: [],
          ),
          dismissedVersion: '1.1.0',
          dismissedAt: now.subtract(const Duration(hours: 12)), // 12시간 전
        );

        // Assert
        expect(state.shouldShowBadge, isFalse);
      });

      test('같은 버전이 dismiss된 후 24시간 경과 시 뱃지가 다시 표시되어야 한다', () {
        // Arrange
        final state = UpdateState(
          result: const UpdateCheckResult(
            availability: UpdateAvailability.updateAvailable,
            currentVersion: '1.0.0',
            latestVersion: '1.1.0',
            minSupportedVersion: '1.0.0',
            storeUrl: 'https://example.com',
            notes: [],
          ),
          dismissedVersion: '1.1.0',
          dismissedAt: DateTime.now().subtract(const Duration(hours: 25)), // 25시간 전
        );

        // Assert
        expect(state.shouldShowBadge, isTrue);
      });

      test('dismiss timestamp 없이 버전만 있으면 뱃지가 숨겨져야 한다 (하위 호환)', () {
        // Arrange - 기존 데이터 마이그레이션 시나리오
        const state = UpdateState(
          result: UpdateCheckResult(
            availability: UpdateAvailability.updateAvailable,
            currentVersion: '1.0.0',
            latestVersion: '1.1.0',
            minSupportedVersion: '1.0.0',
            storeUrl: 'https://example.com',
            notes: [],
          ),
          dismissedVersion: '1.1.0',
          dismissedAt: null, // timestamp 없음
        );

        // Assert - 하위 호환성: 기존처럼 숨김 처리
        expect(state.shouldShowBadge, isFalse);
      });

      test('최신 버전일 때는 뱃지가 표시되지 않아야 한다', () {
        // Arrange
        const state = UpdateState(
          result: UpdateCheckResult(
            availability: UpdateAvailability.upToDate,
            currentVersion: '1.1.0',
            latestVersion: '1.1.0',
            minSupportedVersion: '1.0.0',
            storeUrl: 'https://example.com',
            notes: [],
          ),
        );

        // Assert
        expect(state.shouldShowBadge, isFalse);
      });

      test('result가 null이면 뱃지가 표시되지 않아야 한다', () {
        // Arrange
        const state = UpdateState(result: null);

        // Assert
        expect(state.shouldShowBadge, isFalse);
      });
    });

    group('hasUpdate 검사', () {
      test('updateAvailable 상태면 hasUpdate가 true여야 한다', () {
        const state = UpdateState(
          result: UpdateCheckResult(
            availability: UpdateAvailability.updateAvailable,
            currentVersion: '1.0.0',
            latestVersion: '1.1.0',
            minSupportedVersion: '1.0.0',
            storeUrl: 'https://example.com',
            notes: [],
          ),
        );

        expect(state.hasUpdate, isTrue);
      });

      test('updateRequired 상태면 hasUpdate가 true여야 한다', () {
        const state = UpdateState(
          result: UpdateCheckResult(
            availability: UpdateAvailability.updateRequired,
            currentVersion: '1.0.0',
            latestVersion: '1.1.0',
            minSupportedVersion: '1.1.0',
            storeUrl: 'https://example.com',
            notes: [],
          ),
        );

        expect(state.hasUpdate, isTrue);
      });

      test('upToDate 상태면 hasUpdate가 false여야 한다', () {
        const state = UpdateState(
          result: UpdateCheckResult(
            availability: UpdateAvailability.upToDate,
            currentVersion: '1.1.0',
            latestVersion: '1.1.0',
            minSupportedVersion: '1.0.0',
            storeUrl: 'https://example.com',
            notes: [],
          ),
        );

        expect(state.hasUpdate, isFalse);
      });
    });

    group('copyWith', () {
      test('clearDismissed가 true면 dismiss 상태가 초기화되어야 한다', () {
        // Arrange
        final state = UpdateState(
          result: const UpdateCheckResult(
            availability: UpdateAvailability.updateAvailable,
            currentVersion: '1.0.0',
            latestVersion: '1.1.0',
            minSupportedVersion: '1.0.0',
            storeUrl: 'https://example.com',
            notes: [],
          ),
          dismissedVersion: '1.1.0',
          dismissedAt: DateTime.now(),
        );

        // Act
        final newState = state.copyWith(clearDismissed: true);

        // Assert
        expect(newState.dismissedVersion, isNull);
        expect(newState.dismissedAt, isNull);
      });

      test('dismissedAt을 유지하면서 다른 필드만 업데이트해야 한다', () {
        // Arrange
        final now = DateTime.now();
        final state = UpdateState(
          dismissedVersion: '1.0.0',
          dismissedAt: now,
        );

        // Act
        final newState = state.copyWith(isLoading: true);

        // Assert
        expect(newState.isLoading, isTrue);
        expect(newState.dismissedVersion, equals('1.0.0'));
        expect(newState.dismissedAt, equals(now));
      });
    });

    group('suppressDuration 상수', () {
      test('suppressDuration이 24시간이어야 한다', () {
        expect(UpdateState.suppressDuration, equals(const Duration(hours: 24)));
      });
    });
  });
}
