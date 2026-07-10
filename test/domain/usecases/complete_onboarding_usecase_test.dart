import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/usecases/complete_onboarding_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  late CompleteOnboardingUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = CompleteOnboardingUseCase(mockRepository);
  });

  group('CompleteOnboardingUseCase', () {
    test('Repository의 setOnboardingCompleted를 호출해야 한다', () async {
      // Arrange
      when(
        () => mockRepository.setOnboardingCompleted(),
      ).thenAnswer((_) async {});

      // Act
      await useCase.execute();

      // Assert
      verify(() => mockRepository.setOnboardingCompleted()).called(1);
    });
  });
}
