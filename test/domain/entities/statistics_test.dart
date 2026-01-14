import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/statistics.dart';

void main() {
  group('DailyEmotion', () {
    test('기본 생성자로 객체를 생성할 수 있어야 한다', () {
      final emotion = DailyEmotion(
        date: DateTime(2024, 1, 15),
        averageScore: 7.5,
        diaryCount: 3,
      );

      expect(emotion.date, DateTime(2024, 1, 15));
      expect(emotion.averageScore, 7.5);
      expect(emotion.diaryCount, 3);
    });

    test('toString이 올바른 형식을 반환해야 한다', () {
      final emotion = DailyEmotion(
        date: DateTime(2024, 1, 15),
        averageScore: 8.0,
        diaryCount: 2,
      );

      final str = emotion.toString();
      expect(str, contains('DailyEmotion'));
      expect(str, contains('score: 8.0'));
      expect(str, contains('count: 2'));
    });
  });

  group('EmotionStatistics', () {
    test('기본 생성자로 객체를 생성할 수 있어야 한다', () {
      final stats = EmotionStatistics(
        dailyEmotions: [
          DailyEmotion(date: DateTime(2024, 1, 15), averageScore: 7.0, diaryCount: 2),
        ],
        keywordFrequency: {'행복': 5, '만족': 3},
        activityMap: {DateTime(2024, 1, 15): 7.0},
        totalDiaries: 10,
        overallAverageScore: 7.5,
      );

      expect(stats.totalDiaries, 10);
      expect(stats.overallAverageScore, 7.5);
      expect(stats.hasData, true);
    });

    test('empty() 팩토리가 빈 통계를 생성해야 한다', () {
      final stats = EmotionStatistics.empty();

      expect(stats.dailyEmotions, isEmpty);
      expect(stats.keywordFrequency, isEmpty);
      expect(stats.activityMap, isEmpty);
      expect(stats.totalDiaries, 0);
      expect(stats.overallAverageScore, 0);
      expect(stats.hasData, false);
    });

    group('getTopKeywords', () {
      test('상위 N개 키워드를 내림차순으로 반환해야 한다', () {
        final stats = EmotionStatistics(
          dailyEmotions: [],
          keywordFrequency: {
            '행복': 10,
            '만족': 8,
            '평온': 5,
            '기쁨': 3,
            '설렘': 1,
          },
          activityMap: {},
          totalDiaries: 5,
          overallAverageScore: 7.0,
        );

        final top3 = stats.getTopKeywords(3);

        expect(top3.length, 3);
        expect(top3[0].key, '행복');
        expect(top3[0].value, 10);
        expect(top3[1].key, '만족');
        expect(top3[2].key, '평온');
      });

      test('요청한 수보다 키워드가 적으면 있는 만큼만 반환해야 한다', () {
        final stats = EmotionStatistics(
          dailyEmotions: [],
          keywordFrequency: {'행복': 5, '만족': 3},
          activityMap: {},
          totalDiaries: 2,
          overallAverageScore: 7.0,
        );

        final top5 = stats.getTopKeywords(5);

        expect(top5.length, 2);
      });
    });

    group('getRecentEmotions', () {
      test('최근 N일의 감정 데이터를 반환해야 한다', () {
        final stats = EmotionStatistics(
          dailyEmotions: [
            DailyEmotion(date: DateTime(2024, 1, 20), averageScore: 8.0, diaryCount: 2),
            DailyEmotion(date: DateTime(2024, 1, 19), averageScore: 7.0, diaryCount: 1),
            DailyEmotion(date: DateTime(2024, 1, 18), averageScore: 6.0, diaryCount: 1),
            DailyEmotion(date: DateTime(2024, 1, 17), averageScore: 5.0, diaryCount: 1),
            DailyEmotion(date: DateTime(2024, 1, 16), averageScore: 4.0, diaryCount: 1),
          ],
          keywordFrequency: {},
          activityMap: {},
          totalDiaries: 6,
          overallAverageScore: 6.0,
        );

        final recent3 = stats.getRecentEmotions(3);

        expect(recent3.length, 3);
        expect(recent3[0].date, DateTime(2024, 1, 20));
        expect(recent3[2].date, DateTime(2024, 1, 18));
      });

      test('빈 데이터에서 빈 목록을 반환해야 한다', () {
        final stats = EmotionStatistics.empty();

        final recent = stats.getRecentEmotions(7);

        expect(recent, isEmpty);
      });
    });

    group('getAverageScoreForPeriod', () {
      test('특정 기간의 평균 점수를 계산해야 한다', () {
        final stats = EmotionStatistics(
          dailyEmotions: [
            DailyEmotion(date: DateTime(2024, 1, 20), averageScore: 8.0, diaryCount: 1),
            DailyEmotion(date: DateTime(2024, 1, 19), averageScore: 6.0, diaryCount: 1),
            DailyEmotion(date: DateTime(2024, 1, 18), averageScore: 4.0, diaryCount: 1),
            DailyEmotion(date: DateTime(2024, 1, 15), averageScore: 2.0, diaryCount: 1),
          ],
          keywordFrequency: {},
          activityMap: {},
          totalDiaries: 4,
          overallAverageScore: 5.0,
        );

        // 1/18 ~ 1/20 기간의 평균: (8 + 6 + 4) / 3 = 6.0
        final avg = stats.getAverageScoreForPeriod(
          DateTime(2024, 1, 18),
          DateTime(2024, 1, 20),
        );

        expect(avg, 6.0);
      });

      test('해당 기간에 데이터가 없으면 0을 반환해야 한다', () {
        final stats = EmotionStatistics(
          dailyEmotions: [
            DailyEmotion(date: DateTime(2024, 1, 15), averageScore: 7.0, diaryCount: 1),
          ],
          keywordFrequency: {},
          activityMap: {},
          totalDiaries: 1,
          overallAverageScore: 7.0,
        );

        final avg = stats.getAverageScoreForPeriod(
          DateTime(2024, 2, 1),
          DateTime(2024, 2, 28),
        );

        expect(avg, 0);
      });
    });
  });

  group('StatisticsPeriod', () {
    test('모든 기간 값이 정의되어야 한다', () {
      expect(StatisticsPeriod.values.length, 3);
      expect(StatisticsPeriod.values, contains(StatisticsPeriod.week));
      expect(StatisticsPeriod.values, contains(StatisticsPeriod.month));
      expect(StatisticsPeriod.values, contains(StatisticsPeriod.all));
    });

    test('displayName이 올바른 한국어 이름을 반환해야 한다', () {
      expect(StatisticsPeriod.week.displayName, '최근 7일');
      expect(StatisticsPeriod.month.displayName, '최근 30일');
      expect(StatisticsPeriod.all.displayName, '전체');
    });

    test('days가 올바른 일수를 반환해야 한다', () {
      expect(StatisticsPeriod.week.days, 7);
      expect(StatisticsPeriod.month.days, 30);
      expect(StatisticsPeriod.all.days, isNull);
    });
  });
}
