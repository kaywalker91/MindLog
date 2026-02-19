import 'package:flutter/material.dart';
import '../../../core/theme/statistics_theme_tokens.dart';
import '../../../domain/entities/statistics.dart';

/// 통계 화면 상단의 요약 + 스트릭 Row
class StatisticsSummaryRow extends StatelessWidget {
  const StatisticsSummaryRow({super.key, required this.statistics});

  final EmotionStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final streak = _calculateStreak(statistics.activityMap);

    return Row(
      children: [
        Expanded(child: _SummaryCard(statistics: statistics)),
        const SizedBox(width: 12),
        Expanded(child: _StreakCard(streak: streak)),
      ],
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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.statistics});

  final EmotionStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statsTokens = StatisticsThemeTokens.of(context);
    final isDark = colorScheme.brightness == Brightness.dark;

    if (!statistics.hasData) {
      return const _EmptyCard(
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
        color: statsTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statsTokens.cardBorder),
        boxShadow: [
          BoxShadow(
            color: statsTokens.cardShadow.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 2),
          Text(
            '평균 ${statistics.overallAverageScore.toStringAsFixed(1)}점',
            style: TextStyle(
              color: statsTokens.primaryStrong,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${statistics.totalDiaries}개의 일기',
            style: TextStyle(
              color: statsTokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getEmojiForScore(double score) {
    if (score <= 2) return '😭';
    if (score <= 4) return '😢';
    if (score <= 6) return '🙂';
    if (score <= 8) return '😊';
    return '🥰';
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final statsTokens = StatisticsThemeTokens.of(context);
    final streakColor = statsTokens.coralAccent;

    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statsTokens.cardSoftBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statsTokens.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 2),
          Text(
            '$streak일',
            style: TextStyle(
              color: streakColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '연속 작성!',
            style: TextStyle(
              color: statsTokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final statsTokens = StatisticsThemeTokens.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statsTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statsTokens.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: statsTokens.textSecondary),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: statsTokens.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: statsTokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
