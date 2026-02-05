import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';

void main() {
  group('SelfEncouragementMessage', () {
    test('should create message with all required fields', () {
      final now = DateTime.now();
      final message = SelfEncouragementMessage(
        id: 'test-id',
        content: '오늘도 힘내자!',
        createdAt: now,
        displayOrder: 0,
      );

      expect(message.id, 'test-id');
      expect(message.content, '오늘도 힘내자!');
      expect(message.createdAt, now);
      expect(message.displayOrder, 0);
    });

    test('should support copyWith', () {
      final original = SelfEncouragementMessage(
        id: 'test-id',
        content: '원본 메시지',
        createdAt: DateTime(2024, 1, 1),
        displayOrder: 0,
      );

      final copied = original.copyWith(content: '수정된 메시지');

      expect(copied.id, original.id);
      expect(copied.content, '수정된 메시지');
      expect(copied.createdAt, original.createdAt);
      expect(copied.displayOrder, original.displayOrder);
    });

    test('should serialize to JSON and back', () {
      final original = SelfEncouragementMessage(
        id: 'test-id',
        content: '테스트 메시지',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        displayOrder: 2,
      );

      final json = original.toJson();
      final restored = SelfEncouragementMessage.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.content, original.content);
      expect(restored.createdAt, original.createdAt);
      expect(restored.displayOrder, original.displayOrder);
    });

    test('should have correct max content length constant', () {
      expect(SelfEncouragementMessage.maxContentLength, 100);
    });

    test('should have correct max message count constant', () {
      expect(SelfEncouragementMessage.maxMessageCount, 10);
    });

    test('should implement equality correctly', () {
      final now = DateTime(2024, 1, 1);
      final message1 = SelfEncouragementMessage(
        id: 'id-1',
        content: '메시지',
        createdAt: now,
        displayOrder: 0,
      );
      final message2 = SelfEncouragementMessage(
        id: 'id-1',
        content: '메시지',
        createdAt: now,
        displayOrder: 0,
      );
      final message3 = SelfEncouragementMessage(
        id: 'id-2',
        content: '메시지',
        createdAt: now,
        displayOrder: 0,
      );

      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });
  });

  group('MessageRotationMode', () {
    test('should have random and sequential modes', () {
      expect(MessageRotationMode.values.length, 2);
      expect(MessageRotationMode.random, isNotNull);
      expect(MessageRotationMode.sequential, isNotNull);
    });
  });
}
