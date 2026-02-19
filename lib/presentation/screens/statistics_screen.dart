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
    final colorScheme = Theme.of(context).colorScheme;
    ref.listen<StatisticsPeriod>(selectedStatisticsPeriodProvider, (
      previous,
      next,
    ) {
      if (previous != next) {
        unawaited(AnalyticsService.logStatisticsViewed(period: next.name));
      }
    });

    final statisticsAsync = ref.watch(statisticsProvider);
    final selectedPeriod = ref.watch(selectedStatisticsPeriodProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: const MindlogAppBar(
        title: Text('감정 통계'),
        leading: SizedBox.shrink(),
      ),
      body: statisticsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.statsPrimary),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statsPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: AppColors.statsPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '잠시 연결이 어려워요',
              style: TextStyle(
                color: AppColors.statsTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '인터넷 연결을 확인해주세요',
              style: TextStyle(
                color: AppColors.statsTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => ref.refresh(statisticsProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도해볼게요'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statsPrimary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
