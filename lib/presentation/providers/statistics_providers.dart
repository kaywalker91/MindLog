import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/domain/entities/statistics.dart';
import 'package:mindlog/core/di/infra_providers.dart';
import 'package:mindlog/presentation/providers/ui_state_providers.dart';

/// 통계 화면 전용 상태 Provider
/// Note: selectedStatisticsPeriodProvider는 ui_state_providers.dart에서 관리

/// 통계 데이터 Provider
///
/// autoDispose 제거: IndexedStack에서 모든 탭 화면이 동시에 빌드되므로,
/// 빠른 탭 전환 시 async 작업 완료 전에 dispose되는 문제 방지.
/// 통계 데이터 크기가 작아 메모리 영향 미미.
final statisticsProvider = FutureProvider<EmotionStatistics>((ref) async {
  final useCase = ref.watch(getStatisticsUseCaseProvider);
  final period = ref.watch(selectedStatisticsPeriodProvider);
  return await useCase.execute(period);
});

/// 상위 키워드 Provider (상위 10개)
/// statisticsProvider의 keywordFrequency를 재사용하여 기간 필터 적용
///
/// autoDispose 제거: statisticsProvider와 동일한 이유.
/// .select() 최적화: keywordFrequency만 구독하여 다른 필드 변경 시 리빌드 방지
final topKeywordsProvider = FutureProvider<Map<String, int>>((ref) async {
  // .select()로 keywordFrequency만 구독하여 리빌드 최소화
  final frequency = await ref.watch(
    statisticsProvider.selectAsync((stats) => stats.keywordFrequency),
  );

  // 상위 10개만 반환
  final sorted = frequency.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return Map.fromEntries(sorted.take(10));
});

/// 전체 일기 수 Provider
/// .select() 최적화: totalDiaries만 구독하여 다른 필드 변경 시 리빌드 방지
final totalDiariesProvider = FutureProvider<int>((ref) async {
  return ref.watch(
    statisticsProvider.selectAsync((stats) => stats.totalDiaries),
  );
});

/// 전체 평균 감정 점수 Provider
/// .select() 최적화: overallAverageScore만 구독
final overallAverageScoreProvider = FutureProvider<double>((ref) async {
  return ref.watch(
    statisticsProvider.selectAsync((stats) => stats.overallAverageScore),
  );
});

/// 활동 맵 Provider (히트맵용)
/// .select() 최적화: activityMap만 구독
final activityMapProvider = FutureProvider<Map<DateTime, double>>((ref) async {
  return ref.watch(
    statisticsProvider.selectAsync((stats) => stats.activityMap),
  );
});
