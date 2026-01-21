import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// 일기 목록에서 이미지 첨부 여부를 표시하는 컴팩트 인디케이터
///
/// 카메라 아이콘과 첨부된 이미지 개수를 표시합니다.
class DiaryImageIndicator extends StatelessWidget {
  /// 첨부된 이미지 개수
  final int count;

  const DiaryImageIndicator({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '첨부된 사진 $count장',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 12,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: AppTextStyles.label.copyWith(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
