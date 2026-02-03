import '../entities/statistics.dart';

/// 통계 저장소 인터페이스 (Domain Layer)
abstract class StatisticsRepository {
  /// 감정 통계 조회
  ///
  /// [period] 조회 기간 (week, month, all)
  Future<EmotionStatistics> getStatistics(StatisticsPeriod period);

  /// 특정 기간의 일별 감정 데이터 조회
  Future<List<DailyEmotion>> getDailyEmotions({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// 날짜별 활동 맵 조회 (히트맵용)
  Future<Map<DateTime, double>> getActivityMap({
    DateTime? startDate,
    DateTime? endDate,
  });
}
