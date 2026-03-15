import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/presentation/providers/ai_character_controller.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_fallbacks.dart';
import '../../mocks/mock_usecases.dart';

void main() {
  late ProviderContainer container;
  late MockGetSelectedAiCharacterUseCase mockGetUseCase;
  late MockSetSelectedAiCharacterUseCase mockSetUseCase;

  setUpAll(() {
    registerMockFallbackValues();
  });

  setUp(() {
    mockGetUseCase = MockGetSelectedAiCharacterUseCase();
    mockSetUseCase = MockSetSelectedAiCharacterUseCase();

    when(
      () => mockGetUseCase.execute(),
    ).thenAnswer((_) async => AiCharacter.warmCounselor);
    when(
      () => mockSetUseCase.execute(any()),
    ).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        getSelectedAiCharacterUseCaseProvider.overrideWithValue(mockGetUseCase),
        setSelectedAiCharacterUseCaseProvider.overrideWithValue(mockSetUseCase),
      ],
    );
    addTearDown(container.dispose);
  });

  group('AiCharacterController', () {
    group('build', () {
      test('초기 로드 시 UseCase에서 캐릭터를 조회해야 한다', () async {
        // Arrange
        when(
          () => mockGetUseCase.execute(),
        ).thenAnswer((_) async => AiCharacter.realisticCoach);

        // Act
        final character = await container.read(aiCharacterProvider.future);

        // Assert
        expect(character, AiCharacter.realisticCoach);
      });

      test('warmCounselor가 기본값으로 조회되어야 한다', () async {
        // Act
        final character = await container.read(aiCharacterProvider.future);

        // Assert
        expect(character, AiCharacter.warmCounselor);
      });

      test('UseCase 에러 시 AsyncError 상태여야 한다', () async {
        // Arrange
        when(
          () => mockGetUseCase.execute(),
        ).thenThrow(const Failure.cache(message: '조회 실패'));

        // Act
        await container
            .read(aiCharacterProvider.future)
            .catchError((_) => AiCharacter.warmCounselor);

        // Assert
        final state = container.read(aiCharacterProvider);
        expect(state, isA<AsyncError<AiCharacter>>());
      });
    });

    group('setCharacter', () {
      test('캐릭터 설정 시 UseCase를 호출해야 한다', () async {
        // Arrange
        await container.read(aiCharacterProvider.future);
        final notifier = container.read(aiCharacterProvider.notifier);

        // Act
        await notifier.setCharacter(AiCharacter.cheerfulFriend);

        // Assert
        verify(
          () => mockSetUseCase.execute(AiCharacter.cheerfulFriend),
        ).called(1);
      });

      test('설정 후 상태가 업데이트되어야 한다', () async {
        // Arrange
        await container.read(aiCharacterProvider.future);
        final notifier = container.read(aiCharacterProvider.notifier);

        // Act
        await notifier.setCharacter(AiCharacter.realisticCoach);

        // Assert
        final state = container.read(aiCharacterProvider);
        expect(state.value, AiCharacter.realisticCoach);
      });

      test('모든 캐릭터 타입을 설정할 수 있어야 한다', () async {
        // Arrange
        await container.read(aiCharacterProvider.future);
        final notifier = container.read(aiCharacterProvider.notifier);

        // Act & Assert - warmCounselor
        await notifier.setCharacter(AiCharacter.warmCounselor);
        expect(
          container.read(aiCharacterProvider).value,
          AiCharacter.warmCounselor,
        );

        // realisticCoach
        await notifier.setCharacter(AiCharacter.realisticCoach);
        expect(
          container.read(aiCharacterProvider).value,
          AiCharacter.realisticCoach,
        );

        // cheerfulFriend
        await notifier.setCharacter(AiCharacter.cheerfulFriend);
        expect(
          container.read(aiCharacterProvider).value,
          AiCharacter.cheerfulFriend,
        );
      });

      test('UseCase 에러 시 예외를 전파해야 한다', () async {
        // Arrange
        await container.read(aiCharacterProvider.future);
        final notifier = container.read(aiCharacterProvider.notifier);
        when(
          () => mockSetUseCase.execute(any()),
        ).thenThrow(const Failure.cache(message: '저장 실패'));

        // Act & Assert
        await expectLater(
          notifier.setCharacter(AiCharacter.cheerfulFriend),
          throwsA(isA<CacheFailure>()),
        );
      });

      test('연속 설정 변경이 올바르게 동작해야 한다', () async {
        // Arrange
        await container.read(aiCharacterProvider.future);
        final notifier = container.read(aiCharacterProvider.notifier);

        // Act
        await notifier.setCharacter(AiCharacter.warmCounselor);
        await notifier.setCharacter(AiCharacter.realisticCoach);
        await notifier.setCharacter(AiCharacter.cheerfulFriend);

        // Assert
        verify(() => mockSetUseCase.execute(any())).called(3);
        expect(
          container.read(aiCharacterProvider).value,
          AiCharacter.cheerfulFriend,
        );
      });
    });
  });
}
