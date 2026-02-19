import 'package:flutter/material.dart';
import '../../../core/theme/statistics_theme_tokens.dart';

/// 대표 감정 카드 위젯
class TopEmotionCard extends StatelessWidget {
  final String keyword;
  final int frequency;
  final int totalCount;

  const TopEmotionCard({
    super.key,
    required this.keyword,
    required this.frequency,
    required this.totalCount,
  });

  int get _percent {
    if (totalCount == 0) return 0;
    return ((frequency / totalCount) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final statsTokens = StatisticsThemeTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statsTokens.cardSoftBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statsTokens.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statsTokens.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.star_rounded,
              color: statsTokens.primaryStrong,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '대표 감정',
                  style: TextStyle(
                    color: statsTokens.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  keyword,
                  style: TextStyle(
                    color: statsTokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '키워드 등장 $frequency회',
                  style: TextStyle(
                    color: statsTokens.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: statsTokens.primaryStrong,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$_percent%',
              style: TextStyle(
                color: statsTokens.chipSelectedForeground,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
