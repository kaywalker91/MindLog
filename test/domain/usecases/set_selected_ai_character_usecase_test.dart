import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/usecases/set_selected_ai_character_usecase.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  late SetSelectedAiCharacterUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = SetSelectedAiCharacterUseCase(mockRepository);
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('SetSelectedAiCharacterUseCase', () {
    group('execute', () {
      test('Repository에 AI 캐릭터를 저장해야 한다', () async {
        // Arrange & Act
        await useCase.execute(AiCharacter.warmCounselor);

        // Assert
        final savedCharacter = await mockRepository.getSelectedAiCharacter();
        expect(savedCharacter, AiCharacter.warmCounselor);
      });

      test('realisticCoach 캐릭터를 저장해야 한다', () async {
        // Arrange & Act
        await useCase.execute(AiCharacter.realisticCoach);

        // Assert
        final savedCharacter = await mockRepository.getSelectedAiCharacter();
        expect(savedCharacter, AiCharacter.realisticCoach);
      });

      test('cheerfulFriend 캐릭터를 저장해야 한다', () async {
        // Arrange & Act
        await useCase.execute(AiCharacter.cheerfulFriend);

        // Assert
        final savedCharacter = await mockRepository.getSelectedAiCharacter();
        expect(savedCharacter, AiCharacter.cheerfulFriend);
      });

      test('Repository 에러 시 예외를 전파해야 한다', () async {
        // Arrange
        mockRepository.shouldThrowOnSet = true;
        mockRepository.failureToThrow = const Failure.cache(
          message: '캐릭터 저장 실패',
        );

        // Act & Assert
        await expectLater(
          useCase.execute(AiCharacter.warmCounselor),
          throwsA(isA<CacheFailure>()),
        );
      });

      test('연속 설정 변경이 올바르게 동작해야 한다', () async {
        // Arrange & Act
        await useCase.execute(AiCharacter.warmCounselor);
        await useCase.execute(AiCharacter.realisticCoach);
        await useCase.execute(AiCharacter.cheerfulFriend);

        // Assert
        final savedCharacter = await mockRepository.getSelectedAiCharacter();
        expect(savedCharacter, AiCharacter.cheerfulFriend);
      });
    });
  });
}
