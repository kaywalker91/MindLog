import 'package:flutter/material.dart';
import '../../../core/theme/statistics_theme_tokens.dart';
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
    final statsTokens = StatisticsThemeTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statsTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statsTokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자주 느낀 감정',
            style: TextStyle(
              color: statsTokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${selectedPeriod.displayName} 감정 패턴 요약',
            style: TextStyle(
              color: statsTokens.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
