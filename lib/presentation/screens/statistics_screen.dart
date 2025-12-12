import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/statistics.dart';
import '../providers/providers.dart';
import '../widgets/emotion_line_chart.dart';
import '../widgets/keyword_tags.dart';
import '../widgets/activity_heatmap.dart';

/// 감정 통계 화면
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statisticsAsync = ref.watch(statisticsProvider);
    final selectedPeriod = ref.watch(selectedStatisticsPeriodProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('감정 통계'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: statisticsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '통계를 불러올 수 없어요',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.refresh(statisticsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (statistics) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(statisticsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 기간 선택 탭
                _buildPeriodSelector(context, ref, selectedPeriod),
                const SizedBox(height: 24),

                // 요약 카드
                _buildSummaryCard(context, statistics),
                const SizedBox(height: 16),

                // 감정 추이 차트
                EmotionLineChart(
                  dailyEmotions: statistics.dailyEmotions,
                  period: selectedPeriod,
                ),
                const SizedBox(height: 16),

                // 키워드 태그
                KeywordTags(
                  keywordFrequency: statistics.keywordFrequency,
                  maxTags: 10,
                ),
                const SizedBox(height: 16),

                // 활동 히트맵
                ActivityHeatmap(
                  activityMap: statistics.activityMap,
                  weeksToShow: _getWeeksForPeriod(selectedPeriod),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    WidgetRef ref,
    StatisticsPeriod selectedPeriod,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: StatisticsPeriod.values.map((period) {
          final isSelected = period == selectedPeriod;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(selectedStatisticsPeriodProvider.notifier).state =
                    period;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    period.displayName,
                    style: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, EmotionStatistics statistics) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!statistics.hasData) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                '아직 데이터가 없어요',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '일기를 작성하면 감정 통계를 볼 수 있어요',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final emoji = _getEmojiForScore(statistics.overallAverageScore);
    final message = _getMessageForScore(statistics.overallAverageScore);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '평균 ${statistics.overallAverageScore.toStringAsFixed(1)}점 · '
                  '${statistics.totalDiaries}개의 일기',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  String _getEmojiForScore(double score) {
    if (score <= 2) return '😢';
    if (score <= 4) return '😔';
    if (score <= 6) return '😐';
    if (score <= 8) return '🙂';
    return '😊';
  }

  String _getMessageForScore(double score) {
    if (score <= 2) return '많이 힘드셨군요';
    if (score <= 4) return '조금 힘든 시간을 보내고 계시네요';
    if (score <= 6) return '평온한 하루를 보내고 계시네요';
    if (score <= 8) return '좋은 시간을 보내고 계시네요';
    return '정말 행복한 하루였네요';
  }
}
