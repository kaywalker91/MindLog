import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/animation_settings.dart';
import '../../core/utils/responsive_utils.dart';
import '../../domain/entities/diary.dart';
import '../providers/diary_list_controller.dart';
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

    return Scaffold(
      appBar: const MindlogAppBar(
        title: HomeHeaderTitle(),
        centerTitle: false,
        leading: SizedBox.shrink(),
        leadingWidth: 16,
      ),
      body: diaryListState.when(
        data: (diaries) => _buildList(diaries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(ref),
      ),
      floatingActionButton: WriteFab(onPressed: () => context.goNewDiary()),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
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
                color: AppColors.textSecondary,
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
                foregroundColor: Colors.white,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              '작성된 일기가 없습니다.\n오늘의 마음을 기록해보세요!',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
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

  Widget _buildSwipeableDiaryItem(Diary diary) {
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
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
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
