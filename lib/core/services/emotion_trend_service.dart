import 'package:flutter/foundation.dart';

import '../../domain/entities/statistics.dart';

/// 감정 추이 트렌드 유형
enum EmotionTrend {
  /// 감정 점수 하락 추세
  declining,

  /// 하락 후 회복 추세
  recovering,

  /// 안정적인 높은 점수 유지
  steady,

  /// 일기 작성 공백 (3일 이상 미작성)
  gap,
}

/// 감정 추이 분석 결과
class EmotionTrendResult {
  const EmotionTrendResult({
    required this.trend,
    this.metadata = const {},
  });

  /// 감지된 트렌드 유형
  final EmotionTrend trend;

  /// 추가 메타데이터 (평균 점수, 기간 등)
  final Map<String, dynamic> metadata;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EmotionTrendResult) return false;
    if (other.trend != trend) return false;
    if (other.metadata.length != metadata.length) return false;
    for (final key in metadata.keys) {
      if (other.metadata[key] != metadata[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(trend, metadata.length);

  @override
  String toString() =>
      'EmotionTrendResult(trend: $trend, metadata: $metadata)';
}

/// 감정 추이 분석 서비스
///
/// [DailyEmotion] 데이터를 기반으로 감정 트렌드를 감지합니다.
/// 우선순위: gap > steady > recovering > declining
class EmotionTrendService {
  EmotionTrendService._();

  /// 테스트용 현재 시간 오버라이드
  @visibleForTesting
  static DateTime Function()? nowOverride;

  /// 테스트 상태 초기화
  @visibleForTesting
  static void resetForTesting() {
    nowOverride = null;
  }

  static DateTime _now() => nowOverride?.call() ?? DateTime.now();

  /// 감정 추이 분석
  ///
  /// [dailyEmotions]는 날짜 기준 정렬 (최신순 또는 오래된순 무관, 내부 정렬)
  ///
  /// 반환값:
  /// - 충분한 데이터가 없으면 null
  /// - 우선순위: gap > steady > recovering > declining
  static EmotionTrendResult? analyzeTrend(List<DailyEmotion> dailyEmotions) {
    if (dailyEmotions.isEmpty) return null;

    // 날짜 오름차순 정렬 (오래된 → 최신)
    final sorted = List<DailyEmotion>.from(dailyEmotions)
      ..sort((a, b) => a.date.compareTo(b.date));

    // 1. Gap 감지: 마지막 기록일로부터 3일 이상 공백
    final gapResult = _detectGap(sorted);
    if (gapResult != null) return gapResult;

    // 2. Steady 감지: 최근 7일 평균 >= 7.0 AND 최소 3개 엔트리
    final steadyResult = _detectSteady(sorted);
    if (steadyResult != null) return steadyResult;

    // 3. Recovering 감지: 2일 연속 상승 + 이전 하락
    final recoveringResult = _detectRecovering(sorted);
    if (recoveringResult != null) return recoveringResult;

    // 4. Declining 감지: 3일 연속 하락 OR 7일 평균 2점 이상 하락
    final decliningResult = _detectDeclining(sorted);
    if (decliningResult != null) return decliningResult;

    return null;
  }

  /// Gap 감지: 마지막 기록 날짜로부터 현재까지 3일 이상
  static EmotionTrendResult? _detectGap(List<DailyEmotion> sorted) {
    final now = _now();
    final lastEntry = sorted.last;
    final daysSinceLastEntry = now.difference(lastEntry.date).inDays;

    if (daysSinceLastEntry >= 3) {
      return EmotionTrendResult(
        trend: EmotionTrend.gap,
        metadata: {
          'daysSinceLastEntry': daysSinceLastEntry,
          'lastEntryDate': lastEntry.date.toIso8601String(),
        },
      );
    }
    return null;
  }

  /// Steady 감지: 최근 7일 평균 >= 7.0 AND 최소 3개 엔트리
  static EmotionTrendResult? _detectSteady(List<DailyEmotion> sorted) {
    final now = _now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final recentEntries = sorted
        .where((e) => !e.date.isBefore(sevenDaysAgo))
        .toList();

    if (recentEntries.length < 3) return null;

    final average = recentEntries.fold<double>(
          0,
          (sum, e) => sum + e.averageScore,
        ) /
        recentEntries.length;

    if (average >= 7.0) {
      return EmotionTrendResult(
        trend: EmotionTrend.steady,
        metadata: {
          'averageScore': average,
          'entryCount': recentEntries.length,
          'periodDays': 7,
        },
      );
    }
    return null;
  }

  /// Recovering 감지: 2일 연속 상승 + 이전 하락 (최소 3개 데이터)
  static EmotionTrendResult? _detectRecovering(List<DailyEmotion> sorted) {
    if (sorted.length < 3) return null;

    // 최신 3개 데이터 포인트로 판별
    final recent = sorted.sublist(sorted.length - 3);

    // 처음 → 중간 하락, 중간 → 마지막 상승, 두번째 → 세번째 상승
    final previousDecline = recent[0].averageScore > recent[1].averageScore;
    final firstRise = recent[1].averageScore < recent[2].averageScore;

    // 추가: 2일 연속 상승 확인 (마지막 2개가 이전보다 높아야 함)
    if (sorted.length >= 4) {
      final lastFour = sorted.sublist(sorted.length - 4);
      final decline = lastFour[0].averageScore > lastFour[1].averageScore;
      final rise1 = lastFour[1].averageScore < lastFour[2].averageScore;
      final rise2 = lastFour[2].averageScore < lastFour[3].averageScore;

      if (decline && rise1 && rise2) {
        return EmotionTrendResult(
          trend: EmotionTrend.recovering,
          metadata: {
            'lowestScore': lastFour[1].averageScore,
            'currentScore': lastFour[3].averageScore,
            'consecutiveRisingDays': 2,
          },
        );
      }
    }

    // 3개만 있을 때: 하락 + 상승
    if (previousDecline && firstRise) {
      return EmotionTrendResult(
        trend: EmotionTrend.recovering,
        metadata: {
          'lowestScore': recent[1].averageScore,
          'currentScore': recent[2].averageScore,
          'consecutiveRisingDays': 1,
        },
      );
    }

    return null;
  }

  /// Declining 감지: 3일 연속 하락 OR 7일 평균 2점 이상 하락
  static EmotionTrendResult? _detectDeclining(List<DailyEmotion> sorted) {
    // 조건 1: 3일 연속 하락
    if (sorted.length >= 3) {
      final lastThree = sorted.sublist(sorted.length - 3);
      final consecutiveDecline =
          lastThree[0].averageScore > lastThree[1].averageScore &&
              lastThree[1].averageScore > lastThree[2].averageScore;

      if (consecutiveDecline) {
        return EmotionTrendResult(
          trend: EmotionTrend.declining,
          metadata: {
            'type': 'consecutiveDecline',
            'startScore': lastThree[0].averageScore,
            'currentScore': lastThree[2].averageScore,
            'consecutiveDecliningDays': 3,
          },
        );
      }
    }

    // 조건 2: 최근 7일 평균 vs 이전 7일 평균 비교 (2점 이상 하락)
    if (sorted.length >= 7) {
      final now = _now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final fourteenDaysAgo = now.subtract(const Duration(days: 14));

      final recentWeek = sorted
          .where((e) => !e.date.isBefore(sevenDaysAgo))
          .toList();
      final previousWeek = sorted
          .where(
            (e) => !e.date.isBefore(fourteenDaysAgo) &&
                e.date.isBefore(sevenDaysAgo),
          )
          .toList();

      if (recentWeek.isNotEmpty && previousWeek.isNotEmpty) {
        final recentAvg = recentWeek.fold<double>(
              0,
              (sum, e) => sum + e.averageScore,
            ) /
            recentWeek.length;
        final previousAvg = previousWeek.fold<double>(
              0,
              (sum, e) => sum + e.averageScore,
            ) /
            previousWeek.length;

        if (previousAvg - recentAvg >= 2.0) {
          return EmotionTrendResult(
            trend: EmotionTrend.declining,
            metadata: {
              'type': 'averageDrop',
              'recentAverage': recentAvg,
              'previousAverage': previousAvg,
              'dropAmount': previousAvg - recentAvg,
            },
          );
        }
      }
    }

    return null;
  }
}
