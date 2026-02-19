import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/statistics_theme_tokens.dart';
import '../../../domain/entities/statistics.dart';
import '../../providers/providers.dart';
import '../emotion_calendar.dart';

/// 히트맵 카드 (기간 필터 + 감정 달력 포함)
class StatisticsHeatmapCard extends ConsumerWidget {
  const StatisticsHeatmapCard({
    super.key,
    required this.statistics,
    required this.selectedPeriod,
  });

  final EmotionStatistics statistics;
  final StatisticsPeriod selectedPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final statsTokens = StatisticsThemeTokens.of(context);
    final isDark = colorScheme.brightness == Brightness.dark;
    final streak = _calculateStreak(statistics.activityMap);
    final recordedDays = statistics.activityMap.length;
    final totalDays = _getPeriodDayCount(statistics, selectedPeriod);
    final completionRate = totalDays > 0
        ? ((recordedDays / totalDays) * 100).round()
        : 0;
    final hasRecords = recordedDays > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statsTokens.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statsTokens.cardBorder),
        boxShadow: [
          BoxShadow(
            color: statsTokens.cardShadow.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '마음 달력',
            style: TextStyle(
              color: statsTokens.textPrimary,
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
            style: TextStyle(
              color: statsTokens.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          if (hasRecords) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ProudBadge(
                  label: '기록 $recordedDays일',
                  emoji: '🗓️',
                  backgroundColor: statsTokens.primarySoft,
                  textColor: statsTokens.primaryStrong,
                  borderColor: statsTokens.cardBorder,
                ),
                if (totalDays > 0)
                  _ProudBadge(
                    label: '기록률 $completionRate%',
                    emoji: '✨',
                    backgroundColor: statsTokens.mintAccent.withValues(
                      alpha: 0.16,
                    ),
                    textColor: statsTokens.textPrimary,
                    borderColor: statsTokens.mintAccent.withValues(alpha: 0.45),
                  ),
                if (streak > 0)
                  _ProudBadge(
                    label: '$streak일 연속',
                    emoji: '🔥',
                    backgroundColor: statsTokens.coralAccent.withValues(
                      alpha: 0.16,
                    ),
                    textColor: statsTokens.textPrimary,
                    borderColor: statsTokens.coralAccent.withValues(
                      alpha: 0.55,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: _PeriodChips(selectedPeriod: selectedPeriod),
          ),
          const SizedBox(height: 16),
          EmotionCalendar(
            activityMap: statistics.activityMap,
            showLegend: true,
          ),
        ],
      ),
    );
  }

  int _calculateStreak(Map<DateTime, double> activityMap) {
    int streak = 0;
    final DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

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
    if (days != null) return days;
    if (statistics.activityMap.isEmpty) return 0;

    final today = DateTime.now();
    final earliest = statistics.activityMap.keys.reduce(
      (a, b) => a.isBefore(b) ? a : b,
    );
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedStart = DateTime(
      earliest.year,
      earliest.month,
      earliest.day,
    );
    return normalizedToday.difference(normalizedStart).inDays + 1;
  }

  String _getPeriodLabel(StatisticsPeriod period) {
    if (period == StatisticsPeriod.all) return '전체 기간';
    return period.displayName;
  }
}

class _PeriodChips extends ConsumerWidget {
  const _PeriodChips({required this.selectedPeriod});

  final StatisticsPeriod selectedPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsTokens = StatisticsThemeTokens.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animationDuration = reduceMotion
        ? Duration.zero
        : Duration(milliseconds: statsTokens.microMotionMs);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: StatisticsPeriod.values.map((period) {
        final isSelected = period == selectedPeriod;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: GestureDetector(
            onTap: () {
              ref.read(selectedStatisticsPeriodProvider.notifier).state =
                  period;
            },
            child: AnimatedContainer(
              duration: animationDuration,
              constraints: const BoxConstraints(minHeight: 38),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? statsTokens.chipSelectedBackground
                    : statsTokens.chipUnselectedBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? statsTokens.chipSelectedBackground
                      : statsTokens.cardBorder,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: statsTokens.primaryStrong.withValues(
                            alpha: 0.24,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                period.displayName,
                style: TextStyle(
                  color: isSelected
                      ? statsTokens.chipSelectedForeground
                      : statsTokens.chipUnselectedForeground,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProudBadge extends StatelessWidget {
  const _ProudBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    this.emoji,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 12)),
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
}
