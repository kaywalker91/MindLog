import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/services/analytics_service.dart';
import '../../domain/entities/statistics.dart';
import '../providers/providers.dart';
import '../widgets/mindlog_app_bar.dart';
import '../widgets/statistics/statistics.dart';

/// 감정 통계 화면 (레이아웃 B: 요약+잔디 우선형)
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    final period = ref.read(selectedStatisticsPeriodProvider);
    unawaited(AnalyticsService.logStatisticsViewed(period: period.name));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StatisticsPeriod>(
      selectedStatisticsPeriodProvider,
      (previous, next) {
        if (previous != next) {
          unawaited(AnalyticsService.logStatisticsViewed(period: next.name));
        }
      },
    );

    final statisticsAsync = ref.watch(statisticsProvider);
    final selectedPeriod = ref.watch(selectedStatisticsPeriodProvider);

    return Scaffold(
      backgroundColor: AppColors.statsBackground,
      appBar: const MindlogAppBar(
        title: Text('감정 통계'),
      ),
      body: statisticsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.statsPrimary,
          ),
        ),
        error: (error, stack) => _buildErrorState(context, ref),
        data: (statistics) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(statisticsProvider);
          },
          color: AppColors.statsPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: ResponsiveUtils.bottomSafeAreaPadding(context, extra: 32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [A] 요약 + 스트릭 Row
                StatisticsSummaryRow(statistics: statistics),
                const SizedBox(height: 16),

                // [B] 히트맵 카드 (기간 필터 포함)
                StatisticsHeatmapCard(
                  statistics: statistics,
                  selectedPeriod: selectedPeriod,
                ),
                const SizedBox(height: 16),

                // [C] 감정 추이 차트
                StatisticsChartCard(
                  statistics: statistics,
                  selectedPeriod: selectedPeriod,
                ),
                const SizedBox(height: 16),

                // [D] 자주 느낀 감정
                StatisticsKeywordCard(
                  statistics: statistics,
                  selectedPeriod: selectedPeriod,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text(
            '통계를 불러올 수 없어요',
            style: TextStyle(
              color: AppColors.statsTextPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => ref.refresh(statisticsProvider),
            icon: const Icon(Icons.refresh, color: AppColors.statsPrimary),
            label: const Text(
              '다시 시도',
              style: TextStyle(color: AppColors.statsPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
