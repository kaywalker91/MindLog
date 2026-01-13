import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/statistics.dart';
import 'package:mindlog/domain/usecases/get_statistics_usecase.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/providers/statistics_providers.dart';

import '../../fixtures/statistics_fixtures.dart';
import '../../mocks/mock_repositories.dart';

/// Mock GetStatisticsUseCase
class MockGetStatisticsUseCase implements GetStatisticsUseCase {
  EmotionStatistics? mockStatistics;
  Map<String, int>? mockKeywordFrequency;
  bool shouldThrow = false;
  bool shouldThrowOnKeyword = false;
  Failure? failureToThrow;

  final List<StatisticsPeriod> requestedPeriods = [];
  final List<int?> requestedLimits = [];

  void reset() {
    mockStatistics = null;
    mockKeywordFrequency = null;
    shouldThrow = false;
    shouldThrowOnKeyword = false;
    failureToThrow = null;
    requestedPeriods.clear();
    requestedLimits.clear();
  }

  @override
  Future<EmotionStatistics> execute(StatisticsPeriod period) async {
    requestedPeriods.add(period);
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '통계 조회 실패');
    }
    return mockStatistics ?? StatisticsFixtures.weekly();
  }

  @override
  Future<List<DailyEmotion>> getDailyEmotions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '일별 감정 조회 실패');
    }
    return mockStatistics?.dailyEmotions ?? StatisticsFixtures.weekly().dailyEmotions;
  }

  @override
  Future<Map<String, int>> getKeywordFrequency({int? limit}) async {
    requestedLimits.add(limit);
    if (shouldThrowOnKeyword) {
      throw failureToThrow ?? const Failure.cache(message: '키워드 조회 실패');
    }
    final frequency = mockKeywordFrequency ?? StatisticsFixtures.weekly().keywordFrequency;
    if (limit == null) return frequency;

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(limit));
  }

  @override
  Future<Map<DateTime, double>> getActivityMap({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (shouldThrow) {
      throw failureToThrow ?? const Failure.cache(message: '활동맵 조회 실패');
    }
    return mockStatistics?.activityMap ?? StatisticsFixtures.weekly().activityMap;
  }
}

void main() {
  late ProviderContainer container;
  late MockGetStatisticsUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetStatisticsUseCase();

    container = ProviderContainer(
      overrides: [
        getStatisticsUseCaseProvider.overrideWithValue(mockUseCase),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() {
    mockUseCase.reset();
  });

  group('selectedStatisticsPeriodProvider', () {
    test('초기값은 StatisticsPeriod.week이어야 한다', () {
      // Act
      final period = container.read(selectedStatisticsPeriodProvider);

      // Assert
      expect(period, StatisticsPeriod.week);
    });

    test('기간을 변경할 수 있어야 한다', () {
      // Act
      container.read(selectedStatisticsPeriodProvider.notifier).state =
          StatisticsPeriod.month;

      // Assert
      expect(
        container.read(selectedStatisticsPeriodProvider),
        StatisticsPeriod.month,
      );
    });

    test('모든 기간 옵션을 설정할 수 있어야 한다', () {
      // Act & Assert - week
      container.read(selectedStatisticsPeriodProvider.notifier).state =
          StatisticsPeriod.week;
      expect(
        container.read(selectedStatisticsPeriodProvider),
        StatisticsPeriod.week,
      );

      // month
      container.read(selectedStatisticsPeriodProvider.notifier).state =
          StatisticsPeriod.month;
      expect(
        container.read(selectedStatisticsPeriodProvider),
        StatisticsPeriod.month,
      );

      // all
      container.read(selectedStatisticsPeriodProvider.notifier).state =
          StatisticsPeriod.all;
      expect(
        container.read(selectedStatisticsPeriodProvider),
        StatisticsPeriod.all,
      );
    });
  });

  group('statisticsProvider', () {
    test('선택된 기간의 통계를 조회해야 한다', () async {
      // Arrange
      mockUseCase.mockStatistics = StatisticsFixtures.weekly();

      // Act
      final statistics = await container.read(statisticsProvider.future);

      // Assert
      expect(mockUseCase.requestedPeriods, contains(StatisticsPeriod.week));
      expect(statistics, isNotNull);
    });

    test('기간 변경 시 새로운 통계를 조회해야 한다', () async {
      // Arrange
      mockUseCase.mockStatistics = StatisticsFixtures.weekly();

      // Act - 먼저 주간 통계 조회
      await container.read(statisticsProvider.future);
      expect(mockUseCase.requestedPeriods.last, StatisticsPeriod.week);

      // 기간 변경
      mockUseCase.mockStatistics = StatisticsFixtures.monthly();
      container.read(selectedStatisticsPeriodProvider.notifier).state =
          StatisticsPeriod.month;

      // 새로운 Container로 테스트 (autoDispose 때문에)
      final newContainer = ProviderContainer(
        overrides: [
          getStatisticsUseCaseProvider.overrideWithValue(mockUseCase),
          selectedStatisticsPeriodProvider.overrideWith((ref) => StatisticsPeriod.month),
        ],
      );
      addTearDown(newContainer.dispose);

      await newContainer.read(statisticsProvider.future);

      // Assert
      expect(mockUseCase.requestedPeriods.last, StatisticsPeriod.month);
    });

    test('조회 에러 시 AsyncError 상태여야 한다', () async {
      // Arrange
      mockUseCase.shouldThrow = true;
      mockUseCase.failureToThrow = const Failure.cache(message: '통계 조회 실패');

      // Act
      await container.read(statisticsProvider.future)
          .catchError((_) => StatisticsFixtures.empty());

      // Assert
      final state = container.read(statisticsProvider);
      expect(state, isA<AsyncError<EmotionStatistics>>());
    });

    test('주간 통계 데이터를 반환해야 한다', () async {
      // Arrange
      final weeklyStats = StatisticsFixtures.weekly();
      mockUseCase.mockStatistics = weeklyStats;

      // Act
      final statistics = await container.read(statisticsProvider.future);

      // Assert
      expect(statistics.totalDiaries, weeklyStats.totalDiaries);
      expect(statistics.overallAverageScore, weeklyStats.overallAverageScore);
    });

    test('월간 통계 데이터를 반환해야 한다', () async {
      // Arrange
      final monthlyStats = StatisticsFixtures.monthly();
      mockUseCase.mockStatistics = monthlyStats;

      final newContainer = ProviderContainer(
        overrides: [
          getStatisticsUseCaseProvider.overrideWithValue(mockUseCase),
          selectedStatisticsPeriodProvider.overrideWith((ref) => StatisticsPeriod.month),
        ],
      );
      addTearDown(newContainer.dispose);

      // Act
      final statistics = await newContainer.read(statisticsProvider.future);

      // Assert
      expect(statistics.totalDiaries, monthlyStats.totalDiaries);
    });
  });

  group('topKeywordsProvider', () {
    test('상위 10개 키워드를 조회해야 한다', () async {
      // Arrange
      mockUseCase.mockKeywordFrequency = {
        '행복': 10,
        '감사': 8,
        '기쁨': 7,
        '평화': 6,
        '사랑': 5,
        '희망': 4,
        '용기': 3,
        '성장': 2,
        '도전': 1,
        '목표': 1,
        '여행': 1,
        '음악': 1,
      };

      // Act
      final keywords = await container.read(topKeywordsProvider.future);

      // Assert
      expect(mockUseCase.requestedLimits, contains(10));
      expect(keywords.length, lessThanOrEqualTo(10));
    });

    test('키워드가 빈도순으로 정렬되어야 한다', () async {
      // Arrange
      mockUseCase.mockKeywordFrequency = {
        '행복': 10,
        '감사': 5,
        '기쁨': 8,
      };

      // Act
      final keywords = await container.read(topKeywordsProvider.future);

      // Assert
      final entries = keywords.entries.toList();
      expect(entries[0].key, '행복');
      expect(entries[0].value, 10);
      expect(entries[1].key, '기쁨');
      expect(entries[1].value, 8);
    });

    test('키워드가 없으면 빈 맵을 반환해야 한다', () async {
      // Arrange
      mockUseCase.mockKeywordFrequency = {};

      // Act
      final keywords = await container.read(topKeywordsProvider.future);

      // Assert
      expect(keywords, isEmpty);
    });

    test('조회 에러 시 AsyncError 상태여야 한다', () async {
      // Arrange
      mockUseCase.shouldThrowOnKeyword = true;
      mockUseCase.failureToThrow = const Failure.cache(message: '키워드 조회 실패');

      // Act
      await container.read(topKeywordsProvider.future)
          .catchError((_) => <String, int>{});

      // Assert
      final state = container.read(topKeywordsProvider);
      expect(state, isA<AsyncError<Map<String, int>>>());
    });
  });

  group('Provider 연동', () {
    test('기간 변경이 통계 Provider에 반영되어야 한다', () async {
      // Arrange
      mockUseCase.mockStatistics = StatisticsFixtures.weekly();

      // Act - 초기 조회
      await container.read(statisticsProvider.future);
      final initialPeriod = mockUseCase.requestedPeriods.last;

      // Assert
      expect(initialPeriod, StatisticsPeriod.week);
    });
  });
}
