import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';

void main() {
  group('AiCharacter', () {
    test('모든 캐릭터는 displayName을 가진다', () {
      for (final character in AiCharacter.values) {
        expect(character.displayName, isNotEmpty);
      }
    });

    test('모든 캐릭터는 description을 가진다', () {
      for (final character in AiCharacter.values) {
        expect(character.description, isNotEmpty);
      }
    });

    test('모든 캐릭터는 id를 가진다', () {
      for (final character in AiCharacter.values) {
        expect(character.id, isNotEmpty);
      }
    });

    test('모든 캐릭터는 imagePath를 가진다', () {
      for (final character in AiCharacter.values) {
        expect(character.imagePath, isNotEmpty);
        expect(character.imagePath, contains('assets/'));
      }
    });

    test('warmCounselor는 따뜻한 상담사이다', () {
      expect(AiCharacter.warmCounselor.displayName, contains('온이'));
    });

    test('realisticCoach는 현실적 코치이다', () {
      expect(AiCharacter.realisticCoach.displayName, contains('콕이'));
    });

    test('cheerfulFriend는 유쾌한 친구이다', () {
      expect(AiCharacter.cheerfulFriend.displayName, contains('웃음이'));
    });

    test('AiCharacter.values는 3개의 캐릭터를 가진다', () {
      expect(AiCharacter.values.length, 3);
    });
  });
}
