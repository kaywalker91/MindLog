import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';

/// 모든 일기 삭제 확인 다이얼로그
class DeleteAllDiariesDialog extends ConsumerWidget {
  const DeleteAllDiariesDialog({super.key});

  /// 다이얼로그를 표시하는 유틸리티 메서드
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const DeleteAllDiariesDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          const SizedBox(width: 8),
          const Text('모든 일기 삭제'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Text(
          '정말로 모든 일기를 삭제하시겠습니까?\n\n'
          '이 작업은 되돌릴 수 없으며, 모든 감정 분석 기록도 함께 삭제됩니다.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () async {
            context.pop();
            await _deleteAllDiaries(context, ref);
          },
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
          ),
          child: const Text('삭제'),
        ),
      ],
    );
  }

  Future<void> _deleteAllDiaries(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(diaryRepositoryProvider);
      await repository.deleteAllDiaries();

      // 목록 새로고침
      await ref.read(diaryListControllerProvider.notifier).refresh();
      // 통계 새로고침
      ref.invalidate(statisticsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 일기가 삭제되었습니다.')),
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
