import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/usecases/get_selected_ai_character_usecase.dart';
import 'package:mindlog/domain/usecases/set_selected_ai_character_usecase.dart';
import 'package:mindlog/presentation/providers/ai_character_controller.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';

import '../../mocks/mock_repositories.dart';

/// Mock GetSelectedAiCharacterUseCase
class MockGetSelectedAiCharacterUseCase implements GetSelectedAiCharacterUseCase {
  AiCharacter mockCharacter = AiCharacter.warmCounselor;
  bool shouldThrow = false;
  Failure? failureToThrow;

  void reset() {
    mockCharacter = AiCharacter.warmCounselor;
    shouldThrow = false;
    failureToThrow = null;
  }

  @override
  Future<AiCharacter> execute() async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '캐릭터 조회 실패');
    }
    return mockCharacter;
  }
}

/// Mock SetSelectedAiCharacterUseCase
class MockSetSelectedAiCharacterUseCase implements SetSelectedAiCharacterUseCase {
  bool shouldThrow = false;
  Failure? failureToThrow;
  final List<AiCharacter> savedCharacters = [];

  void reset() {
    shouldThrow = false;
    failureToThrow = null;
    savedCharacters.clear();
  }

  @override
  Future<void> execute(AiCharacter character) async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '캐릭터 저장 실패');
    }
    savedCharacters.add(character);
  }
}

void main() {
  late ProviderContainer container;
  late MockGetSelectedAiCharacterUseCase mockGetUseCase;
  late MockSetSelectedAiCharacterUseCase mockSetUseCase;

  setUp(() {
    mockGetUseCase = MockGetSelectedAiCharacterUseCase();
    mockSetUseCase = MockSetSelectedAiCharacterUseCase();

    container = ProviderContainer(
      overrides: [
        getSelectedAiCharacterUseCaseProvider.overrideWithValue(mockGetUseCase),
        setSelectedAiCharacterUseCaseProvider.overrideWithValue(mockSetUseCase),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() {
    mockGetUseCase.reset();
    mockSetUseCase.reset();
  });

  group('AiCharacterController', () {
    group('build', () {
      test('초기 로드 시 UseCase에서 캐릭터를 조회해야 한다', () async {
        // Arrange
        mockGetUseCase.mockCharacter = AiCharacter.realisticCoach;

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
        mockGetUseCase.shouldThrow = true;
        mockGetUseCase.failureToThrow = const Failure.cache(message: '조회 실패');

        // Act
        await container.read(aiCharacterProvider.future).catchError((_) => AiCharacter.warmCounselor);

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
        expect(mockSetUseCase.savedCharacters, contains(AiCharacter.cheerfulFriend));
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
        expect(container.read(aiCharacterProvider).value, AiCharacter.warmCounselor);

        // realisticCoach
        await notifier.setCharacter(AiCharacter.realisticCoach);
        expect(container.read(aiCharacterProvider).value, AiCharacter.realisticCoach);

        // cheerfulFriend
        await notifier.setCharacter(AiCharacter.cheerfulFriend);
        expect(container.read(aiCharacterProvider).value, AiCharacter.cheerfulFriend);
      });

      test('UseCase 에러 시 예외를 전파해야 한다', () async {
        // Arrange
        await container.read(aiCharacterProvider.future);
        final notifier = container.read(aiCharacterProvider.notifier);
        mockSetUseCase.shouldThrow = true;
        mockSetUseCase.failureToThrow = const Failure.cache(message: '저장 실패');

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
        expect(mockSetUseCase.savedCharacters.length, 3);
        expect(container.read(aiCharacterProvider).value, AiCharacter.cheerfulFriend);
      });
    });
  });
}
