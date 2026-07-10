import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/cheerme/cheer_me_weight.dart';

void main() {
  group('CheerMeWeight.forMessage', () {
    test('writtenEmotionScore null이면 기본 가중치 1이어야 한다', () {
      expect(
        CheerMeWeight.forMessage(
          writtenEmotionScore: null,
          recentEmotionScore: 5,
        ),
        CheerMeWeight.weightDefault,
      );
    });

    test('거리 ≤ 1.0이면 가중치 3이어야 한다', () {
      expect(
        CheerMeWeight.forMessage(
          writtenEmotionScore: 5.0,
          recentEmotionScore: 5.0,
        ),
        CheerMeWeight.weightClose,
      );
      expect(
        CheerMeWeight.forMessage(
          writtenEmotionScore: 5.0,
          recentEmotionScore: 4.0,
        ),
        CheerMeWeight.weightClose,
      );
    });

    test('거리 ≤ 3.0이면 가중치 2이어야 한다', () {
      expect(
        CheerMeWeight.forMessage(
          writtenEmotionScore: 5.0,
          recentEmotionScore: 3.0,
        ),
        CheerMeWeight.weightNear,
      );
      expect(
        CheerMeWeight.forMessage(
          writtenEmotionScore: 5.0,
          recentEmotionScore: 2.0,
        ),
        CheerMeWeight.weightNear,
      );
    });

    test('거리 > 3.0이면 가중치 1이어야 한다', () {
      expect(
        CheerMeWeight.forMessage(
          writtenEmotionScore: 1.0,
          recentEmotionScore: 5.0,
        ),
        CheerMeWeight.weightDefault,
      );
    });
  });

  group('CheerMeWeight.indexFromWeightedPick', () {
    test('legacy Random 루프와 동일한 버킷을 선택해야 한다', () {
      const weights = [3, 2, 1];
      // pick 0..2 → index 0, 3..4 → index 1, 5 → index 2
      for (var pick = 0; pick < 3; pick++) {
        expect(CheerMeWeight.indexFromWeightedPick(weights, pick), 0);
      }
      for (var pick = 3; pick < 5; pick++) {
        expect(CheerMeWeight.indexFromWeightedPick(weights, pick), 1);
      }
      expect(CheerMeWeight.indexFromWeightedPick(weights, 5), 2);
    });

    test('범위 초과 pick은 마지막 인덱스로 폴백해야 한다', () {
      expect(CheerMeWeight.indexFromWeightedPick([1, 1], 99), 1);
    });
  });

  group('CheerMeWeight.forMessages', () {
    test('메시지 점수 리스트에 대해 가중치 배열을 생성해야 한다', () {
      final weights = CheerMeWeight.forMessages(
        writtenEmotionScores: [5.0, null, 1.0],
        recentEmotionScore: 5.0,
      );
      expect(weights, [3, 1, 1]);
      expect(CheerMeWeight.total(weights), 5);
    });
  });
}
