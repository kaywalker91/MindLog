import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/data/repositories/statistics_repository_impl.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/entities/statistics.dart';

import '../../fixtures/diary_fixtures.dart';
import '../../mocks/mock_datasources.dart';

void main() {
  late StatisticsRepositoryImpl repository;
  late MockSqliteLocalDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockSqliteLocalDataSource();
    repository = StatisticsRepositoryImpl(localDataSource: mockDataSource);
  });

  tearDown(() {
    mockDataSource.reset();
  });

  group('StatisticsRepositoryImpl', () {
    group('getStatistics', () {
      test('주간 통계를 올바르게 계산해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        final weekDiaries = List.generate(7, (i) {
          return DiaryFixtures.analyzed(
            id: 'diary-$i',
            createdAt: now.subtract(Duration(days: i)),
            sentimentScore: 5 + i, // 5, 6, 7, 8, 9, 10, 10
            keywords: ['키워드$i', '공통키워드'],
          );
        });
        mockDataSource.setDiaries(weekDiaries);

        // Act
        final result = await repository.getStatistics(StatisticsPeriod.week);

        // Assert
        expect(result.totalDiaries, 7);
        expect(result.dailyEmotions.length, 7);
        expect(result.periodStart, isNotNull);
        expect(result.periodEnd, isNotNull);
      });

      test('월간 통계를 올바르게 계산해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        final monthDiaries = List.generate(30, (i) {
          return DiaryFixtures.analyzed(
            id: 'diary-$i',
            createdAt: now.subtract(Duration(days: i)),
            sentimentScore: (i % 10) + 1,
          );
        });
        mockDataSource.setDiaries(monthDiaries);

        // Act
        final result = await repository.getStatistics(StatisticsPeriod.month);

        // Assert
        expect(result.totalDiaries, 30);
        expect(result.dailyEmotions.isNotEmpty, true);
      });

      test('전체 기간 통계를 올바르게 계산해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        final allDiaries = List.generate(90, (i) {
          return DiaryFixtures.analyzed(
            id: 'diary-$i',
            createdAt: now.subtract(Duration(days: i)),
            sentimentScore: (i % 10) + 1,
          );
        });
        mockDataSource.setDiaries(allDiaries);

        // Act
        final result = await repository.getStatistics(StatisticsPeriod.all);

        // Assert
        expect(result.totalDiaries, 90);
        expect(result.periodStart, isNull); // 전체 기간은 시작일 없음
      });

      test('데이터가 없을 때 빈 통계를 반환해야 한다', () async {
        // Arrange - 빈 상태

        // Act
        final result = await repository.getStatistics(StatisticsPeriod.week);

        // Assert
        expect(result.totalDiaries, 0);
        expect(result.dailyEmotions, isEmpty);
        expect(result.keywordFrequency, isEmpty);
        expect(result.activityMap, isEmpty);
        expect(result.overallAverageScore, 0.0);
      });

      test('분석되지 않은 일기는 통계에서 제외해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: 'analyzed-1', createdAt: now),
          DiaryFixtures.pending(id: 'pending-1', createdAt: now.subtract(const Duration(hours: 1))),
          DiaryFixtures.failed(id: 'failed-1', createdAt: now.subtract(const Duration(hours: 2))),
          DiaryFixtures.analyzed(id: 'analyzed-2', createdAt: now.subtract(const Duration(hours: 3))),
        ]);

        // Act
        final result = await repository.getStatistics(StatisticsPeriod.week);

        // Assert - pending과 failed는 제외됨
        expect(result.totalDiaries, 2);
      });

      test('safetyBlocked 상태 일기도 통계에 포함해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: 'analyzed-1', createdAt: now),
          DiaryFixtures.safetyBlocked(id: 'blocked-1', createdAt: now.subtract(const Duration(hours: 1))),
        ]);

        // Act
        final result = await repository.getStatistics(StatisticsPeriod.week);

        // Assert
        expect(result.totalDiaries, 2);
      });

      test('평균 점수를 올바르게 계산해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now, sentimentScore: 6),
          DiaryFixtures.analyzed(id: '2', createdAt: now.subtract(const Duration(hours: 1)), sentimentScore: 8),
          DiaryFixtures.analyzed(id: '3', createdAt: now.subtract(const Duration(hours: 2)), sentimentScore: 10),
        ]);

        // Act
        final result = await repository.getStatistics(StatisticsPeriod.week);

        // Assert
        expect(result.overallAverageScore, 8.0); // (6 + 8 + 10) / 3 = 8
      });

      test('키워드 빈도를 올바르게 집계해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now, keywords: ['행복', '기쁨', '만족']),
          DiaryFixtures.analyzed(id: '2', createdAt: now.subtract(const Duration(hours: 1)), keywords: ['행복', '피곤']),
          DiaryFixtures.analyzed(id: '3', createdAt: now.subtract(const Duration(hours: 2)), keywords: ['행복', '스트레스']),
        ]);

        // Act
        final result = await repository.getStatistics(StatisticsPeriod.week);

        // Assert
        expect(result.keywordFrequency['행복'], 3);
        expect(result.keywordFrequency['피곤'], 1);
        expect(result.keywordFrequency['기쁨'], 1);
      });

      test('DataSource 에러 시 Failure를 던져야 한다', () async {
        // Arrange
        mockDataSource.shouldThrowOnGet = true;

        // Act & Assert
        await expectLater(
          repository.getStatistics(StatisticsPeriod.week),
          throwsA(isA<Failure>()),
        );
      });
    });

    group('getDailyEmotions', () {
      test('날짜 범위로 필터링해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 3));
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now, sentimentScore: 7),
          DiaryFixtures.analyzed(id: '2', createdAt: now.subtract(const Duration(days: 2)), sentimentScore: 6),
          DiaryFixtures.analyzed(id: '3', createdAt: now.subtract(const Duration(days: 5)), sentimentScore: 5), // 범위 밖
        ]);

        // Act
        final result = await repository.getDailyEmotions(
          startDate: startDate,
          endDate: now,
        );

        // Assert
        expect(result.length, 2); // 범위 내 일기만
      });

      test('빈 결과를 처리해야 한다', () async {
        // Arrange - 빈 상태

        // Act
        final result = await repository.getDailyEmotions();

        // Assert
        expect(result, isEmpty);
      });

      test('날짜순으로 정렬되어야 한다 (최신순)', () async {
        // Arrange
        final now = DateTime.now();
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now.subtract(const Duration(days: 2))),
          DiaryFixtures.analyzed(id: '2', createdAt: now),
          DiaryFixtures.analyzed(id: '3', createdAt: now.subtract(const Duration(days: 1))),
        ]);

        // Act
        final result = await repository.getDailyEmotions();

        // Assert
        expect(result.length, 3);
        expect(result[0].date.isAfter(result[1].date), true);
        expect(result[1].date.isAfter(result[2].date), true);
      });

      test('같은 날 여러 일기의 평균을 계산해야 한다', () async {
        // Arrange
        final now = DateTime(2024, 1, 15, 12, 0);
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now, sentimentScore: 6),
          DiaryFixtures.analyzed(id: '2', createdAt: now.subtract(const Duration(hours: 2)), sentimentScore: 8),
          DiaryFixtures.analyzed(id: '3', createdAt: now.subtract(const Duration(hours: 4)), sentimentScore: 10),
        ]);

        // Act
        final result = await repository.getDailyEmotions();

        // Assert
        expect(result.length, 1); // 같은 날이므로 1개
        expect(result[0].averageScore, 8.0); // (6 + 8 + 10) / 3 = 8
        expect(result[0].diaryCount, 3);
      });

      test('DataSource 에러 시 Failure를 던져야 한다', () async {
        // Arrange
        mockDataSource.shouldThrowOnGet = true;

        // Act & Assert
        await expectLater(
          repository.getDailyEmotions(),
          throwsA(isA<Failure>()),
        );
      });
    });

    group('getKeywordFrequency', () {
      test('빈도순으로 정렬해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now, keywords: ['A', 'B', 'C']),
          DiaryFixtures.analyzed(id: '2', createdAt: now.subtract(const Duration(hours: 1)), keywords: ['A', 'B']),
          DiaryFixtures.analyzed(id: '3', createdAt: now.subtract(const Duration(hours: 2)), keywords: ['A']),
        ]);

        // Act
        final result = await repository.getKeywordFrequency();

        // Assert
        final sorted = result.entries.toList();
        expect(sorted[0].key, 'A');
        expect(sorted[0].value, 3);
        expect(sorted[1].key, 'B');
        expect(sorted[1].value, 2);
      });

      test('limit을 적용해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now, keywords: ['A', 'B', 'C', 'D', 'E']),
          DiaryFixtures.analyzed(id: '2', createdAt: now.subtract(const Duration(hours: 1)), keywords: ['A', 'B', 'C']),
        ]);

        // Act
        final result = await repository.getKeywordFrequency(limit: 3);

        // Assert
        expect(result.length, 3);
      });

      test('limit이 null이면 전체를 반환해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now, keywords: ['A', 'B', 'C', 'D', 'E']),
        ]);

        // Act
        final result = await repository.getKeywordFrequency(limit: null);

        // Assert
        expect(result.length, 5);
      });

      test('중복 키워드를 올바르게 집계해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now, keywords: ['행복', '행복', '기쁨']),
          DiaryFixtures.analyzed(id: '2', createdAt: now.subtract(const Duration(hours: 1)), keywords: ['행복']),
        ]);

        // Act
        final result = await repository.getKeywordFrequency();

        // Assert
        // 같은 일기 내 중복은 각각 카운트됨
        expect(result['행복'], 3);
        expect(result['기쁨'], 1);
      });

      test('빈 키워드는 무시해야 한다', () async {
        // Arrange
        final now = DateTime.now();
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now, keywords: ['유효', '', '  ', '키워드']),
        ]);

        // Act
        final result = await repository.getKeywordFrequency();

        // Assert
        expect(result.containsKey(''), false);
        expect(result.length, 2);
      });

      test('DataSource 에러 시 Failure를 던져야 한다', () async {
        // Arrange
        mockDataSource.shouldThrowOnGet = true;

        // Act & Assert
        await expectLater(
          repository.getKeywordFrequency(),
          throwsA(isA<Failure>()),
        );
      });
    });

    group('getActivityMap', () {
      test('날짜별 활동량을 반환해야 한다', () async {
        // Arrange
        final now = DateTime(2024, 1, 15);
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now, sentimentScore: 7),
          DiaryFixtures.analyzed(id: '2', createdAt: now.subtract(const Duration(days: 1)), sentimentScore: 5),
        ]);

        // Act
        final result = await repository.getActivityMap();

        // Assert
        expect(result.length, 2);
        expect(result[DateTime(now.year, now.month, now.day)], 7.0);
      });

      test('날짜 범위로 필터링해야 한다', () async {
        // Arrange
        final now = DateTime(2024, 1, 15);
        final startDate = now.subtract(const Duration(days: 2));
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now),
          DiaryFixtures.analyzed(id: '2', createdAt: now.subtract(const Duration(days: 1))),
          DiaryFixtures.analyzed(id: '3', createdAt: now.subtract(const Duration(days: 5))), // 범위 밖
        ]);

        // Act
        final result = await repository.getActivityMap(
          startDate: startDate,
          endDate: now,
        );

        // Assert
        expect(result.length, 2);
      });

      test('같은 날 여러 일기의 평균을 계산해야 한다', () async {
        // Arrange
        final now = DateTime(2024, 1, 15, 12, 0);
        mockDataSource.setDiaries([
          DiaryFixtures.analyzed(id: '1', createdAt: now, sentimentScore: 4),
          DiaryFixtures.analyzed(id: '2', createdAt: now.subtract(const Duration(hours: 2)), sentimentScore: 6),
        ]);

        // Act
        final result = await repository.getActivityMap();

        // Assert
        final dateKey = DateTime(now.year, now.month, now.day);
        expect(result[dateKey], 5.0); // (4 + 6) / 2 = 5
      });

      test('DataSource 에러 시 Failure를 던져야 한다', () async {
        // Arrange
        mockDataSource.shouldThrowOnGet = true;

        // Act & Assert
        await expectLater(
          repository.getActivityMap(),
          throwsA(isA<Failure>()),
        );
      });
    });

    group('성능 최적화 검증', () {
      test('1-pass 계산이 올바른 결과를 반환해야 한다', () async {
        // Arrange - 대량 데이터
        final now = DateTime.now();
        final largeDiaries = List.generate(100, (i) {
          return DiaryFixtures.analyzed(
            id: 'diary-$i',
            createdAt: now.subtract(Duration(days: i % 30)),
            sentimentScore: (i % 10) + 1,
            keywords: ['키워드${i % 5}'],
          );
        });
        mockDataSource.setDiaries(largeDiaries);

        // Act
        final result = await repository.getStatistics(StatisticsPeriod.month);

        // Assert
        expect(result.totalDiaries, 100);
        expect(result.dailyEmotions.isNotEmpty, true);
        expect(result.keywordFrequency.isNotEmpty, true);
        expect(result.activityMap.isNotEmpty, true);
      });
    });
  });
}
