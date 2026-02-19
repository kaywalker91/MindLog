import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/usecases/secret/verify_secret_pin_usecase.dart';

import '../../../mocks/mock_repositories.dart';

void main() {
  late VerifySecretPinUseCase useCase;
  late MockSecretPinRepository mockRepository;

  setUp(() {
    mockRepository = MockSecretPinRepository();
    useCase = VerifySecretPinUseCase(mockRepository);
  });

  group('VerifySecretPinUseCase', () {
    group('정상 케이스', () {
      test('should return true when correct PIN is provided', () async {
        // Arrange
        mockRepository.correctPin = '1234';

        // Act
        final result = await useCase.execute('1234');

        // Assert
        expect(result, true);
      });

      test('should return false when incorrect PIN is provided', () async {
        // Arrange
        mockRepository.correctPin = '1234';

        // Act
        final result = await useCase.execute('9999');

        // Assert
        expect(result, false);
      });

      test('should return false when no PIN is set', () async {
        // Arrange
        mockRepository.correctPin = null; // PIN 미설정

        // Act
        final result = await useCase.execute('1234');

        // Assert
        expect(result, false);
      });
    });

    group('입력 유효성 검사', () {
      test('should throw ValidationFailure when PIN is not 4 digits', () async {
        expect(() => useCase.execute('123'), throwsA(isA<ValidationFailure>()));
      });

      test('should throw ValidationFailure when PIN is 5 digits', () async {
        expect(
          () => useCase.execute('12345'),
          throwsA(isA<ValidationFailure>()),
        );
      });

      test(
        'should throw ValidationFailure when PIN contains non-digits',
        () async {
          expect(
            () => useCase.execute('12ab'),
            throwsA(isA<ValidationFailure>()),
          );
        },
      );

      test('should throw ValidationFailure when PIN is empty', () async {
        expect(() => useCase.execute(''), throwsA(isA<ValidationFailure>()));
      });
    });

    group('오류 처리', () {
      test('should rethrow Failure from repository', () async {
        // Arrange
        mockRepository.shouldThrow = true;
        mockRepository.failureToThrow = const CacheFailure(message: '검증 실패');

        // Act & Assert
        expect(() => useCase.execute('1234'), throwsA(isA<CacheFailure>()));
      });
    });
  });
}
