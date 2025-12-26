import '../../domain/entities/diary.dart';
import '../../domain/entities/statistics.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/local/sqlite_local_datasource.dart';

/// 통계 Repository 구현체
class StatisticsRepositoryImpl implements StatisticsRepository {
  final SqliteLocalDataSource _localDataSource;

  StatisticsRepositoryImpl({
    required SqliteLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<EmotionStatistics> getStatistics(StatisticsPeriod period) async {
    final now = DateTime.now();
    DateTime? startDate;

    // 기간에 따른 시작일 계산
    if (period.days != null) {
      startDate = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: period.days! - 1));
    }

    // SQL 레벨에서 필터링된 일기 조회 (성능 최적화)
    final analyzedDiaries = await _localDataSource.getAnalyzedDiariesInRange(
      startDate: startDate,
      endDate: now,
    );

    if (analyzedDiaries.isEmpty) {
      return EmotionStatistics.empty();
    }

    // 단일 패스로 일별 감정 + 활동 맵 + 평균 점수 계산 (성능 최적화)
    final (dailyEmotions, activityMap, overallAverage) =
        _calculateDailyStats(analyzedDiaries);

    // 키워드 빈도 계산
    final keywordFrequency = _calculateKeywordFrequency(analyzedDiaries);

    return EmotionStatistics(
      dailyEmotions: dailyEmotions,
      keywordFrequency: keywordFrequency,
      activityMap: activityMap,
      totalDiaries: analyzedDiaries.length,
      overallAverageScore: overallAverage,
      periodStart: startDate,
      periodEnd: now,
    );
  }

  @override
  Future<List<DailyEmotion>> getDailyEmotions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // SQL 레벨에서 필터링 (성능 최적화)
    final filteredDiaries = await _localDataSource.getAnalyzedDiariesInRange(
      startDate: startDate,
      endDate: endDate,
    );

    return _calculateDailyEmotions(filteredDiaries);
  }

  @override
  Future<Map<String, int>> getKeywordFrequency({int? limit}) async {
    // SQL 레벨에서 필터링 (성능 최적화)
    final analyzedDiaries = await _localDataSource.getAnalyzedDiariesInRange();

    final frequency = _calculateKeywordFrequency(analyzedDiaries);

    if (limit == null) return frequency;

    // 상위 N개만 반환
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(limit));
  }

  @override
  Future<Map<DateTime, double>> getActivityMap({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // SQL 레벨에서 필터링 (성능 최적화)
    final filteredDiaries = await _localDataSource.getAnalyzedDiariesInRange(
      startDate: startDate,
      endDate: endDate,
    );

    return _calculateActivityMap(filteredDiaries);
  }

  /// 단일 패스로 일별 통계 계산 (dailyEmotions, activityMap, overallAverage)
  /// 성능 최적화: 기존 4-pass → 1-pass
  (List<DailyEmotion>, Map<DateTime, double>, double) _calculateDailyStats(
    List<Diary> diaries,
  ) {
    // 날짜별로 점수 그룹핑
    final Map<DateTime, List<int>> grouped = {};
    final Map<DateTime, int> diaryCountPerDay = {};
    int totalScore = 0;
    int scoreCount = 0;

    for (final diary in diaries) {
      if (diary.analysisResult == null) continue;

      final date = DateTime(
        diary.createdAt.year,
        diary.createdAt.month,
        diary.createdAt.day,
      );

      grouped[date] ??= [];
      grouped[date]!.add(diary.analysisResult!.sentimentScore);
      diaryCountPerDay[date] = (diaryCountPerDay[date] ?? 0) + 1;

      totalScore += diary.analysisResult!.sentimentScore;
      scoreCount++;
    }

    // 일별 감정 리스트 + 활동 맵 동시 생성
    final List<DailyEmotion> dailyEmotions = [];
    final Map<DateTime, double> activityMap = {};

    for (final entry in grouped.entries) {
      final date = entry.key;
      final scores = entry.value;
      final averageScore = scores.reduce((a, b) => a + b) / scores.length;

      dailyEmotions.add(DailyEmotion(
        date: date,
        averageScore: averageScore,
        diaryCount: diaryCountPerDay[date] ?? scores.length,
      ));

      activityMap[date] = averageScore;
    }

    // 날짜순 정렬 (최신순)
    dailyEmotions.sort((a, b) => b.date.compareTo(a.date));

    final overallAverage = scoreCount == 0 ? 0.0 : totalScore / scoreCount;

    return (dailyEmotions, activityMap, overallAverage);
  }

  /// 일별 감정 데이터 계산 (단독 호출용)
  List<DailyEmotion> _calculateDailyEmotions(List<Diary> diaries) {
    final (dailyEmotions, _, _) = _calculateDailyStats(diaries);
    return dailyEmotions;
  }

  /// 키워드 빈도 계산
  Map<String, int> _calculateKeywordFrequency(List<Diary> diaries) {
    final Map<String, int> frequency = {};

    for (final diary in diaries) {
      if (diary.analysisResult == null) continue;

      for (final keyword in diary.analysisResult!.keywords) {
        final normalizedKeyword = keyword.trim();
        if (normalizedKeyword.isEmpty) continue;

        frequency[normalizedKeyword] = (frequency[normalizedKeyword] ?? 0) + 1;
      }
    }

    return frequency;
  }

  /// 활동 맵 계산 (단독 호출용)
  Map<DateTime, double> _calculateActivityMap(List<Diary> diaries) {
    final (_, activityMap, _) = _calculateDailyStats(diaries);
    return activityMap;
  }
}
