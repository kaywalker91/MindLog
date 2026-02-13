import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
import 'package:mindlog/domain/usecases/self_encouragement/add_self_encouragement_message_usecase.dart';

import '../../../mocks/mock_repositories.dart';

void main() {
  late AddSelfEncouragementMessageUseCase useCase;
  late MockSettingsRepositoryWithMessages mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepositoryWithMessages();
    useCase = AddSelfEncouragementMessageUseCase(mockRepository);
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

  group('AddSelfEncouragementMessageUseCase', () {
    test('should add message when valid', () async {
      // Arrange
      final message = createMessage();
      mockRepository.messages = [];

      // Act
      await useCase.execute(message);

      // Assert
      expect(mockRepository.addedMessages.length, 1);
      expect(mockRepository.addedMessages.first, message);
    });

    test('should throw ValidationFailure when content is empty', () async {
      // Arrange
      final message = createMessage(content: '');

      // Act & Assert
      expect(() => useCase.execute(message), throwsA(isA<ValidationFailure>()));
      expect(mockRepository.addedMessages, isEmpty);
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
        mockRepository.messages = List.generate(
          SelfEncouragementMessage.maxMessageCount, // 10
          (i) => createMessage(displayOrder: i),
        );

        final newMessage = createMessage();

        // Act & Assert
        expect(
          () => useCase.execute(newMessage),
          throwsA(isA<ValidationFailure>()),
        );
        expect(mockRepository.addedMessages, isEmpty);
      },
    );

    test('should allow adding when under max count', () async {
      // Arrange
      mockRepository.messages = List.generate(
        SelfEncouragementMessage.maxMessageCount - 1, // 9
        (i) => createMessage(displayOrder: i),
      );

      final newMessage = createMessage();

      // Act
      await useCase.execute(newMessage);

      // Assert
      expect(mockRepository.addedMessages.length, 1);
    });
  });
}
