import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/diary.dart';
import '../providers/diary_list_controller.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.delete_outline, color: colorScheme.error),
          const SizedBox(width: 8),
          const Text('일기 삭제'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Text(
          '이 일기를 삭제하시겠습니까?\n\n'
          '삭제된 일기는 복구할 수 없습니다.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
            await _deleteDiary(context, ref);
          },
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
          ),
          child: const Text('삭제'),
        ),
      ],
    );
  }

  Future<void> _deleteDiary(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(diaryRepositoryProvider);
      await repository.deleteDiary(diary.id);

      // 목록 새로고침
      await ref.read(diaryListControllerProvider.notifier).refresh();
      // 통계 새로고침
      ref.invalidate(statisticsProvider);

      if (context.mounted) {
        // 상세 화면에서 호출된 경우 목록으로 복귀
        if (popAfterDelete) {
          Navigator.of(context).pop();
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
