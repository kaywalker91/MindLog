import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/constants/prompt_constants.dart';
import 'package:mindlog/core/utils/clock.dart';

/// 결정론적 Random (테스트용)
class FakeRandom implements Random {
  final List<double> _doubleSequence;
  final List<int> _intSequence;
  int _doubleIndex = 0;
  int _intIndex = 0;

  FakeRandom({
    List<double>? doubleSequence,
    List<int>? intSequence,
  })  : _doubleSequence = doubleSequence ?? [0.5],
        _intSequence = intSequence ?? [0];

  @override
  double nextDouble() {
    final value = _doubleSequence[_doubleIndex % _doubleSequence.length];
    _doubleIndex++;
    return value;
  }

  @override
  int nextInt(int max) {
    final value = _intSequence[_intIndex % _intSequence.length];
    _intIndex++;
    return value % max;
  }

  @override
  bool nextBool() => nextDouble() < 0.5;
}

void main() {
  setUp(() {
    PromptConstants.resetForTesting();
  });

  tearDown(() {
    PromptConstants.resetForTesting();
  });

  group('PromptConstants 시스템 프롬프트 캐싱', () {
    test('동일한 캐릭터에 대해 캐싱된 프롬프트를 반환해야 한다', () {
      final first = PromptConstants.systemInstructionFor(AiCharacter.warmCounselor);
      final second = PromptConstants.systemInstructionFor(AiCharacter.warmCounselor);

      expect(identical(first, second), isTrue);
    });

    test('다른 캐릭터에 대해 다른 프롬프트를 반환해야 한다', () {
      final warm = PromptConstants.systemInstructionFor(AiCharacter.warmCounselor);
      final realistic = PromptConstants.systemInstructionFor(AiCharacter.realisticCoach);
      final cheerful = PromptConstants.systemInstructionFor(AiCharacter.cheerfulFriend);

      expect(warm, isNot(equals(realistic)));
      expect(warm, isNot(equals(cheerful)));
      expect(realistic, isNot(equals(cheerful)));
    });

    test('캐시 초기화 후 새로운 프롬프트를 생성해야 한다', () {
      final before = PromptConstants.systemInstructionFor(AiCharacter.warmCounselor);
      PromptConstants.resetForTesting();
      final after = PromptConstants.systemInstructionFor(AiCharacter.warmCounselor);

      // 내용은 동일하지만 다른 인스턴스
      expect(before, equals(after));
      expect(identical(before, after), isFalse);
    });
  });

  group('PromptConstants 시간 주입', () {
    test('아침 시간대(5-10시)에 올바른 카테고리를 반환해야 한다', () {
      PromptConstants.setClock(FixedClock(DateTime(2024, 1, 1, 8, 0))); // 8시 = 아침

      final prompt = PromptConstants.createAnalysisPrompt(
        '테스트 일기 내용입니다.',
        character: AiCharacter.warmCounselor,
      );

      expect(prompt, contains('현재 시간대: 아침'));
    });

    test('점심 시간대(11-13시)에 올바른 카테고리를 반환해야 한다', () {
      PromptConstants.setClock(FixedClock(DateTime(2024, 1, 1, 12, 0))); // 12시 = 점심

      final prompt = PromptConstants.createAnalysisPrompt(
        '테스트 일기 내용입니다.',
        character: AiCharacter.warmCounselor,
      );

      expect(prompt, contains('현재 시간대: 점심'));
    });

    test('오후 시간대(14-17시)에 올바른 카테고리를 반환해야 한다', () {
      PromptConstants.setClock(FixedClock(DateTime(2024, 1, 1, 15, 0))); // 15시 = 오후

      final prompt = PromptConstants.createAnalysisPrompt(
        '테스트 일기 내용입니다.',
        character: AiCharacter.warmCounselor,
      );

      expect(prompt, contains('현재 시간대: 오후'));
    });

    test('저녁 시간대(18-21시)에 올바른 카테고리를 반환해야 한다', () {
      PromptConstants.setClock(FixedClock(DateTime(2024, 1, 1, 20, 0))); // 20시 = 저녁

      final prompt = PromptConstants.createAnalysisPrompt(
        '테스트 일기 내용입니다.',
        character: AiCharacter.warmCounselor,
      );

      expect(prompt, contains('현재 시간대: 저녁'));
    });

    test('밤 시간대(22-4시)에 올바른 카테고리를 반환해야 한다', () {
      PromptConstants.setClock(FixedClock(DateTime(2024, 1, 1, 23, 0))); // 23시 = 밤

      final prompt = PromptConstants.createAnalysisPrompt(
        '테스트 일기 내용입니다.',
        character: AiCharacter.warmCounselor,
      );

      expect(prompt, contains('현재 시간대: 밤'));
    });
  });

  group('PromptConstants Random 주입', () {
    test('FakeRandom으로 결정론적 카테고리 선택이 가능해야 한다', () {
      PromptConstants.setClock(FixedClock(DateTime(2024, 1, 1, 8, 0))); // 아침
      // 70% 미만이면 시간대 기반 카테고리 선택
      PromptConstants.setRandom(FakeRandom(doubleSequence: [0.5], intSequence: [0]));

      final prompt1 = PromptConstants.createAnalysisPrompt(
        '테스트 일기',
        character: AiCharacter.warmCounselor,
      );

      // 아침 시간대의 첫 번째 카테고리는 '마음챙김'
      expect(prompt1, contains("'마음챙김' 카테고리"));
    });

    test('70% 이상이면 전체 카테고리에서 선택해야 한다', () {
      PromptConstants.setClock(FixedClock(DateTime(2024, 1, 1, 8, 0)));
      // 70% 이상이면 전체 카테고리에서 랜덤 선택
      PromptConstants.setRandom(FakeRandom(doubleSequence: [0.8], intSequence: [1]));

      final prompt = PromptConstants.createAnalysisPrompt(
        '테스트 일기',
        character: AiCharacter.warmCounselor,
      );

      // 전체 카테고리의 두 번째는 '신체활동'
      expect(prompt, contains("'신체활동' 카테고리"));
    });
  });

  group('PromptConstants 유저 이름 개인화', () {
    test('유저 이름이 있으면 프롬프트에 포함되어야 한다', () {
      PromptConstants.setClock(FixedClock(DateTime(2024, 1, 1, 12, 0)));

      final prompt = PromptConstants.createAnalysisPrompt(
        '테스트 일기',
        character: AiCharacter.warmCounselor,
        userName: '홍길동',
      );

      expect(prompt, contains('홍길동'));
      expect(prompt, contains('[유저 이름]'));
    });

    test('유저 이름이 없으면 유저 이름 섹션이 없어야 한다', () {
      PromptConstants.setClock(FixedClock(DateTime(2024, 1, 1, 12, 0)));

      final prompt = PromptConstants.createAnalysisPrompt(
        '테스트 일기',
        character: AiCharacter.warmCounselor,
      );

      expect(prompt, isNot(contains('[유저 이름]')));
    });
  });
}
