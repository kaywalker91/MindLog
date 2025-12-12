import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 키워드 태그 위젯
class KeywordTags extends StatelessWidget {
  final Map<String, int> keywordFrequency;
  final int maxTags;

  const KeywordTags({
    super.key,
    required this.keywordFrequency,
    this.maxTags = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (keywordFrequency.isEmpty) {
      return _buildEmptyState(context);
    }

    // 빈도순 정렬 및 상위 N개 선택
    final sortedKeywords = keywordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topKeywords = sortedKeywords.take(maxTags).toList();

    // 최대 빈도 계산 (태그 크기 결정용)
    final maxFrequency =
        topKeywords.isEmpty ? 1 : topKeywords.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자주 느낀 감정',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '일기에서 자주 등장한 감정 키워드예요',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topKeywords.asMap().entries.map((entry) {
              final index = entry.key;
              final keyword = entry.value.key;
              final frequency = entry.value.value;

              // 빈도에 따른 스케일 (0.8 ~ 1.2)
              final scale = 0.8 + (frequency / maxFrequency) * 0.4;

              return _buildTag(
                context,
                keyword,
                frequency,
                scale,
                index,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
    BuildContext context,
    String keyword,
    int frequency,
    double scale,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 빈도에 따른 색상 결정
    final color = _getTagColor(frequency, colorScheme);

    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              keyword,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                frequency.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
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
        .scale(begin: const Offset(0.8, 0.8), duration: 300.ms);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자주 느낀 감정',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.tag,
                  size: 48,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  '아직 키워드가 없어요',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '일기를 작성하면 감정 키워드가 추출돼요',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getTagColor(int frequency, ColorScheme colorScheme) {
    // 빈도에 따른 색상 팔레트
    if (frequency >= 10) return colorScheme.primary;
    if (frequency >= 5) return colorScheme.secondary;
    if (frequency >= 3) return colorScheme.tertiary;
    return colorScheme.outline;
  }
}
