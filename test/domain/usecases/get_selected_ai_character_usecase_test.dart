import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/usecases/get_selected_ai_character_usecase.dart';

import '../../helpers/mock_fallbacks.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  late GetSelectedAiCharacterUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerMockFallbackValues();
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = GetSelectedAiCharacterUseCase(mockRepository);
  });

  group('GetSelectedAiCharacterUseCase', () {
    group('execute', () {
      test('Repository에서 선택된 AI 캐릭터를 반환해야 한다', () async {
        // Arrange
        when(
          () => mockRepository.getSelectedAiCharacter(),
        ).thenAnswer((_) async => AiCharacter.warmCounselor);

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result, AiCharacter.warmCounselor);
      });

      test('다른 캐릭터가 설정되어 있으면 해당 캐릭터를 반환해야 한다', () async {
        // Arrange
        when(
          () => mockRepository.getSelectedAiCharacter(),
        ).thenAnswer((_) async => AiCharacter.realisticCoach);

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result, AiCharacter.realisticCoach);
      });

      test('cheerfulFriend 캐릭터도 올바르게 반환해야 한다', () async {
        // Arrange
        when(
          () => mockRepository.getSelectedAiCharacter(),
        ).thenAnswer((_) async => AiCharacter.cheerfulFriend);

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result, AiCharacter.cheerfulFriend);
      });

      test('Repository 에러 시 예외를 전파해야 한다', () async {
        // Arrange
        when(
          () => mockRepository.getSelectedAiCharacter(),
        ).thenAnswer((_) async => throw const Failure.cache(message: '캐릭터 조회 실패'));

        // Act & Assert
        await expectLater(useCase.execute(), throwsA(isA<CacheFailure>()));
      });
    });
  });
}
