import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/usecases/get_onboarding_completed_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  late GetOnboardingCompletedUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = GetOnboardingCompletedUseCase(mockRepository);
  });

  group('GetOnboardingCompletedUseCase', () {
    test('온보딩 미완료 시 false를 반환해야 한다', () async {
      // Arrange
      when(
        () => mockRepository.isOnboardingCompleted(),
      ).thenAnswer((_) async => false);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, false);
      verify(() => mockRepository.isOnboardingCompleted()).called(1);
    });

    test('온보딩 완료 시 true를 반환해야 한다', () async {
      // Arrange
      when(
        () => mockRepository.isOnboardingCompleted(),
      ).thenAnswer((_) async => true);

      // Act
      final result = await useCase.execute();

      // Assert
      expect(result, true);
    });
  });
}
