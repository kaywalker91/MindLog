import 'package:flutter/material.dart';
import '../../../core/theme/statistics_theme_tokens.dart';

/// 키워드 요약 칩 위젯
class SummaryChips extends StatelessWidget {
  final int totalCount;
  final int uniqueCount;

  const SummaryChips({
    super.key,
    required this.totalCount,
    required this.uniqueCount,
  });

  @override
  Widget build(BuildContext context) {
    final statsTokens = StatisticsThemeTokens.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _SummaryChip(
          icon: Icons.auto_awesome,
          label: '키워드 등장 $totalCount회',
          backgroundColor: statsTokens.primarySoft,
          foregroundColor: statsTokens.primaryStrong,
        ),
        _SummaryChip(
          icon: Icons.category_outlined,
          label: '키워드 종류 $uniqueCount개',
          backgroundColor: statsTokens.mintAccent.withValues(alpha: 0.2),
          foregroundColor: statsTokens.textPrimary,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
