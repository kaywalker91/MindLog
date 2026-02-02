import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 키워드 랭킹 행 위젯
class KeywordRankRow extends StatelessWidget {
  final String keyword;
  final int frequency;
  final int rank;
  final int totalCount;
  final int maxCount;

  const KeywordRankRow({
    super.key,
    required this.keyword,
    required this.frequency,
    required this.rank,
    required this.totalCount,
    required this.maxCount,
  });

  int get _percent {
    if (totalCount == 0) return 0;
    return ((frequency / totalCount) * 100).round();
  }

  double get _fillFactor {
    if (maxCount == 0) return 0;
    return (frequency / maxCount).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statsCardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.statsCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RankBadge(rank: rank),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  keyword,
                  style: const TextStyle(
                    color: AppColors.statsTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$frequency회',
                style: const TextStyle(
                  color: AppColors.statsTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: AppColors.statsPrimary.withValues(alpha: 0.12),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _fillFactor,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.statsPrimary.withValues(alpha: 0.6),
                          AppColors.statsPrimaryDark,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '키워드 등장 비율 $_percent%',
            style: const TextStyle(
              color: AppColors.statsTextTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.statsPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: AppColors.statsPrimaryDark,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
