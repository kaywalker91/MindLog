import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/statistics.dart';
import '../providers/providers.dart';
import '../widgets/emotion_line_chart.dart';
import '../widgets/keyword_tags.dart';
import '../widgets/activity_heatmap.dart';

/// 감정 통계 화면 (레이아웃 B: 요약+잔디 우선형)
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(statisticsProvider);
    final selectedPeriod = ref.watch(selectedStatisticsPeriodProvider);

    return Scaffold(
      backgroundColor: AppColors.statsBackground,
      appBar: AppBar(
        title: const Text('감정 통계'),
      ),
      body: statisticsAsync.when(
        loading: () => Center(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [A] 요약 + 스트릭 Row
                _buildSummaryRow(context, statistics),
                const SizedBox(height: 16),

                // [B] 히트맵 카드 (기간 필터 포함)
                _buildHeatmapCard(context, ref, statistics, selectedPeriod),
                const SizedBox(height: 16),

                // [C] 감정 추이 차트
                _buildChartCard(context, statistics, selectedPeriod),
                const SizedBox(height: 16),

                // [D] 자주 느낀 감정
                _buildKeywordCard(context, statistics),
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
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            '통계를 불러올 수 없어요',
            style: TextStyle(
              color: AppColors.statsTextPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => ref.refresh(statisticsProvider),
            icon: Icon(Icons.refresh, color: AppColors.statsPrimary),
            label: Text(
              '다시 시도',
              style: TextStyle(color: AppColors.statsPrimary),
            ),
          ),
        ],
      ),
    );
  }

  /// [A] 요약 + 스트릭 Row
  Widget _buildSummaryRow(BuildContext context, EmotionStatistics statistics) {
    final streak = _calculateStreak(statistics.activityMap);

    return Row(
      children: [
        // 요약 카드 (좌측)
        Expanded(
          child: _buildSummaryCard(context, statistics),
        ),
        const SizedBox(width: 12),
        // 스트릭 카드 (우측)
        Expanded(
          child: _buildStreakCard(context, streak),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, EmotionStatistics statistics) {
    if (!statistics.hasData) {
      return _buildEmptyCard(
        context,
        icon: Icons.analytics_outlined,
        title: '데이터 없음',
        subtitle: '일기를 작성해보세요',
      );
    }

    final emoji = _getEmojiForScore(statistics.overallAverageScore);

    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.statsCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statsCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.statsPrimary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 2),
          Text(
            '평균 ${statistics.overallAverageScore.toStringAsFixed(1)}점',
            style: TextStyle(
              color: AppColors.statsPrimaryDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${statistics.totalDiaries}개의 일기',
            style: TextStyle(
              color: AppColors.statsTextSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, int streak) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.statsPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statsPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🔥',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 2),
          Text(
            '$streak일',
            style: TextStyle(
              color: AppColors.statsAccentCoral,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '연속 작성!',
            style: TextStyle(
              color: AppColors.statsTextSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statsCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statsCardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: AppColors.statsTextTertiary),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: AppColors.statsTextSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.statsTextTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// [B] 히트맵 카드 (기간 필터 포함)
  Widget _buildHeatmapCard(
    BuildContext context,
    WidgetRef ref,
    EmotionStatistics statistics,
    StatisticsPeriod selectedPeriod,
  ) {
    final streak = _calculateStreak(statistics.activityMap);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statsCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statsCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목 + 기간 필터 (Column 분리로 overflow 방지)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 첫 번째 Row: 제목 + 스트릭 배지
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '일기 작성 기록',
                      style: TextStyle(
                        color: AppColors.statsTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (streak > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statsAccentCoral.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🔥 $streak일 연속',
                        style: TextStyle(
                          color: AppColors.statsAccentCoral,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 두 번째 Row: 기간 필터 (우측 정렬)
              Align(
                alignment: Alignment.centerRight,
                child: _buildPeriodChips(context, ref, selectedPeriod),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 히트맵
          ActivityHeatmap(
            activityMap: statistics.activityMap,
            weeksToShow: _getWeeksForPeriod(selectedPeriod),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChips(
    BuildContext context,
    WidgetRef ref,
    StatisticsPeriod selectedPeriod,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: StatisticsPeriod.values.map((period) {
        final isSelected = period == selectedPeriod;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: GestureDetector(
            onTap: () {
              ref.read(selectedStatisticsPeriodProvider.notifier).state = period;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              // 최소 터치 영역 44dp 보장
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.statsPrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.statsPrimary
                      : AppColors.statsCardBorder,
                ),
              ),
              child: Text(
                _getPeriodShortName(period),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.statsTextSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// [C] 감정 추이 차트
  Widget _buildChartCard(
    BuildContext context,
    EmotionStatistics statistics,
    StatisticsPeriod selectedPeriod,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statsCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statsCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '감정 추이',
            style: TextStyle(
              color: AppColors.statsTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selectedPeriod.displayName,
            style: TextStyle(
              color: AppColors.statsTextTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          EmotionLineChart(
            dailyEmotions: statistics.dailyEmotions,
            period: selectedPeriod,
          ),
        ],
      ),
    );
  }

  /// [D] 키워드 카드
  Widget _buildKeywordCard(BuildContext context, EmotionStatistics statistics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statsCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statsCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자주 느낀 감정',
            style: TextStyle(
              color: AppColors.statsTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          KeywordTags(
            keywordFrequency: statistics.keywordFrequency,
            maxTags: 5,
          ),
        ],
      ),
    );
  }

  // ============================================
  // Helper Methods
  // ============================================

  int _calculateStreak(Map<DateTime, double> activityMap) {
    int streak = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    // 오늘 또는 어제부터 시작 (오늘 아직 안썼을 수 있으므로)
    if (!activityMap.containsKey(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (activityMap.containsKey(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _getWeeksForPeriod(StatisticsPeriod period) {
    switch (period) {
      case StatisticsPeriod.week:
        return 4;
      case StatisticsPeriod.month:
        return 8;
      case StatisticsPeriod.all:
        return 12;
    }
  }

  String _getPeriodShortName(StatisticsPeriod period) {
    switch (period) {
      case StatisticsPeriod.week:
        return '7일';
      case StatisticsPeriod.month:
        return '30일';
      case StatisticsPeriod.all:
        return '전체';
    }
  }

  String _getEmojiForScore(double score) {
    if (score <= 2) return '😢';
    if (score <= 4) return '😔';
    if (score <= 6) return '😐';
    if (score <= 8) return '🙂';
    return '😊';
  }
}
