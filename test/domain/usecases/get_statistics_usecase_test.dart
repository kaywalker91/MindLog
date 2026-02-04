import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/statistics.dart';
import 'package:mindlog/domain/usecases/get_statistics_usecase.dart';

import '../../fixtures/statistics_fixtures.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  late GetStatisticsUseCase useCase;
  late MockStatisticsRepository mockRepository;

  setUp(() {
    mockRepository = MockStatisticsRepository();
    useCase = GetStatisticsUseCase(mockRepository);
  });

  tearDown(() {
    mockRepository.reset();
  });

  group('GetStatisticsUseCase', () {
    group('execute', () {
      test('StatisticsPeriod.week을 Repository에 전달해야 한다', () async {
        // Arrange
        mockRepository.mockStatistics = StatisticsFixtures.weekly();

        // Act
        final result = await useCase.execute(StatisticsPeriod.week);

        // Assert
        expect(
          mockRepository.requestedPeriods,
          contains(StatisticsPeriod.week),
        );
        expect(result.totalDiaries, 7);
      });

      test('StatisticsPeriod.month를 Repository에 전달해야 한다', () async {
        // Arrange
        mockRepository.mockStatistics = StatisticsFixtures.monthly();

        // Act
        final result = await useCase.execute(StatisticsPeriod.month);

        // Assert
        expect(
          mockRepository.requestedPeriods,
          contains(StatisticsPeriod.month),
        );
        expect(result.totalDiaries, 30);
      });

      test('StatisticsPeriod.all을 Repository에 전달해야 한다', () async {
        // Arrange
        mockRepository.mockStatistics = StatisticsFixtures.all();

        // Act
        final result = await useCase.execute(StatisticsPeriod.all);

        // Assert
        expect(mockRepository.requestedPeriods, contains(StatisticsPeriod.all));
        expect(result.totalDiaries, 90);
      });

      test('Repository 에러를 전파해야 한다', () async {
        // Arrange
        mockRepository.shouldThrowOnGetStatistics = true;
        mockRepository.failureToThrow = const Failure.cache(
          message: '통계 조회 실패',
        );

        // Act & Assert
        await expectLater(
          useCase.execute(StatisticsPeriod.week),
          throwsA(isA<CacheFailure>()),
        );
      });

      test('빈 통계를 올바르게 반환해야 한다', () async {
        // Arrange
        mockRepository.mockStatistics = StatisticsFixtures.empty();

        // Act
        final result = await useCase.execute(StatisticsPeriod.week);

        // Assert
        expect(result.totalDiaries, 0);
        expect(result.hasData, false);
      });

      test('dailyEmotions 데이터를 포함해야 한다', () async {
        // Arrange
        mockRepository.mockStatistics = StatisticsFixtures.weekly();

        // Act
        final result = await useCase.execute(StatisticsPeriod.week);

        // Assert
        expect(result.dailyEmotions.isNotEmpty, true);
        expect(result.dailyEmotions.length, 7);
      });

      test('keywordFrequency 데이터를 포함해야 한다', () async {
        // Arrange
        mockRepository.mockStatistics = StatisticsFixtures.weekly();

        // Act
        final result = await useCase.execute(StatisticsPeriod.week);

        // Assert
        expect(result.keywordFrequency.isNotEmpty, true);
      });
    });

    group('getDailyEmotions', () {
      test('날짜 파라미터를 Repository에 전달해야 한다', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 7);

        // Act
        await useCase.getDailyEmotions(startDate: startDate, endDate: endDate);

        // Assert
        expect(mockRepository.dailyEmotionRequests.length, 1);
        expect(
          mockRepository.dailyEmotionRequests.first['startDate'],
          startDate,
        );
        expect(mockRepository.dailyEmotionRequests.first['endDate'], endDate);
      });

      test('파라미터 없이 호출 시 기본값을 사용해야 한다', () async {
        // Act
        await useCase.getDailyEmotions();

        // Assert
        expect(mockRepository.dailyEmotionRequests.length, 1);
        expect(mockRepository.dailyEmotionRequests.first['startDate'], isNull);
        expect(mockRepository.dailyEmotionRequests.first['endDate'], isNull);
      });

      test('Repository 에러를 전파해야 한다', () async {
        // Arrange
        mockRepository.shouldThrowOnGetDailyEmotions = true;

        // Act & Assert
        await expectLater(useCase.getDailyEmotions(), throwsA(isA<Failure>()));
      });

      test('DailyEmotion 리스트를 반환해야 한다', () async {
        // Arrange
        mockRepository.mockDailyEmotions = StatisticsFixtures.dailyEmotions(
          days: 7,
        );

        // Act
        final result = await useCase.getDailyEmotions();

        // Assert
        expect(result.length, 7);
        expect(result.first, isA<DailyEmotion>());
      });
    });

    group('getActivityMap', () {
      test('날짜 파라미터를 Repository에 전달해야 한다', () async {
        // Arrange
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        // Act
        await useCase.getActivityMap(startDate: startDate, endDate: endDate);

        // Assert
        expect(mockRepository.activityMapRequests.length, 1);
        expect(
          mockRepository.activityMapRequests.first['startDate'],
          startDate,
        );
        expect(mockRepository.activityMapRequests.first['endDate'], endDate);
      });

      test('파라미터 없이 호출 시 기본값을 사용해야 한다', () async {
        // Act
        await useCase.getActivityMap();

        // Assert
        expect(mockRepository.activityMapRequests.first['startDate'], isNull);
        expect(mockRepository.activityMapRequests.first['endDate'], isNull);
      });

      test('Repository 에러를 전파해야 한다', () async {
        // Arrange
        mockRepository.shouldThrowOnGetActivityMap = true;

        // Act & Assert
        await expectLater(useCase.getActivityMap(), throwsA(isA<Failure>()));
      });

      test('활동 맵을 반환해야 한다', () async {
        // Arrange
        final testDate = DateTime(2024, 1, 15);
        mockRepository.mockActivityMap = {testDate: 7.5};

        // Act
        final result = await useCase.getActivityMap();

        // Assert
        expect(result[testDate], 7.5);
      });
    });

    group('통합 시나리오', () {
      test('여러 메서드를 순차적으로 호출해도 정상 동작해야 한다', () async {
        // Arrange
        mockRepository.mockStatistics = StatisticsFixtures.weekly();

        // Act
        final statistics = await useCase.execute(StatisticsPeriod.week);
        final dailyEmotions = await useCase.getDailyEmotions();
        final activityMap = await useCase.getActivityMap();

        // Assert
        expect(statistics.totalDiaries, 7);
        expect(dailyEmotions.isNotEmpty, true);
        expect(activityMap.isNotEmpty, true);
      });
    });
  });
}
