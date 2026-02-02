import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import 'keyword_rank_row.dart';
import 'summary_chips.dart';
import 'top_emotion_card.dart';

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
      return const _EmptyState();
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
        SummaryChips(
          totalCount: totalCount,
          uniqueCount: keywordFrequency.length,
        ),
        const SizedBox(height: 12),
        TopEmotionCard(
          keyword: topEntry.key,
          frequency: topEntry.value,
          totalCount: totalCount,
        )
            .animate()
            .fadeIn(duration: 250.ms)
            .scale(begin: const Offset(0.98, 0.98), duration: 250.ms),
        if (remainingKeywords.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
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
                child: KeywordRankRow(
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.tag,
              size: 40,
              color: AppColors.statsTextTertiary,
            ),
            SizedBox(height: 12),
            Text(
              '감정 패턴이 아직 없어요',
              style: TextStyle(
                color: AppColors.statsTextSecondary,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
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
