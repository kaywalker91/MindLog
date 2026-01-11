import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/animation_settings.dart';
import '../../core/utils/responsive_utils.dart';
import '../../domain/entities/diary.dart';
import '../providers/diary_list_controller.dart';
import '../widgets/delete_diary_dialog.dart';
import '../widgets/mindlog_app_bar.dart';
import 'diary_screen.dart';
import 'diary_detail_screen.dart';

/// 일기 목록 화면 (메인)
class DiaryListScreen extends ConsumerStatefulWidget {
  const DiaryListScreen({super.key});

  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  // DateFormat 인스턴스 재사용 (생성 비용 최적화)
  static final DateFormat _dateFormatter = DateFormat('MM월 dd일 (E)', 'ko_KR');

  // 초기 로드 플래그 (stagger 애니메이션 제어)
  bool _isInitialLoad = true;
  // FAB 탭 상태
  bool _isFabPressed = false;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    // Future.microtask(() => ref.read(diaryListControllerProvider.notifier).refresh());
    unawaited(AnalyticsService.logScreenView('diary_list'));

    // 초기 애니메이션 후 플래그 리셋
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
      appBar: MindlogAppBar(
        title: const Text(AppStrings.appName),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 설정 화면 이동
            },
          ),
        ],
      ),
      body: diaryListState.when(
        data: (diaries) => _buildList(diaries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류 발생: $error')),
      ),
      floatingActionButton: _buildWriteFab(
        context,
        onPressed: () async {
          // 일기 작성 화면으로 이동
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DiaryScreen()),
          );
        // 작성 후 돌아오면 목록 새로고침
        await ref.read(diaryListControllerProvider.notifier).refresh();
        },
      ),
    );
  }

  Widget _buildWriteFab(
    BuildContext context, {
    required VoidCallback onPressed,
  }) {
    const borderRadius = BorderRadius.all(Radius.circular(28));

    return Tooltip(
      message: '오늘 기록하기',
      child: Semantics(
        button: true,
        label: '오늘 기록하기',
        child: GestureDetector(
          onTapDown: (_) {
            HapticFeedback.mediumImpact();
            setState(() => _isFabPressed = true);
          },
          onTapUp: (_) {
            setState(() => _isFabPressed = false);
            onPressed();
          },
          onTapCancel: () => setState(() => _isFabPressed = false),
          child: AnimatedScale(
            scale: _isFabPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.statsPrimary.withValues(
                      alpha: _isFabPressed ? 0.2 : 0.35,
                    ),
                    blurRadius: _isFabPressed ? 4 : 12,
                    offset: Offset(0, _isFabPressed ? 2 : 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: borderRadius,
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.statsPrimary,
                        AppColors.statsSecondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: AppColors.statsPrimaryDark.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_note_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '오늘 기록하기',
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
            const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '작성된 일기가 없습니다.\n오늘의 마음을 기록해보세요!',
              style: AppTextStyles.body.copyWith(color: Colors.grey),
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
        // 새로고침 후 애니메이션 재생
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _isInitialLoad = false);
        });
      },
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          // FAB와 시스템 바를 고려한 하단 패딩
          bottom: ResponsiveUtils.bottomSafeAreaPadding(context, extra: 80),
        ),
        itemCount: diaries.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final diary = diaries[index];
          final shouldAnimate = AnimationSettings.shouldAnimate(context);

          // 초기 로드 시 stagger 애니메이션 적용
          Widget item = KeyedSubtree(
            key: ValueKey(diary.id),
            child: _buildSwipeableDiaryItem(diary),
          );

          if (_isInitialLoad && shouldAnimate && index < 10) {
            final delay = (index * 50).ms;
            item = item
                .animate()
                .fadeIn(delay: delay, duration: 300.ms)
                .slideX(begin: 0.08, delay: delay, duration: 300.ms, curve: Curves.easeOut);
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
          color: const Color(0xFFFF5252).withValues(alpha: 0.9), // 부드러운 빨간색
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await DeleteDiaryDialog.show(
          context,
          diary: diary,
          popAfterDelete: false,
        );
      },
      child: _buildDiaryItem(diary),
    );
  }

  Widget _buildDiaryItem(Diary diary) {
    // 감정 점수에 따른 이모지 및 색상
    String emoji = '📝';
    Color color = Colors.grey.shade100;
    
    if (diary.status == DiaryStatus.analyzed && diary.analysisResult != null) {
      final score = diary.analysisResult!.sentimentScore;
      if (score <= 2) {
        emoji = '😭';
        color = Colors.red.withValues(alpha: 0.1);
      } else if (score <= 4) {
        emoji = '😢';
        color = Colors.orange.withValues(alpha: 0.1);
      } else if (score <= 6) {
        emoji = '🙂';
        color = Colors.yellow.withValues(alpha: 0.1);
      } else if (score <= 8) {
        emoji = '😊';
        color = Colors.green.withValues(alpha: 0.1);
      } else {
        emoji = '🥰';
        color = Colors.blue.withValues(alpha: 0.1);
      }
    }

    return _TappableCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DiaryDetailScreen(diary: diary),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 날짜 및 감정 아이콘
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // 내용 요약
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dateFormatter.format(diary.createdAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          diary.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body,
                        ),
                        if (diary.analysisResult?.keywords.isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            children: diary.analysisResult!.keywords.take(2).map((k) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#$k',
                                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 핀 아이콘을 위해 cheveron 제거하거나 위치 조정 필요할 수 있음. 
                  // 현재 디자인에서는 핀이 상단에 뜨므로, cheveron은 유지.
                  const SizedBox(width: 32), // 핀 아이콘 공간 확보
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(
                  diary.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: diary.isPinned ? AppColors.statsPrimary : Colors.grey.shade300,
                  size: 20,
                ),
                onPressed: () {
                  ref.read(diaryListControllerProvider.notifier)
                     .togglePin(diary.id, !diary.isPinned);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 탭 피드백이 있는 카드 위젯
class _TappableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TappableCard({
    required this.child,
    required this.onTap,
  });

  @override
  State<_TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<_TappableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _isPressed ? 0.02 : 0.05,
                ),
                blurRadius: _isPressed ? 4 : 10,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
