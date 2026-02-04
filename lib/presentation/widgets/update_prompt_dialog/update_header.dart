import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 업데이트 다이얼로그 헤더 위젯
class UpdateHeader extends StatelessWidget {
  final bool isRequired;

  const UpdateHeader({super.key, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = isRequired
        ? const LinearGradient(
            colors: [AppColors.warning, AppColors.error],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [AppColors.statsPrimary, AppColors.statsSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: gradient),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isRequired
                  ? Icons.warning_amber_rounded
                  : Icons.system_update_alt_rounded,
              color: theme.colorScheme.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '업데이트',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isRequired)
                      _buildChip(
                        theme,
                        '필수',
                        backgroundColor: theme.colorScheme.onPrimary.withValues(
                          alpha: 0.22,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isRequired ? '최신 버전으로 업데이트가 필요해요.' : '새 버전이 준비되었어요.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    ThemeData theme,
    String text, {
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
