import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/statistics.dart';
import '../emotion_line_chart.dart';

/// 감정 추이 차트 카드
class StatisticsChartCard extends StatelessWidget {
  const StatisticsChartCard({
    super.key,
    required this.statistics,
    required this.selectedPeriod,
  });

  final EmotionStatistics statistics;
  final StatisticsPeriod selectedPeriod;

  @override
  Widget build(BuildContext context) {
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
}
