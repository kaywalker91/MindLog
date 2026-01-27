import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/services/analytics_service.dart';
import '../../domain/entities/statistics.dart';
import '../providers/providers.dart';
import '../widgets/emotion_line_chart.dart';
import '../widgets/keyword_tags.dart';
import '../widgets/emotion_calendar.dart';
import '../widgets/mindlog_app_bar.dart';

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
              // 하단 시스템 바를 고려한 패딩
              bottom: ResponsiveUtils.bottomSafeAreaPadding(context, extra: 32),
            ),
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
                _buildKeywordCard(context, statistics, selectedPeriod),
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
            style: const TextStyle(
              color: AppColors.statsPrimaryDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${statistics.totalDiaries}개의 일기',
            style: const TextStyle(
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
          const Text(
            '🔥',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 2),
          Text(
            '$streak일',
            style: const TextStyle(
              color: AppColors.statsAccentCoral,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
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
            style: const TextStyle(
              color: AppColors.statsTextSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
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
    final recordedDays = statistics.activityMap.length;
    final totalDays = _getPeriodDayCount(statistics, selectedPeriod);
    final completionRate =
        totalDays > 0 ? ((recordedDays / totalDays) * 100).round() : 0;
    final hasRecords = recordedDays > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statsCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.statsCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.statsPrimary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '마음 달력',
            style: TextStyle(
              color: AppColors.statsTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasRecords
                ? '✨ ${_getPeriodLabel(selectedPeriod)} 동안 $recordedDays일 기록했어요 · '
                    '${statistics.totalDiaries}편의 일기'
                : '아직 기록이 없어요. 오늘의 마음을 남겨볼까요?',
            style: const TextStyle(
              color: AppColors.statsTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          if (hasRecords) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildProudBadge(
                  label: '기록 $recordedDays일',
                  emoji: '🗓️',
                  backgroundColor:
                      AppColors.statsPrimary.withValues(alpha: 0.15),
                  textColor: AppColors.statsPrimaryDark,
                ),
                if (totalDays > 0)
                  _buildProudBadge(
                    label: '기록률 $completionRate%',
                    emoji: '✨',
                    backgroundColor:
                        AppColors.statsAccentMint.withValues(alpha: 0.2),
                    textColor: AppColors.statsPrimaryDark,
                  ),
                if (streak > 0)
                  _buildProudBadge(
                    label: '$streak일 연속',
                    emoji: '🔥',
                    backgroundColor:
                        AppColors.statsAccentCoral.withValues(alpha: 0.15),
                    textColor: AppColors.statsAccentCoral,
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: _buildPeriodChips(context, ref, selectedPeriod),
          ),
          const SizedBox(height: 16),

          // 감정 달력
          EmotionCalendar(
            activityMap: statistics.activityMap,
            showLegend: true,
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
              constraints: const BoxConstraints(minHeight: 38),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.statsPrimary
                    : AppColors.statsPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.statsPrimaryDark
                      : AppColors.statsCardBorder,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              AppColors.statsPrimary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                period.displayName,
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

  Widget _buildProudBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    String? emoji,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(
              emoji,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
          const Text(
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
            style: const TextStyle(
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
  Widget _buildKeywordCard(
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
          const Text(
            '자주 느낀 감정',
            style: TextStyle(
              color: AppColors.statsTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${selectedPeriod.displayName} 감정 패턴 요약',
            style: const TextStyle(
              color: AppColors.statsTextTertiary,
              fontSize: 12,
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
    final DateTime today = DateTime.now();
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

  int _getPeriodDayCount(
    EmotionStatistics statistics,
    StatisticsPeriod period,
  ) {
    final days = period.days;
    if (days != null) {
      return days;
    }

    if (statistics.activityMap.isEmpty) {
      return 0;
    }

    final today = DateTime.now();
    final earliest = _getEarliestActivityDate(statistics.activityMap);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedStart =
        DateTime(earliest.year, earliest.month, earliest.day);
    return normalizedToday.difference(normalizedStart).inDays + 1;
  }

  DateTime _getEarliestActivityDate(Map<DateTime, double> activityMap) {
    return activityMap.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  String _getPeriodLabel(StatisticsPeriod period) {
    if (period == StatisticsPeriod.all) {
      return '전체 기간';
    }
    return period.displayName;
  }

  String _getEmojiForScore(double score) {
    if (score <= 2) return '😭';
    if (score <= 4) return '😢';
    if (score <= 6) return '🙂';
    if (score <= 8) return '😊';
    return '🥰';
  }
}
