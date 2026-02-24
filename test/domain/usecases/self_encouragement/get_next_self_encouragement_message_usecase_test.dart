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

  SelfEncouragementMessage createMessageWithScore(
    String id,
    double score,
    int order,
  ) {
    return SelfEncouragementMessage(
      id: id,
      content: '메시지 $id',
      createdAt: DateTime.now(),
      displayOrder: order,
      writtenEmotionScore: score,
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

    group('emotionAware mode', () {
      test('currentEmotionScore 없으면 랜덤 폴백', () async {
        // Arrange
        final messages = createMessages(3);
        mockRepository.messages = messages;
        mockRandom.nextValue = 1;
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.emotionAware,
        );

        // Act
        final result = await useCase.execute(settings);

        // Assert - no score → random fallback → index 1
        expect(result, equals(messages[1]));
      });

      test('low 점수(≤3)이면 low 메시지만 선택', () async {
        // Arrange
        final lowMsg = createMessageWithScore('low', 2.0, 0);
        final medMsg = createMessageWithScore('med', 5.0, 1);
        final highMsg = createMessageWithScore('high', 8.0, 2);
        mockRepository.messages = [lowMsg, medMsg, highMsg];
        mockRandom.nextValue = 0;
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.emotionAware,
        );

        // Act
        final result = await useCase.execute(
          settings,
          currentEmotionScore: 2.5,
        );

        // Assert - filtered to [lowMsg], random index 0
        expect(result, equals(lowMsg));
      });

      test('medium 점수(4-6)이면 medium 메시지만 선택', () async {
        // Arrange
        final lowMsg = createMessageWithScore('low', 2.0, 0);
        final medMsg1 = createMessageWithScore('med1', 4.0, 1);
        final medMsg2 = createMessageWithScore('med2', 6.0, 2);
        final highMsg = createMessageWithScore('high', 8.0, 3);
        mockRepository.messages = [lowMsg, medMsg1, medMsg2, highMsg];
        mockRandom.nextValue = 1;
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.emotionAware,
        );

        // Act
        final result = await useCase.execute(
          settings,
          currentEmotionScore: 5.0,
        );

        // Assert - filtered to [medMsg1, medMsg2], random index 1 → medMsg2
        expect(result, equals(medMsg2));
      });

      test('high 점수(>6)이면 high 메시지만 선택', () async {
        // Arrange
        final lowMsg = createMessageWithScore('low', 2.0, 0);
        final highMsg = createMessageWithScore('high', 8.0, 1);
        mockRepository.messages = [lowMsg, highMsg];
        mockRandom.nextValue = 0;
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.emotionAware,
        );

        // Act
        final result = await useCase.execute(
          settings,
          currentEmotionScore: 7.5,
        );

        // Assert - filtered to [highMsg], random index 0
        expect(result, equals(highMsg));
      });

      test('매칭 메시지 없으면 전체 폴백', () async {
        // Arrange - all messages have low scores, but current is high
        final msg1 = createMessageWithScore('m1', 2.0, 0);
        final msg2 = createMessageWithScore('m2', 3.0, 1);
        mockRepository.messages = [msg1, msg2];
        mockRandom.nextValue = 1;
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.emotionAware,
        );

        // Act
        final result = await useCase.execute(
          settings,
          currentEmotionScore: 9.0, // high, no matches
        );

        // Assert - fallback to all messages, random index 1
        expect(result, equals(msg2));
      });

      test('writtenEmotionScore 없는 메시지는 필터에서 제외', () async {
        // Arrange
        final noScore = SelfEncouragementMessage(
          id: 'no',
          content: '점수 없음',
          createdAt: DateTime.now(),
          displayOrder: 0,
        );
        final lowMsg = createMessageWithScore('low', 2.0, 1);
        mockRepository.messages = [noScore, lowMsg];
        mockRandom.nextValue = 0;
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.emotionAware,
        );

        // Act
        final result = await useCase.execute(
          settings,
          currentEmotionScore: 1.0,
        );

        // Assert - filtered to [lowMsg] only (noScore excluded)
        expect(result, equals(lowMsg));
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
