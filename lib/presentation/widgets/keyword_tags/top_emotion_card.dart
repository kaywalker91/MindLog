import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.statsPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statsCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.statsPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.statsPrimaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '대표 감정',
                  style: TextStyle(
                    color: AppColors.statsTextTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  keyword,
                  style: const TextStyle(
                    color: AppColors.statsTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '키워드 등장 $frequency회',
                  style: const TextStyle(
                    color: AppColors.statsTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.statsPrimaryDark,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$_percent%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
