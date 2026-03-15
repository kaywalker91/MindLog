import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/usecases/secret/set_diary_secret_usecase.dart';

import '../../../helpers/mock_fallbacks.dart';
import '../../../mocks/mock_repositories.dart';

void main() {
  late SetDiarySecretUseCase useCase;
  late MockDiaryRepository mockRepository;

  setUpAll(() {
    registerMockFallbackValues();
  });

  setUp(() {
    mockRepository = MockDiaryRepository();
    useCase = SetDiarySecretUseCase(mockRepository);

    when(
      () => mockRepository.setDiarySecret(any(), any()),
    ).thenAnswer((_) async {});
  });

  group('SetDiarySecretUseCase', () {
    group('정상 케이스', () {
      test('should set diary as secret when valid diaryId provided', () async {
        // Arrange
        const diaryId = 'diary-001';

        // Act
        await useCase.execute(diaryId, isSecret: true);

        // Assert
        verify(
          () => mockRepository.setDiarySecret('diary-001', true),
        ).called(1);
      });

      test('should unset diary secret when isSecret is false', () async {
        // Arrange
        const diaryId = 'diary-001';

        // Act
        await useCase.execute(diaryId, isSecret: false);

        // Assert
        verify(
          () => mockRepository.setDiarySecret('diary-001', false),
        ).called(1);
      });
    });

    group('입력 유효성 검사', () {
      test('should throw ValidationFailure when diaryId is empty', () async {
        // Act & Assert
        expect(
          () => useCase.execute('', isSecret: true),
          throwsA(isA<ValidationFailure>()),
        );
        verifyNever(() => mockRepository.setDiarySecret(any(), any()));
      });
    });

    group('오류 처리', () {
      test('should rethrow Failure from repository', () async {
        // Arrange
        when(
          () => mockRepository.setDiarySecret(any(), any()),
        ).thenThrow(const CacheFailure(message: '저장 실패'));

        // Act & Assert
        expect(
          () => useCase.execute('diary-001', isSecret: true),
          throwsA(isA<CacheFailure>()),
        );
      });

      test('should wrap unknown exception as UnknownFailure', () async {
        // Arrange
        when(
          () => mockRepository.setDiarySecret(any(), any()),
        ).thenThrow(Exception('generic error'));

        // Act & Assert
        expect(
          () => useCase.execute('diary-001', isSecret: true),
          throwsA(isA<UnknownFailure>()),
        );
      });
    });
  });
}
