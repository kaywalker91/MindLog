import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/accessibility/app_accessibility.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/animation_settings.dart';
import '../../core/utils/responsive_utils.dart';
import '../../domain/entities/diary.dart';
import '../providers/providers.dart';
import '../router/app_router.dart';
import '../widgets/diary_list/diary_item_card.dart';
import '../widgets/diary_list/write_fab.dart';
import '../widgets/home/home_header_title.dart';
import '../widgets/mindlog_app_bar.dart';

/// 일기 목록 화면 (메인)
class DiaryListScreen extends ConsumerStatefulWidget {
  const DiaryListScreen({super.key});

  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    unawaited(AnalyticsService.logScreenView('diary_list'));

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isInitialLoad = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final diaryListState = ref.watch(diaryListControllerProvider);

    return AccessibilityWrapper(
      screenTitle: '일기 목록',
      child: Scaffold(
        appBar: const MindlogAppBar(
          title: HomeHeaderTitle(),
          centerTitle: false,
          leading: SizedBox.shrink(),
          leadingWidth: 16,
          actions: [_SecretDiaryEntryButton()],
        ),
        body: diaryListState.when(
          data: (diaries) => _buildList(diaries),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(ref),
        ),
        floatingActionButton: WriteFab(onPressed: () => context.goNewDiary()),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '잠시 문제가 생겼어요',
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '일기를 불러오는 중 문제가 발생했어요',
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                ref.read(diaryListControllerProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도해볼게요'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Diary> diaries) {
    if (diaries.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      onRefresh: () async {
        setState(() => _isInitialLoad = true);
        await ref.read(diaryListControllerProvider.notifier).refresh();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _isInitialLoad = false);
        });
      },
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: ResponsiveUtils.bottomSafeAreaPadding(context, extra: 80),
        ),
        itemCount: diaries.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final diary = diaries[index];
          final shouldAnimate = AnimationSettings.shouldAnimate(context);

          Widget item = RepaintBoundary(
            child: KeyedSubtree(
              key: ValueKey(diary.id),
              child: _buildSwipeableDiaryItem(diary),
            ),
          );

          if (_isInitialLoad && shouldAnimate && index < 10) {
            final delay = (index * 50).ms;
            item = item
                .animate()
                .fadeIn(delay: delay, duration: 300.ms)
                .slideX(
                  begin: 0.08,
                  delay: delay,
                  duration: 300.ms,
                  curve: Curves.easeOut,
                );
          }

          return item;
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '일기 없음, 새 일기 작성 버튼을 눌러 시작하세요',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.book_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '아직 작성된 일기가 없어요',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '첫 일기를 기록해볼까요?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeableDiaryItem(Diary diary) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('dismissible_${diary.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: colorScheme.onError, size: 28),
      ),
      onDismissed: (_) {
        final controller = ref.read(diaryListControllerProvider.notifier);
        controller.softDelete(diary);

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('일기가 삭제되었습니다'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: '되돌리기',
                onPressed: () => controller.cancelDelete(diary.id),
              ),
            ),
          );
      },
      child: DiaryItemCard(diary: diary),
    );
  }
}

/// AppBar 비밀일기 진입 버튼
///
/// - PIN 미설정: 잠금 아이콘 → PIN 설정 화면
/// - PIN 설정됨: 잠금 아이콘 → 잠금 해제 화면
class _SecretDiaryEntryButton extends ConsumerWidget {
  const _SecretDiaryEntryButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPinAsync = ref.watch(hasPinProvider);

    return hasPinAsync.when(
      data: (hasPin) => IconButton(
        icon: Icon(
          hasPin ? Icons.lock_outline : Icons.lock_open_outlined,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        tooltip: hasPin ? '비밀일기' : '비밀일기 설정',
        onPressed: () {
          if (hasPin) {
            context.pushSecretDiaryUnlock();
          } else {
            context.pushSecretPinSetup();
          }
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
