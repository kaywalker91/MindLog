import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
import 'package:mindlog/domain/usecases/self_encouragement/add_self_encouragement_message_usecase.dart';

import '../../../helpers/mock_fallbacks.dart';
import '../../../mocks/mock_repositories.dart';

void main() {
  late AddSelfEncouragementMessageUseCase useCase;
  late MockSettingsRepositoryWithMessages mockRepository;

  setUpAll(() {
    registerMockFallbackValues();
  });

  SelfEncouragementMessage createMessage({
    String content = '테스트 메시지',
    int displayOrder = 0,
  }) {
    return SelfEncouragementMessage(
      id: 'test-id',
      content: content,
      createdAt: DateTime.now(),
      displayOrder: displayOrder,
    );
  }

  setUp(() {
    mockRepository = MockSettingsRepositoryWithMessages();
    useCase = AddSelfEncouragementMessageUseCase(mockRepository);

    when(
      () => mockRepository.getSelfEncouragementMessages(),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.addSelfEncouragementMessage(any()),
    ).thenAnswer((_) async {});
  });

  group('AddSelfEncouragementMessageUseCase', () {
    test('should add message when valid', () async {
      // Arrange
      final message = createMessage();
      when(
        () => mockRepository.getSelfEncouragementMessages(),
      ).thenAnswer((_) async => []);

      // Act
      await useCase.execute(message);

      // Assert
      final captured = verify(
        () => mockRepository.addSelfEncouragementMessage(captureAny()),
      ).captured;
      expect(captured.length, 1);
      expect(captured.first, message);
    });

    test('should throw ValidationFailure when content is empty', () async {
      // Arrange
      final message = createMessage(content: '');

      // Act & Assert
      expect(() => useCase.execute(message), throwsA(isA<ValidationFailure>()));
      verifyNever(
        () => mockRepository.addSelfEncouragementMessage(any()),
      );
    });

    test(
      'should throw ValidationFailure when content is whitespace only',
      () async {
        // Arrange
        final message = createMessage(content: '   ');

        // Act & Assert
        expect(
          () => useCase.execute(message),
          throwsA(isA<ValidationFailure>()),
        );
      },
    );

    test(
      'should throw ValidationFailure when content exceeds max length',
      () async {
        // Arrange
        final longContent = 'a' * 101; // max is 100
        final message = createMessage(content: longContent);

        // Act & Assert
        expect(
          () => useCase.execute(message),
          throwsA(isA<ValidationFailure>()),
        );
      },
    );

    test(
      'should throw ValidationFailure when max message count reached',
      () async {
        // Arrange
        when(
          () => mockRepository.getSelfEncouragementMessages(),
        ).thenAnswer(
          (_) async => List.generate(
            SelfEncouragementMessage.maxMessageCount, // 10
            (i) => createMessage(displayOrder: i),
          ),
        );

        final newMessage = createMessage();

        // Act & Assert
        expect(
          () => useCase.execute(newMessage),
          throwsA(isA<ValidationFailure>()),
        );
        verifyNever(
          () => mockRepository.addSelfEncouragementMessage(any()),
        );
      },
    );

    test('should allow adding when under max count', () async {
      // Arrange
      when(
        () => mockRepository.getSelfEncouragementMessages(),
      ).thenAnswer(
        (_) async => List.generate(
          SelfEncouragementMessage.maxMessageCount - 1, // 9
          (i) => createMessage(displayOrder: i),
        ),
      );

      final newMessage = createMessage();

      // Act
      await useCase.execute(newMessage);

      // Assert
      verify(
        () => mockRepository.addSelfEncouragementMessage(any()),
      ).called(1);
    });
  });
}
