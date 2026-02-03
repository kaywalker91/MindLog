import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/diary.dart';
import '../providers/providers.dart';

/// 개별 일기 삭제 확인 다이얼로그
class DeleteDiaryDialog extends ConsumerWidget {
  final Diary diary;
  final bool popAfterDelete;

  const DeleteDiaryDialog({
    super.key,
    required this.diary,
    this.popAfterDelete = false,
  });

  /// 다이얼로그를 표시하는 유틸리티 메서드
  static Future<bool?> show(
    BuildContext context, {
    required Diary diary,
    bool popAfterDelete = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteDiaryDialog(
        diary: diary,
        popAfterDelete: popAfterDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아이콘
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            
            // 제목
            const Text(
              '소중한 기록을 지우시겠어요?',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // 내용
            Text(
              '삭제 후에는 되돌릴 수 없어요.\n정말로 삭제하시겠습니까?',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            
            // 버튼 영역
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => context.pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      context.pop(true);
                      await _deleteDiary(context, ref);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('삭제'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDiary(BuildContext context, WidgetRef ref) async {
    try {
      // Controller를 통해 삭제 (통계 갱신 포함)
      await ref.read(diaryListControllerProvider.notifier).deleteImmediately(diary.id);

      if (context.mounted) {
        // 상세 화면에서 호출된 경우 목록으로 복귀
        if (popAfterDelete) {
          context.pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일기가 삭제되었습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
}
