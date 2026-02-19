import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/usecases/secret/set_diary_secret_usecase.dart';

import '../../../mocks/mock_repositories.dart';

void main() {
  late SetDiarySecretUseCase useCase;
  late MockDiaryRepository mockRepository;

  setUp(() {
    mockRepository = MockDiaryRepository();
    useCase = SetDiarySecretUseCase(mockRepository);
  });

  group('SetDiarySecretUseCase', () {
    group('정상 케이스', () {
      test('should set diary as secret when valid diaryId provided', () async {
        // Arrange
        const diaryId = 'diary-001';

        // Act
        await useCase.execute(diaryId, isSecret: true);

        // Assert
        expect(mockRepository.setSecretCalls, contains(diaryId));
        expect(mockRepository.setSecretValues[diaryId], true);
      });

      test('should unset diary secret when isSecret is false', () async {
        // Arrange
        const diaryId = 'diary-001';

        // Act
        await useCase.execute(diaryId, isSecret: false);

        // Assert
        expect(mockRepository.setSecretCalls, contains(diaryId));
        expect(mockRepository.setSecretValues[diaryId], false);
      });
    });

    group('입력 유효성 검사', () {
      test('should throw ValidationFailure when diaryId is empty', () async {
        // Act & Assert
        expect(
          () => useCase.execute('', isSecret: true),
          throwsA(isA<ValidationFailure>()),
        );
        expect(mockRepository.setSecretCalls, isEmpty);
      });
    });

    group('오류 처리', () {
      test('should rethrow Failure from repository', () async {
        // Arrange
        mockRepository.shouldThrowOnUpdate = true;
        mockRepository.failureToThrow = const CacheFailure(message: '저장 실패');

        // Act & Assert
        expect(
          () => useCase.execute('diary-001', isSecret: true),
          throwsA(isA<CacheFailure>()),
        );
      });

      test('should wrap unknown exception as UnknownFailure', () async {
        // Arrange
        mockRepository.shouldThrowGenericError = true;

        // Act & Assert
        expect(
          () => useCase.execute('diary-001', isSecret: true),
          throwsA(isA<UnknownFailure>()),
        );
      });
    });
  });
}
