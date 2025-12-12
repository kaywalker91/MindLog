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
    final topKeywords = sortedKeywords.take(maxTags).toList();

    // 최대 빈도 계산 (태그 크기 결정용)
    final maxFrequency = topKeywords.isEmpty ? 1 : topKeywords.first.value;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: topKeywords.asMap().entries.map((entry) {
        final index = entry.key;
        final keyword = entry.value.key;
        final frequency = entry.value.value;

        // 빈도에 따른 스케일 (1.0 ~ 1.1, 1위만 약간 크게)
        final scale = index == 0 ? 1.1 : 1.0;

        return _buildTag(
          context,
          keyword,
          frequency,
          scale,
          index,
          maxFrequency,
        );
      }).toList(),
    );
  }

  Widget _buildTag(
    BuildContext context,
    String keyword,
    int frequency,
    double scale,
    int index,
    int maxFrequency,
  ) {
    // 빈도에 따른 색상 강도 결정 (1위가 가장 진함)
    final intensity = frequency / maxFrequency;
    final baseColor = AppColors.statsPrimary;
    final darkColor = AppColors.statsPrimaryDark;

    // 1위는 더 진한 색상, 나머지는 기본 하늘색
    final tagColor = index == 0 ? darkColor : baseColor;

    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tagColor.withValues(alpha: 0.1 + intensity * 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: tagColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              keyword,
              style: TextStyle(
                color: AppColors.statsPrimaryDark,
                fontSize: 14,
                fontWeight: index == 0 ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$frequency회',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), duration: 300.ms);
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
              '아직 키워드가 없어요',
              style: TextStyle(
                color: AppColors.statsTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '일기를 작성하면 감정 키워드가 추출돼요',
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
