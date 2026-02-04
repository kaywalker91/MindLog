import 'package:mindlog/domain/entities/statistics.dart';
import 'diary_fixtures.dart';

/// 테스트용 Statistics 픽스처
class StatisticsFixtures {
  // 테스트용 고정 시간
  static final DateTime testNow = DiaryFixtures.testNow;

  /// 빈 통계 데이터
  static EmotionStatistics empty() => EmotionStatistics.empty();

  /// 일주일치 통계 데이터
  static EmotionStatistics weekly({DateTime? baseDate}) {
    final base = baseDate ?? testNow;
    final startDate = base.subtract(const Duration(days: 6));

    return EmotionStatistics(
      dailyEmotions: _generateDailyEmotions(7, base),
      keywordFrequency: _weeklyKeywordFrequency(),
      activityMap: _generateActivityMap(7, base),
      totalDiaries: 7,
      overallAverageScore: 6.5,
      periodStart: startDate,
      periodEnd: base,
    );
  }

  /// 한 달치 통계 데이터
  static EmotionStatistics monthly({DateTime? baseDate}) {
    final base = baseDate ?? testNow;
    final startDate = base.subtract(const Duration(days: 29));

    return EmotionStatistics(
      dailyEmotions: _generateDailyEmotions(30, base),
      keywordFrequency: _monthlyKeywordFrequency(),
      activityMap: _generateActivityMap(30, base),
      totalDiaries: 30,
      overallAverageScore: 6.2,
      periodStart: startDate,
      periodEnd: base,
    );
  }

  /// 전체 기간 통계 데이터
  static EmotionStatistics all({int totalDays = 90, DateTime? baseDate}) {
    final base = baseDate ?? testNow;

    return EmotionStatistics(
      dailyEmotions: _generateDailyEmotions(totalDays, base),
      keywordFrequency: _allTimeKeywordFrequency(),
      activityMap: _generateActivityMap(totalDays, base),
      totalDiaries: totalDays,
      overallAverageScore: 6.0,
      periodStart: null,
      periodEnd: base,
    );
  }

  /// 단일 일기만 있는 통계
  static EmotionStatistics singleDiary({DateTime? date, int score = 7}) {
    final diaryDate = date ?? testNow;
    final normalizedDate = DateTime(
      diaryDate.year,
      diaryDate.month,
      diaryDate.day,
    );

    return EmotionStatistics(
      dailyEmotions: [
        DailyEmotion(
          date: normalizedDate,
          averageScore: score.toDouble(),
          diaryCount: 1,
        ),
      ],
      keywordFrequency: {'행복': 1, '만족': 1, '기쁨': 1},
      activityMap: {normalizedDate: score.toDouble()},
      totalDiaries: 1,
      overallAverageScore: score.toDouble(),
      periodStart: normalizedDate,
      periodEnd: normalizedDate,
    );
  }

  /// 하루에 여러 일기가 있는 통계
  static EmotionStatistics multipleDiariesPerDay({DateTime? date}) {
    final diaryDate = date ?? testNow;
    final normalizedDate = DateTime(
      diaryDate.year,
      diaryDate.month,
      diaryDate.day,
    );

    return EmotionStatistics(
      dailyEmotions: [
        DailyEmotion(
          date: normalizedDate,
          averageScore: 6.0, // (5 + 7 + 6) / 3
          diaryCount: 3,
        ),
      ],
      keywordFrequency: {'행복': 2, '피곤': 1, '스트레스': 1, '휴식': 1},
      activityMap: {normalizedDate: 6.0},
      totalDiaries: 3,
      overallAverageScore: 6.0,
      periodStart: normalizedDate,
      periodEnd: normalizedDate,
    );
  }

  /// 커스텀 DailyEmotion 리스트 생성
  static List<DailyEmotion> dailyEmotions({
    required int days,
    DateTime? baseDate,
    List<int>? scores,
  }) {
    final base = baseDate ?? testNow;
    return List.generate(days, (index) {
      final date = DateTime(
        base.year,
        base.month,
        base.day,
      ).subtract(Duration(days: index));
      final score = scores != null && index < scores.length
          ? scores[index]
          : (5 + (index % 5));
      return DailyEmotion(
        date: date,
        averageScore: score.toDouble(),
        diaryCount: 1,
      );
    });
  }

  /// 커스텀 키워드 빈도 생성
  static Map<String, int> keywordFrequency(Map<String, int>? custom) {
    return custom ?? _weeklyKeywordFrequency();
  }

  /// 커스텀 활동 맵 생성
  static Map<DateTime, double> activityMap({
    required int days,
    DateTime? baseDate,
    List<double>? scores,
  }) {
    final base = baseDate ?? testNow;
    final map = <DateTime, double>{};

    for (int i = 0; i < days; i++) {
      final date = DateTime(
        base.year,
        base.month,
        base.day,
      ).subtract(Duration(days: i));
      final score = scores != null && i < scores.length
          ? scores[i]
          : (5 + (i % 5)).toDouble();
      map[date] = score;
    }

    return map;
  }

  // Private helper methods

  static List<DailyEmotion> _generateDailyEmotions(
    int days,
    DateTime baseDate,
  ) {
    return List.generate(days, (index) {
      final date = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
      ).subtract(Duration(days: index));
      final score = (5 + (index % 5)).clamp(1, 10);
      return DailyEmotion(
        date: date,
        averageScore: score.toDouble(),
        diaryCount: 1 + (index % 2), // 1-2개씩 변동
      );
    });
  }

  static Map<DateTime, double> _generateActivityMap(
    int days,
    DateTime baseDate,
  ) {
    final map = <DateTime, double>{};
    for (int i = 0; i < days; i++) {
      final date = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
      ).subtract(Duration(days: i));
      final score = (5 + (i % 5)).clamp(1, 10);
      map[date] = score.toDouble();
    }
    return map;
  }

  static Map<String, int> _weeklyKeywordFrequency() => {
    '행복': 5,
    '피곤': 4,
    '스트레스': 3,
    '운동': 3,
    '가족': 2,
    '일상': 2,
    '만족': 1,
  };

  static Map<String, int> _monthlyKeywordFrequency() => {
    '행복': 15,
    '피곤': 12,
    '스트레스': 10,
    '운동': 8,
    '가족': 7,
    '일상': 6,
    '성취감': 5,
    '친구': 4,
    '배움': 3,
    '만족': 2,
  };

  static Map<String, int> _allTimeKeywordFrequency() => {
    '행복': 45,
    '피곤': 35,
    '스트레스': 30,
    '운동': 25,
    '가족': 20,
    '일상': 18,
    '성취감': 15,
    '친구': 12,
    '배움': 10,
    '만족': 8,
    '사랑': 5,
    '도전': 3,
  };
}
