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

    // 일별 감정 데이터 계산
    final dailyEmotions = _calculateDailyEmotions(analyzedDiaries);

    // 키워드 빈도 계산
    final keywordFrequency = _calculateKeywordFrequency(analyzedDiaries);

    // 활동 맵 계산
    final activityMap = _calculateActivityMap(analyzedDiaries);

    // 전체 평균 점수 계산
    final scores = analyzedDiaries
        .where((d) => d.analysisResult != null)
        .map((d) => d.analysisResult!.sentimentScore)
        .toList();

    final overallAverage = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;

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

  /// 일별 감정 데이터 계산
  List<DailyEmotion> _calculateDailyEmotions(List<Diary> diaries) {
    // 날짜별로 그룹핑
    final Map<String, List<Diary>> grouped = {};

    for (final diary in diaries) {
      final dateKey = _dateToKey(diary.createdAt);
      grouped[dateKey] ??= [];
      grouped[dateKey]!.add(diary);
    }

    // 일별 평균 계산
    final List<DailyEmotion> result = [];

    for (final entry in grouped.entries) {
      final dateParts = entry.key.split('-');
      final date = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );

      final scores = entry.value
          .where((d) => d.analysisResult != null)
          .map((d) => d.analysisResult!.sentimentScore)
          .toList();

      if (scores.isEmpty) continue;

      final averageScore = scores.reduce((a, b) => a + b) / scores.length;

      result.add(DailyEmotion(
        date: date,
        averageScore: averageScore,
        diaryCount: entry.value.length,
      ));
    }

    // 날짜순 정렬 (최신순)
    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
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

  /// 활동 맵 계산 (날짜별 평균 감정 점수)
  Map<DateTime, double> _calculateActivityMap(List<Diary> diaries) {
    final Map<String, List<int>> grouped = {};

    for (final diary in diaries) {
      if (diary.analysisResult == null) continue;

      final dateKey = _dateToKey(diary.createdAt);
      grouped[dateKey] ??= [];
      grouped[dateKey]!.add(diary.analysisResult!.sentimentScore);
    }

    final Map<DateTime, double> result = {};

    for (final entry in grouped.entries) {
      final dateParts = entry.key.split('-');
      final date = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );

      final averageScore = entry.value.reduce((a, b) => a + b) / entry.value.length;
      result[date] = averageScore;
    }

    return result;
  }

  /// DateTime을 "yyyy-MM-dd" 형식의 키로 변환
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
