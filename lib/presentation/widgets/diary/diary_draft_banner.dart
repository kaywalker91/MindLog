import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 이전에 작성하던 임시저장 일기 내용을 복원했을 때 표시되는 배너 위젯
class DiaryDraftBanner extends StatelessWidget {
  const DiaryDraftBanner({
    super.key,
    required this.savedAt,
    required this.onDelete,
    required this.onDismiss,
  });

  /// 초안이 마지막으로 저장된 시각 (상대 시간 문구로 표시)
  final DateTime savedAt;

  /// [삭제] — 초안을 폐기하고 폼을 비운다
  final VoidCallback onDelete;

  /// 닫기 — 배너만 숨기고 초안은 유지
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
            : AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: 0.35,
          ), // design-ok: 강조선 브랜드 액센트
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.restore_page_outlined,
            color: AppColors.primary, // design-ok: 아이콘 브랜드 액센트
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '이전에 작성하던 내용을 불러왔어요',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRelativeTime(savedAt),
                  style: AppTextStyles.label.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '삭제',
              style: AppTextStyles.label.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: colorScheme.onSurfaceVariant,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: '닫기',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime savedAt) {
    final now = DateTime.now();
    final difference = now.difference(savedAt);

    if (difference.inDays >= 1) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
