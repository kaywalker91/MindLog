import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

/// 키워드 태그 위젯 (하늘색 테마)
class KeywordTags extends StatelessWidget {
  final Map<String, int> keywordFrequency;
  final int maxTags;

  const KeywordTags({
    super.key,
    required this.keywordFrequency,
    this.maxTags = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (keywordFrequency.isEmpty) {
      return _buildEmptyState(context);
    }

    // 빈도순 정렬 및 상위 N개 선택
    final sortedKeywords = keywordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final takeCount = maxTags < 1 ? 1 : maxTags;
    final topKeywords = sortedKeywords.take(takeCount).toList();
    final totalCount =
        keywordFrequency.values.fold<int>(0, (sum, value) => sum + value);
    final maxCount = topKeywords.isEmpty ? 0 : topKeywords.first.value;
    final topEntry = topKeywords.first;
    final remainingKeywords = topKeywords.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(totalCount, keywordFrequency.length),
        const SizedBox(height: 12),
        _buildTopEmotionCard(topEntry, totalCount)
            .animate()
            .fadeIn(duration: 250.ms)
            .scale(begin: const Offset(0.98, 0.98), duration: 250.ms),
        if (remainingKeywords.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            '다음으로 많이 느낀 감정',
            style: TextStyle(
              color: AppColors.statsTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: remainingKeywords.asMap().entries.map((entry) {
              final index = entry.key;
              final keyword = entry.value.key;
              final frequency = entry.value.value;
              final rank = index + 2;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRankRow(
                  keyword: keyword,
                  frequency: frequency,
                  rank: rank,
                  totalCount: totalCount,
                  maxCount: maxCount,
                )
                    .animate(delay: Duration(milliseconds: 80 * (index + 1)))
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.1, end: 0),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(int totalCount, int uniqueCount) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildSummaryChip(
          icon: Icons.auto_awesome,
          label: '키워드 등장 $totalCount회',
          color: AppColors.statsPrimaryDark,
        ),
        _buildSummaryChip(
          icon: Icons.category_outlined,
          label: '키워드 종류 $uniqueCount개',
          color: AppColors.statsAccentMint,
        ),
      ],
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.statsTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEmotionCard(
    MapEntry<String, int> topEntry,
    int totalCount,
  ) {
    final percent = _getPercent(topEntry.value, totalCount);

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
            child: Icon(
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
                Text(
                  '대표 감정',
                  style: TextStyle(
                    color: AppColors.statsTextTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topEntry.key,
                  style: TextStyle(
                    color: AppColors.statsTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '키워드 등장 ${topEntry.value}회',
                  style: TextStyle(
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
              '$percent%',
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

  Widget _buildRankRow({
    required String keyword,
    required int frequency,
    required int rank,
    required int totalCount,
    required int maxCount,
  }) {
    final percent = _getPercent(frequency, totalCount);
    final fillFactor = maxCount == 0 ? 0 : frequency / maxCount;

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
              _buildRankBadge(rank),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  keyword,
                  style: TextStyle(
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
                style: TextStyle(
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
                  widthFactor: fillFactor.clamp(0, 1).toDouble(),
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
            '키워드 등장 비율 $percent%',
            style: TextStyle(
              color: AppColors.statsTextTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
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
          style: TextStyle(
            color: AppColors.statsPrimaryDark,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  int _getPercent(int count, int total) {
    if (total == 0) return 0;
    return ((count / total) * 100).round();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.tag,
              size: 40,
              color: AppColors.statsTextTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              '감정 패턴이 아직 없어요',
              style: TextStyle(
                color: AppColors.statsTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '분석된 일기가 쌓이면 대표 감정과 비율을 알려드려요',
              style: TextStyle(
                color: AppColors.statsTextTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
