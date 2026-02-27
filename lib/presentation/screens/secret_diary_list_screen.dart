import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/app_accessibility.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../../domain/entities/diary.dart';
import '../providers/providers.dart';
import '../widgets/diary_list/diary_item_card.dart';
import '../widgets/mindlog_app_bar.dart';

/// 비밀일기 목록 화면
///
/// - [secretAuthProvider] 감시: false가 되면 즉시 pop (앱 재시작 보안)
/// - [secretDiaryListProvider] 기반 리스트 (비밀 일기만 표시)
/// - AppBar 잠금 버튼 → lock() + pop
class SecretDiaryListScreen extends ConsumerWidget {
  const SecretDiaryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 인증 해제 시 즉시 pop (앱 백그라운드 복귀 등)
    ref.listen(secretAuthProvider, (_, isAuthenticated) {
      if (!isAuthenticated && context.canPop()) {
        context.pop();
      }
    });

    final secretListAsync = ref.watch(secretDiaryListProvider);

    return AccessibilityWrapper(
      screenTitle: '비밀일기',
      child: Scaffold(
        appBar: MindlogAppBar(
          title: const Text('비밀일기'),
          actions: [
            IconButton(
              icon: const Icon(Icons.lock_outline),
              tooltip: '잠금',
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(secretAuthProvider.notifier).lock();
                if (context.canPop()) context.pop();
              },
            ),
          ],
        ),
        body: secretListAsync.when(
          data: (diaries) => _buildBody(context, ref, diaries),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _buildErrorState(ref),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<Diary> diaries) {
    if (diaries.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: ResponsiveUtils.bottomSafeAreaPadding(context, extra: 32),
      ),
      itemCount: diaries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return KeyedSubtree(
          key: ValueKey(diaries[index].id),
          child: DiaryItemCard(diary: diaries[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            '비밀일기가 없습니다.\n일기 목록에서 비밀 설정을 해보세요.',
            style: AppTextStyles.body.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('목록을 불러올 수 없습니다'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(secretDiaryListProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
