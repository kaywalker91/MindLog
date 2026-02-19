import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/usecases/secret/verify_secret_pin_usecase.dart';
import 'package:mindlog/presentation/providers/secret_auth_provider.dart';
import 'package:mindlog/presentation/providers/secret_diary_providers.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  late ProviderContainer container;
  late MockSecretPinRepository mockPinRepository;

  setUp(() {
    mockPinRepository = MockSecretPinRepository();
    container = ProviderContainer(
      overrides: [
        secretPinRepositoryProvider.overrideWithValue(mockPinRepository),
      ],
    );
  });

  tearDown(() {
    mockPinRepository.reset();
    container.dispose();
  });

  group('SecretAuthNotifier', () {
    group('초기 상태', () {
      test('앱 시작 시 항상 잠금 상태(false)여야 한다', () {
        final isUnlocked = container.read(secretAuthProvider);
        expect(isUnlocked, isFalse);
      });
    });

    group('unlock', () {
      test('올바른 PIN으로 잠금 해제 시 상태가 true가 되어야 한다', () async {
        // Arrange
        mockPinRepository.correctPin = '1234';
        final verifyUseCase = container.read(verifySecretPinUseCaseProvider);

        // Act
        final result = await container
            .read(secretAuthProvider.notifier)
            .unlock('1234', verifyUseCase);

        // Assert
        expect(result, isTrue);
        expect(container.read(secretAuthProvider), isTrue);
      });

      test('잘못된 PIN으로 잠금 해제 시 상태가 false를 유지해야 한다', () async {
        // Arrange
        mockPinRepository.correctPin = '1234';
        final verifyUseCase = container.read(verifySecretPinUseCaseProvider);

        // Act
        final result = await container
            .read(secretAuthProvider.notifier)
            .unlock('9999', verifyUseCase);

        // Assert
        expect(result, isFalse);
        expect(container.read(secretAuthProvider), isFalse);
      });

      test('PIN 미설정 시 잠금 해제가 실패해야 한다', () async {
        // Arrange — correctPin = null (미설정)
        final verifyUseCase = container.read(verifySecretPinUseCaseProvider);

        // Act
        final result = await container
            .read(secretAuthProvider.notifier)
            .unlock('1234', verifyUseCase);

        // Assert
        expect(result, isFalse);
        expect(container.read(secretAuthProvider), isFalse);
      });

      test('유효하지 않은 PIN(4자리 미만)으로 잠금 해제 시 예외가 발생해야 한다', () async {
        // Arrange
        mockPinRepository.correctPin = '1234';
        final verifyUseCase = VerifySecretPinUseCase(mockPinRepository);

        // Act & Assert
        expect(
          () => container
              .read(secretAuthProvider.notifier)
              .unlock('12', verifyUseCase),
          throwsA(anything),
        );
      });
    });

    group('lock', () {
      test('잠금 해제 후 lock() 호출 시 상태가 false로 돌아와야 한다', () async {
        // Arrange — 먼저 잠금 해제
        mockPinRepository.correctPin = '1234';
        final verifyUseCase = container.read(verifySecretPinUseCaseProvider);
        await container
            .read(secretAuthProvider.notifier)
            .unlock('1234', verifyUseCase);
        expect(container.read(secretAuthProvider), isTrue);

        // Act
        container.read(secretAuthProvider.notifier).lock();

        // Assert
        expect(container.read(secretAuthProvider), isFalse);
      });
    });
  });
}
