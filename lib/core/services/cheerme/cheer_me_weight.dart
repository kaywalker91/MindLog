/// Pure emotion-distance → weight helpers for Cheer Me selection.
///
/// Shared by deterministic (seeded) and legacy (Random) selectors.
/// Thresholds are contract: do not change without migration.
/// - distance ≤ 1.0 → weight 3
/// - distance ≤ 3.0 → weight 2
/// - else → weight 1
/// - missing [writtenEmotionScore] → weight 1
class CheerMeWeight {
  CheerMeWeight._();

  static const double closeDistance = 1.0;
  static const double nearDistance = 3.0;
  static const int weightClose = 3;
  static const int weightNear = 2;
  static const int weightDefault = 1;

  /// Single-message weight against [recentEmotionScore].
  static int forMessage({
    required double? writtenEmotionScore,
    required double recentEmotionScore,
  }) {
    if (writtenEmotionScore == null) {
      return weightDefault;
    }
    final distance = (writtenEmotionScore - recentEmotionScore).abs();
    if (distance <= closeDistance) {
      return weightClose;
    }
    if (distance <= nearDistance) {
      return weightNear;
    }
    return weightDefault;
  }

  /// Weights aligned with [writtenEmotionScores] order.
  static List<int> forMessages({
    required List<double?> writtenEmotionScores,
    required double recentEmotionScore,
  }) {
    return [
      for (final score in writtenEmotionScores)
        forMessage(
          writtenEmotionScore: score,
          recentEmotionScore: recentEmotionScore,
        ),
    ];
  }

  /// Map a pick in `[0, totalWeight)` to a message index.
  ///
  /// Equivalent to both historical loops (deterministic `if pick < w` and
  /// legacy `pick -= w; if pick < 0`).
  static int indexFromWeightedPick(List<int> weights, int pick) {
    if (weights.isEmpty) {
      throw ArgumentError.value(weights, 'weights', 'must not be empty');
    }
    var remaining = pick;
    for (var i = 0; i < weights.length; i++) {
      if (remaining < weights[i]) {
        return i;
      }
      remaining -= weights[i];
    }
    return weights.length - 1;
  }

  static int total(List<int> weights) =>
      weights.fold(0, (sum, value) => sum + value);
}
