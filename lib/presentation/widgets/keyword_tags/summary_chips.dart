import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _SummaryChip(
          icon: Icons.auto_awesome,
          label: '키워드 등장 $totalCount회',
          color: AppColors.statsPrimaryDark,
        ),
        _SummaryChip(
          icon: Icons.category_outlined,
          label: '키워드 종류 $uniqueCount개',
          color: AppColors.statsAccentMint,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(
              color: AppColors.statsTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
