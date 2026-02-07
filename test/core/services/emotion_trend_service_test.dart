import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/services/emotion_trend_service.dart';
import 'package:mindlog/domain/entities/statistics.dart';

void main() {
  setUp(() {
    EmotionTrendService.resetForTesting();
  });

  tearDown(() {
    EmotionTrendService.resetForTesting();
  });

  group('EmotionTrendService - 빈 데이터 및 부족한 데이터', () {
    test('빈 리스트를 전달하면 null을 반환한다', () {
      // Arrange
      final emptyList = <DailyEmotion>[];

      // Act
      final result = EmotionTrendService.analyzeTrend(emptyList);

      // Assert
      expect(result, isNull);
    });

    test('1개 엔트리만 있으면 null을 반환한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final oneEntry = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(oneEntry);

      // Assert
      expect(result, isNull);
    });

    test('2개 엔트리만 있으면 null을 반환한다 (recovering/declining 최소 3개 필요)', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final twoEntries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 7.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(twoEntries);

      // Assert
      expect(result, isNull);
    });
  });

  group('EmotionTrendService - Gap 감지', () {
    test('마지막 기록이 정확히 3일 전이면 gap을 감지한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 3)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.gap);
      expect(result.metadata['daysSinceLastEntry'], 3);
      expect(
        result.metadata['lastEntryDate'],
        now.subtract(const Duration(days: 3)).toIso8601String(),
      );
    });

    test('마지막 기록이 5일 전이면 gap을 감지한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 10)),
          averageScore: 7.0,
          diaryCount: 2,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 5)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.gap);
      expect(result.metadata['daysSinceLastEntry'], 5);
    });

    test('마지막 기록이 2일 전이면 gap을 감지하지 않는다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      // 2일 전은 gap이 아니고, 데이터 부족으로 null
      expect(result, isNull);
    });

    test('최신 기록이 오늘이면 gap을 감지하지 않는다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 3)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 5.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now,
          averageScore: 4.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      // gap이 아니므로 declining 감지됨 (3일 연속 하락)
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.declining);
    });
  });

  group('EmotionTrendService - Steady 감지', () {
    test('최근 7일 내 3개 엔트리, 평균 7.0 이상이면 steady를 감지한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 6)),
          averageScore: 7.5,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 4)),
          averageScore: 7.2,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.steady);
      expect(result.metadata['averageScore'], closeTo(7.566, 0.01));
      expect(result.metadata['entryCount'], 3);
      expect(result.metadata['periodDays'], 7);
    });

    test('최근 7일 내 5개 엔트리, 평균 8.0이면 steady를 감지한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 6)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 5)),
          averageScore: 8.2,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 3)),
          averageScore: 7.8,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 8.1,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 7.9,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.steady);
      expect(result.metadata['averageScore'], closeTo(8.0, 0.01));
      expect(result.metadata['entryCount'], 5);
    });

    test('최근 7일 내 3개 엔트리지만 평균 6.9면 steady를 감지하지 않는다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 6)),
          averageScore: 6.8,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 4)),
          averageScore: 6.9,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 7.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      // 평균 6.9이므로 steady가 아님, 다른 트렌드도 없어 null
      expect(result, isNull);
    });

    test('최근 7일 내 2개 엔트리만 있으면 steady를 감지하지 않는다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 5)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNull);
    });

    test('7일보다 오래된 데이터는 steady 계산에서 제외된다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        // 8일 전 (제외됨)
        DailyEmotion(
          date: now.subtract(const Duration(days: 8)),
          averageScore: 9.0,
          diaryCount: 1,
        ),
        // 최근 7일 내
        DailyEmotion(
          date: now.subtract(const Duration(days: 6)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 4)),
          averageScore: 6.5,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      // 최근 7일 평균 = (6.0 + 6.5 + 6.0) / 3 = 6.166 < 7.0
      expect(result, isNull);
    });
  });

  group('EmotionTrendService - Recovering 감지', () {
    test('3개 데이터에서 하락 후 상승 패턴이면 recovering을 감지한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 7.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 5.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now,
          averageScore: 6.5,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.recovering);
      expect(result.metadata['lowestScore'], 5.0);
      expect(result.metadata['currentScore'], 6.5);
      expect(result.metadata['consecutiveRisingDays'], 1);
    });

    test('4개 데이터에서 하락 후 2일 연속 상승이면 recovering을 감지한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 3)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 5.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now,
          averageScore: 7.5,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.recovering);
      expect(result.metadata['lowestScore'], 5.0);
      expect(result.metadata['currentScore'], 7.5);
      expect(result.metadata['consecutiveRisingDays'], 2);
    });

    test('연속 상승만 있고 이전 하락이 없으면 recovering을 감지하지 않는다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 5.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now,
          averageScore: 7.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNull);
    });

    test('하락 후 상승이 아닌 다른 패턴이면 recovering을 감지하지 않는다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 7.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 5.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now,
          averageScore: 4.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      // 하락 후 계속 하락 → declining 감지
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.declining);
    });
  });

  group('EmotionTrendService - Declining 감지', () {
    test('3일 연속 하락이면 declining을 감지한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now,
          averageScore: 4.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.declining);
      expect(result.metadata['type'], 'consecutiveDecline');
      expect(result.metadata['startScore'], 8.0);
      expect(result.metadata['currentScore'], 4.0);
      expect(result.metadata['consecutiveDecliningDays'], 3);
    });

    test('최근 7일 평균이 이전 7일 대비 2점 이상 하락하면 declining을 감지한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        // 이전 7일 (14-8일 전): 평균 8.0
        DailyEmotion(
          date: now.subtract(const Duration(days: 13)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 11)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 9)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        // 최근 7일: 평균 5.5
        DailyEmotion(
          date: now.subtract(const Duration(days: 6)),
          averageScore: 5.5,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 4)),
          averageScore: 5.5,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 5.5,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 5.5,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.declining);
      expect(result.metadata['type'], 'averageDrop');
      expect(result.metadata['recentAverage'], closeTo(5.5, 0.01));
      expect(result.metadata['previousAverage'], closeTo(8.0, 0.01));
      expect(result.metadata['dropAmount'], closeTo(2.5, 0.01));
    });

    test('2일 연속 하락은 declining을 감지하지 않는다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now,
          averageScore: 6.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNull);
    });

    test('평균 하락이 1.9점이면 declining을 감지하지 않는다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        // 이전 7일 (14일전~8일전): 평균 8.0
        DailyEmotion(
          date: now.subtract(const Duration(days: 13)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 11)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 9)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        // 최근 7일: 평균 6.1 (하락폭 1.9)
        DailyEmotion(
          date: now.subtract(const Duration(days: 6)),
          averageScore: 6.1,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 4)),
          averageScore: 6.1,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 6.1,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 6.1,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      // 하락폭 1.9 < 2.0이므로 declining이 아님
      expect(result, isNull);
    });
  });

  group('EmotionTrendService - 우선순위 검증', () {
    test('gap이 있으면 steady보다 우선한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        // 최근 7일 내 데이터들 (steady 조건 충족: 평균 8.0, 3개 이상)
        DailyEmotion(
          date: now.subtract(const Duration(days: 6)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 5)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 4)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        // 마지막 기록이 4일 전 (gap 조건 충족)
        DailyEmotion(
          date: now.subtract(const Duration(days: 4)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.gap);
    });

    test('steady가 있으면 recovering보다 우선한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        // Steady 조건: 최근 7일 평균 >= 7.0, 3개 이상
        // 단조증가로 recovering 패턴 회피
        DailyEmotion(
          date: now.subtract(const Duration(days: 6)),
          averageScore: 7.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 4)),
          averageScore: 7.5,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      // 평균 = (7.0 + 7.5 + 8.0) / 3 = 7.5 >= 7.0
      // 단조증가이므로 recovering 패턴 없음 (하락 후 상승이 아님)
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.steady);
    });

    test('recovering이 있으면 declining보다 우선한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        // 하락 후 상승 (recovering)
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 5.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now,
          averageScore: 6.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      // 첫 3개 데이터로는 declining (8.0 > 5.0) 조건도 있지만
      // 마지막이 상승 → recovering 우선
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.recovering);
    });

    test('모든 트렌드 조건을 만족하지 않으면 null을 반환한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 6.2,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now,
          averageScore: 6.1,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      // Gap X (최근), Steady X (평균 6.1 < 7.0), Recovering X, Declining X
      expect(result, isNull);
    });
  });

  group('EmotionTrendService - resetForTesting', () {
    test('resetForTesting은 nowOverride를 초기화한다', () {
      // Arrange
      final testTime = DateTime(2026, 1, 1);
      EmotionTrendService.nowOverride = () => testTime;

      // Act
      EmotionTrendService.resetForTesting();

      // Assert
      // nowOverride가 null이면 DateTime.now()를 사용 (정확히 검증 불가이지만 null 체크)
      expect(EmotionTrendService.nowOverride, isNull);
    });

    test('resetForTesting 후 nowOverride를 재설정할 수 있다', () {
      // Arrange
      final firstTime = DateTime(2026, 1, 1);
      EmotionTrendService.nowOverride = () => firstTime;
      EmotionTrendService.resetForTesting();

      final secondTime = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => secondTime;

      final entries = [
        DailyEmotion(
          date: secondTime.subtract(const Duration(days: 5)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.gap);
      expect(result.metadata['daysSinceLastEntry'], 5);
    });
  });

  group('EmotionTrendService - 정렬 독립성', () {
    test('입력 데이터가 최신순으로 정렬되어도 올바르게 분석한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      // 최신순 (내림차순)
      final entries = [
        DailyEmotion(
          date: now,
          averageScore: 4.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.declining);
      expect(result.metadata['consecutiveDecliningDays'], 3);
    });

    test('입력 데이터가 무작위 순서여도 올바르게 분석한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      // 무작위 순서
      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now,
          averageScore: 4.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.declining);
    });
  });

  group('EmotionTrendService - 경계값 테스트', () {
    test('정확히 7.0 평균이면 steady를 감지한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        DailyEmotion(
          date: now.subtract(const Duration(days: 6)),
          averageScore: 7.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 4)),
          averageScore: 7.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 7.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.steady);
      expect(result.metadata['averageScore'], 7.0);
    });

    test('정확히 2.0 하락이면 declining을 감지한다', () {
      // Arrange
      final now = DateTime(2026, 2, 6);
      EmotionTrendService.nowOverride = () => now;

      final entries = [
        // 이전 7일 (14일전~8일전): 평균 8.0
        DailyEmotion(
          date: now.subtract(const Duration(days: 13)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 11)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 9)),
          averageScore: 8.0,
          diaryCount: 1,
        ),
        // 최근 7일: 평균 6.0 (3개 이상, 마지막 엔트리 최근이어야 gap 회피)
        DailyEmotion(
          date: now.subtract(const Duration(days: 6)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 4)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 2)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
        DailyEmotion(
          date: now.subtract(const Duration(days: 1)),
          averageScore: 6.0,
          diaryCount: 1,
        ),
      ];

      // Act
      final result = EmotionTrendService.analyzeTrend(entries);

      // Assert
      expect(result, isNotNull);
      expect(result!.trend, EmotionTrend.declining);
      expect(result.metadata['dropAmount'], closeTo(2.0, 0.01));
    });
  });

  group('EmotionTrendService - EmotionTrendResult equality', () {
    test('동일한 trend와 metadata를 가진 결과는 같다', () {
      // Arrange
      const result1 = EmotionTrendResult(
        trend: EmotionTrend.gap,
        metadata: {'daysSinceLastEntry': 5},
      );
      const result2 = EmotionTrendResult(
        trend: EmotionTrend.gap,
        metadata: {'daysSinceLastEntry': 5},
      );

      // Act & Assert
      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('다른 trend를 가진 결과는 다르다', () {
      // Arrange
      const result1 = EmotionTrendResult(
        trend: EmotionTrend.gap,
        metadata: {},
      );
      const result2 = EmotionTrendResult(
        trend: EmotionTrend.steady,
        metadata: {},
      );

      // Act & Assert
      expect(result1, isNot(equals(result2)));
    });

    test('다른 metadata를 가진 결과는 다르다', () {
      // Arrange
      const result1 = EmotionTrendResult(
        trend: EmotionTrend.gap,
        metadata: {'daysSinceLastEntry': 5},
      );
      const result2 = EmotionTrendResult(
        trend: EmotionTrend.gap,
        metadata: {'daysSinceLastEntry': 7},
      );

      // Act & Assert
      expect(result1, isNot(equals(result2)));
    });
  });
}
