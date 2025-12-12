import '../entities/statistics.dart';
import '../repositories/statistics_repository.dart';

/// 통계 조회 유스케이스
class GetStatisticsUseCase {
  final StatisticsRepository _repository;

  GetStatisticsUseCase(this._repository);

  /// 지정된 기간의 감정 통계 조회
  Future<EmotionStatistics> execute(StatisticsPeriod period) async {
    return await _repository.getStatistics(period);
  }

  /// 일별 감정 데이터 조회
  Future<List<DailyEmotion>> getDailyEmotions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _repository.getDailyEmotions(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// 키워드 빈도 조회
  Future<Map<String, int>> getKeywordFrequency({int? limit}) async {
    return await _repository.getKeywordFrequency(limit: limit);
  }

  /// 활동 맵 조회 (히트맵용)
  Future<Map<DateTime, double>> getActivityMap({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _repository.getActivityMap(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
