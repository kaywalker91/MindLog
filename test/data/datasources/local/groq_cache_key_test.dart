import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/data/datasources/local/groq_cache_key.dart';

void main() {
  group('GroqCacheKey', () {
    group('forText', () {
      test('동일한 입력은 동일한 키를 생성해야 한다', () {
        final a = GroqCacheKey.forText(
          content: '오늘은 좋은 하루였다.',
          character: AiCharacter.warmCounselor,
          userName: '서연',
        );
        final b = GroqCacheKey.forText(
          content: '오늘은 좋은 하루였다.',
          character: AiCharacter.warmCounselor,
          userName: '서연',
        );
        expect(a, equals(b));
      });

      test('content 차이는 다른 키를 만들어야 한다', () {
        final a = GroqCacheKey.forText(
          content: '오늘은 좋은 하루였다.',
          character: AiCharacter.warmCounselor,
        );
        final b = GroqCacheKey.forText(
          content: '오늘은 힘든 하루였다.',
          character: AiCharacter.warmCounselor,
        );
        expect(a, isNot(equals(b)));
      });

      test('character 차이는 다른 키를 만들어야 한다', () {
        final a = GroqCacheKey.forText(
          content: '같은 내용',
          character: AiCharacter.warmCounselor,
        );
        final b = GroqCacheKey.forText(
          content: '같은 내용',
          character: AiCharacter.cheerfulFriend,
        );
        expect(a, isNot(equals(b)));
      });

      test('userName이 다르면 다른 키를 만들어야 한다', () {
        final a = GroqCacheKey.forText(
          content: '같은 내용',
          character: AiCharacter.warmCounselor,
          userName: '서연',
        );
        final b = GroqCacheKey.forText(
          content: '같은 내용',
          character: AiCharacter.warmCounselor,
          userName: '민준',
        );
        expect(a, isNot(equals(b)));
      });

      test('content 정규화: 양끝 공백/연속 공백은 무시해야 한다', () {
        final raw = GroqCacheKey.forText(
          content: '오늘은 좋은 하루였다.',
          character: AiCharacter.warmCounselor,
        );
        final padded = GroqCacheKey.forText(
          content: '   오늘은    좋은   하루였다.   ',
          character: AiCharacter.warmCounselor,
        );
        expect(raw, equals(padded));
      });

      test('sha256 길이(64자 hex)를 가져야 한다', () {
        final key = GroqCacheKey.forText(
          content: '내용',
          character: AiCharacter.warmCounselor,
        );
        expect(key.length, 64);
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(key), isTrue);
      });
    });

    group('forVision', () {
      test('imageSignatures 순서는 결과 키에 영향이 없어야 한다', () {
        final a = GroqCacheKey.forVision(
          content: '내용',
          character: AiCharacter.warmCounselor,
          imageSignatures: ['hash_a', 'hash_b', 'hash_c'],
        );
        final b = GroqCacheKey.forVision(
          content: '내용',
          character: AiCharacter.warmCounselor,
          imageSignatures: ['hash_c', 'hash_a', 'hash_b'],
        );
        expect(a, equals(b));
      });

      test('imageSignatures가 다르면 다른 키를 만들어야 한다', () {
        final a = GroqCacheKey.forVision(
          content: '내용',
          character: AiCharacter.warmCounselor,
          imageSignatures: ['hash_1'],
        );
        final b = GroqCacheKey.forVision(
          content: '내용',
          character: AiCharacter.warmCounselor,
          imageSignatures: ['hash_2'],
        );
        expect(a, isNot(equals(b)));
      });

      test('forText 키와 forVision 키는 달라야 한다 (model 다름)', () {
        final text = GroqCacheKey.forText(
          content: '내용',
          character: AiCharacter.warmCounselor,
        );
        final vision = GroqCacheKey.forVision(
          content: '내용',
          character: AiCharacter.warmCounselor,
          imageSignatures: const [],
        );
        expect(text, isNot(equals(vision)));
      });
    });
  });
}
