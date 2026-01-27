import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/domain/entities/statistics.dart';
import 'package:mindlog/core/di/infra_providers.dart';
import 'package:mindlog/presentation/providers/ui_state_providers.dart';

/// 통계 화면 전용 상태 Provider
/// Note: selectedStatisticsPeriodProvider는 ui_state_providers.dart에서 관리

/// 통계 데이터 Provider
final statisticsProvider =
    FutureProvider.autoDispose<EmotionStatistics>((ref) async {
  final useCase = ref.watch(getStatisticsUseCaseProvider);
  final period = ref.watch(selectedStatisticsPeriodProvider);
  return await useCase.execute(period);
});

/// 상위 키워드 Provider (상위 10개)
final topKeywordsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final useCase = ref.watch(getStatisticsUseCaseProvider);
  return await useCase.getKeywordFrequency(limit: 10);
});
