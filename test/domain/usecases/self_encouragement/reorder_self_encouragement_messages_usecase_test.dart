import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/usecases/self_encouragement/reorder_self_encouragement_messages_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mock_fallbacks.dart';
import '../../../mocks/mock_repositories.dart';

void main() {
  late ReorderSelfEncouragementMessagesUseCase useCase;
  late MockSettingsRepositoryWithMessages mockRepository;

  setUpAll(() {
    registerMockFallbackValues();
  });

  setUp(() {
    mockRepository = MockSettingsRepositoryWithMessages();
    useCase = ReorderSelfEncouragementMessagesUseCase(mockRepository);

    when(
      () => mockRepository.reorderSelfEncouragementMessages(any()),
    ).thenAnswer((_) async {});
  });

  group('ReorderSelfEncouragementMessagesUseCase', () {
    test('정상 순서 리스트를 Repository에 위임해야 한다', () async {
      // Arrange
      final orderedIds = ['b', 'a', 'c'];

      // Act
      await useCase.execute(orderedIds);

      // Assert
      final captured = verify(
        () => mockRepository.reorderSelfEncouragementMessages(captureAny()),
      ).captured;
      expect(captured.single, orderedIds);
    });

    test('빈 리스트는 ValidationFailure를 던져야 한다', () async {
      // Act & Assert
      expect(
        () => useCase.execute(<String>[]),
        throwsA(isA<ValidationFailure>()),
      );
      verifyNever(
        () => mockRepository.reorderSelfEncouragementMessages(any()),
      );
    });

    test('Repository CacheFailure를 그대로 전파해야 한다', () async {
      // Arrange
      when(
        () => mockRepository.reorderSelfEncouragementMessages(any()),
      ).thenThrow(const CacheFailure(message: '저장 실패'));

      // Act & Assert
      expect(
        () => useCase.execute(['a']),
        throwsA(isA<CacheFailure>()),
      );
    });
  });
}
