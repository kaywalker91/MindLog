import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
import 'package:mindlog/domain/usecases/self_encouragement/get_next_self_encouragement_message_usecase.dart';

import '../../../mocks/mock_repositories.dart';

class MockRandom implements Random {
  int nextValue = 0;

  @override
  int nextInt(int max) => nextValue % max;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.5;
}

void main() {
  late GetNextSelfEncouragementMessageUseCase useCase;
  late MockSettingsRepositoryWithMessages mockRepository;
  late MockRandom mockRandom;

  setUp(() {
    mockRepository = MockSettingsRepositoryWithMessages();
    mockRandom = MockRandom();
    useCase = GetNextSelfEncouragementMessageUseCase(
      mockRepository,
      mockRandom,
    );
  });

  List<SelfEncouragementMessage> createMessages(int count) {
    return List.generate(
      count,
      (i) => SelfEncouragementMessage(
        id: 'id-$i',
        content: '메시지 $i',
        createdAt: DateTime.now(),
        displayOrder: i,
      ),
    );
  }

  group('GetNextSelfEncouragementMessageUseCase', () {
    test('should return null when no messages exist', () async {
      // Arrange
      mockRepository.messages = [];
      final settings = NotificationSettings.defaults();

      // Act
      final result = await useCase.execute(settings);

      // Assert
      expect(result, isNull);
    });

    group('random mode', () {
      test('should return message at random index', () async {
        // Arrange
        final messages = createMessages(5);
        mockRepository.messages = messages;
        mockRandom.nextValue = 2;
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.random,
        );

        // Act
        final result = await useCase.execute(settings);

        // Assert
        expect(result, equals(messages[2]));
      });
    });

    group('sequential mode', () {
      test('should return message at next index', () async {
        // Arrange
        final messages = createMessages(5);
        mockRepository.messages = messages;
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.sequential,
          lastDisplayedIndex: 1, // next should be 2
        );

        // Act
        final result = await useCase.execute(settings);

        // Assert
        expect(result, equals(messages[2]));
      });

      test('should wrap around when reaching end', () async {
        // Arrange
        final messages = createMessages(3);
        mockRepository.messages = messages;
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.sequential,
          lastDisplayedIndex: 2, // next should be 0 (wrap)
        );

        // Act
        final result = await useCase.execute(settings);

        // Assert
        expect(result, equals(messages[0]));
      });
    });

    test('getNextIndex should calculate correct next index', () {
      expect(useCase.getNextIndex(0, 5), 1);
      expect(useCase.getNextIndex(4, 5), 0); // wrap
      expect(useCase.getNextIndex(2, 3), 0); // wrap
      expect(useCase.getNextIndex(0, 0), 0); // empty list
    });
  });
}
