import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/statistics.dart';
import '../keyword_tags.dart';

/// 자주 느낀 감정 키워드 카드
class StatisticsKeywordCard extends StatelessWidget {
  const StatisticsKeywordCard({
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
}
