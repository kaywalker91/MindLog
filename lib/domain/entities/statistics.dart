import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistics.freezed.dart';

/// 일별 감정 데이터 (라인 차트용)
@freezed
class DailyEmotion with _$DailyEmotion {
  const factory DailyEmotion({
    /// 날짜
    required DateTime date,

    /// 해당 날짜의 평균 감정 점수 (1-10)
    required double averageScore,

    /// 해당 날짜의 일기 수
    required int diaryCount,
  }) = _DailyEmotion;
}

/// 감정 통계 엔티티
@freezed
class EmotionStatistics with _$EmotionStatistics {
  const EmotionStatistics._();

  const factory EmotionStatistics({
    /// 일별 감정 데이터 (라인 차트용)
    required List<DailyEmotion> dailyEmotions,

    /// 키워드 빈도 (태그용) - {키워드: 빈도}
    required Map<String, int> keywordFrequency,

    /// 날짜별 작성 여부와 감정 점수 (히트맵용) - {날짜: 평균점수}
    required Map<DateTime, double> activityMap,

    /// 전체 일기 수
    required int totalDiaries,

    /// 전체 평균 감정 점수
    required double overallAverageScore,

    /// 통계 기간 시작일
    DateTime? periodStart,

    /// 통계 기간 종료일
    DateTime? periodEnd,
  }) = _EmotionStatistics;

  /// 빈 통계 데이터
  factory EmotionStatistics.empty() {
    return const EmotionStatistics(
      dailyEmotions: [],
      keywordFrequency: {},
      activityMap: {},
      totalDiaries: 0,
      overallAverageScore: 0,
    );
  }

  /// 데이터가 있는지 확인
  bool get hasData => totalDiaries > 0;

  /// 상위 N개 키워드 반환
  List<MapEntry<String, int>> getTopKeywords(int n) {
    final sorted = keywordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  /// 최근 N일 감정 추이 반환
  List<DailyEmotion> getRecentEmotions(int days) {
    if (dailyEmotions.isEmpty) return [];
    return dailyEmotions.take(days).toList();
  }

  /// 특정 기간의 평균 감정 점수 계산
  double getAverageScoreForPeriod(DateTime start, DateTime end) {
    final periodEmotions = dailyEmotions.where(
      (e) =>
          e.date.isAfter(start.subtract(const Duration(days: 1))) &&
          e.date.isBefore(end.add(const Duration(days: 1))),
    );

    if (periodEmotions.isEmpty) return 0;

    final totalScore = periodEmotions.fold<double>(
      0,
      (sum, e) => sum + e.averageScore,
    );
    return totalScore / periodEmotions.length;
  }
}

/// 통계 기간 타입
enum StatisticsPeriod {
  /// 최근 7일
  week,

  /// 최근 30일
  month,

  /// 전체 기간
  all,
}

extension StatisticsPeriodExtension on StatisticsPeriod {
  String get displayName {
    switch (this) {
      case StatisticsPeriod.week:
        return '최근 7일';
      case StatisticsPeriod.month:
        return '최근 30일';
      case StatisticsPeriod.all:
        return '전체';
    }
  }

  int? get days {
    switch (this) {
      case StatisticsPeriod.week:
        return 7;
      case StatisticsPeriod.month:
        return 30;
      case StatisticsPeriod.all:
        return null;
    }
  }
}
