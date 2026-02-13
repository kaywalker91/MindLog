import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/self_encouragement_controller.dart';
import 'message_input_dialog.dart';

/// 메시지가 없을 때 표시되는 빈 상태 뷰
///
/// 간소화된 UI: 아이콘 + 타이틀 + 서브텍스트 + CTA 버튼만 표시
/// - 알림 미리보기: 메시지 리스트 화면으로 이동
/// - 추천 칩: 메시지 작성 다이얼로그로 이동
/// - FAB: Empty State에서는 숨김 (메시지 1개 이상일 때만 표시)
class EmptyMessageView extends ConsumerWidget {
  const EmptyMessageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 500;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 24 : 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 편지 아이콘
                    Container(
                      padding: EdgeInsets.all(isCompact ? 20 : 28),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mail_outline,
                        size: isCompact ? 56 : 72,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: isCompact ? 24 : 32),
                    // 메인 타이틀
                    Text(
                      '응원 메시지가 없습니다',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    // 서브텍스트
                    Text(
                      '나에게 힘이 되는 한마디를\n작성해보세요',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isCompact ? 32 : 48),
                    // CTA 버튼 (유일한 액션)
                    FilledButton.icon(
                      onPressed: () => _showAddDialog(context, ref),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('첫 메시지 작성하기'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await MessageInputDialog.show(context);
    if (result != null && result.isNotEmpty && context.mounted) {
      await ref.read(selfEncouragementProvider.notifier).addMessage(result);
    }
  }
}
