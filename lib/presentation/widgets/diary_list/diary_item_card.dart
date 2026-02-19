import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/diary.dart';
import '../../extensions/diary_display_extension.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../common/tappable_card.dart';
import '../diary_image_indicator.dart';

/// 일기 목록 아이템 카드
class DiaryItemCard extends ConsumerWidget {
  static final DateFormat _dateFormatter = DateFormat('MM월 dd일 (E)', 'ko_KR');

  final Diary diary;

  const DiaryItemCard({super.key, required this.diary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardShadowAlpha = isDark ? 0.12 : 0.05;

    return TappableCard(
      onTap: () => context.goDiaryDetail(diary),
      onLongPress: () => _showLongPressMenu(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerLow : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.60),
                  width: 1,
                )
              : const Border.fromBorderSide(BorderSide.none),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: cardShadowAlpha),
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
                  _buildEmotionIcon(),
                  const SizedBox(width: 16),
                  _buildContent(context),
                  const SizedBox(width: 32),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
                  ),
                ],
              ),
            ),
            Positioned(top: 4, right: 4, child: _buildPinButton(context, ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: diary.emotionBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(diary.emotionEmoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _dateFormatter.format(diary.createdAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (diary.hasImages) ...[
                const SizedBox(width: 8),
                DiaryImageIndicator(count: diary.imageCount),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            diary.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: colorScheme.onSurface),
          ),
          if (diary.analysisResult?.keywords.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            _buildKeywordChips(context),
          ],
        ],
      ),
    );
  }

  Widget _buildKeywordChips(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final chipBackground = isDark
        ? colorScheme.surfaceContainerHighest
        : AppColors.textHint.withValues(alpha: 0.1);

    return Wrap(
      spacing: 4,
      children: diary.analysisResult!.keywords.take(2).map((k) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: chipBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '#$k',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPinButton(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(
        diary.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        color: diary.isPinned
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
        size: 20,
      ),
      onPressed: () {
        ref
            .read(diaryListControllerProvider.notifier)
            .togglePin(diary.id, !diary.isPinned);
      },
    );
  }

  /// 롱프레스 바텀시트 메뉴
  void _showLongPressMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 고정/고정해제 (비밀일기에서는 숨김)
            if (!diary.isSecret)
              ListTile(
                leading: Icon(
                  diary.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                title: Text(diary.isPinned ? '고정 해제' : '상단 고정'),
                onTap: () {
                  ctx.pop();
                  ref
                      .read(diaryListControllerProvider.notifier)
                      .togglePin(diary.id, !diary.isPinned);
                },
              ),
            // 비밀 설정 / 해제
            if (!diary.isSecret)
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('비밀일기로 설정'),
                onTap: () {
                  ctx.pop();
                  _setSecret(context, ref, isSecret: true);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.lock_open_outlined),
                title: const Text('비밀 해제'),
                onTap: () {
                  ctx.pop();
                  _setSecret(context, ref, isSecret: false);
                },
              ),
            // 삭제 (비밀일기는 별도 처리 없이 동일 패턴)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('삭제', style: TextStyle(color: AppColors.error)),
              onTap: () {
                ctx.pop();
                ref
                    .read(diaryListControllerProvider.notifier)
                    .softDelete(diary);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _setSecret(
    BuildContext context,
    WidgetRef ref, {
    required bool isSecret,
  }) async {
    try {
      final useCase = ref.read(setDiarySecretUseCaseProvider);
      await useCase.execute(diary.id, isSecret: isSecret);
      // 낙관적 업데이트: 일반 목록에서 즉시 제거
      ref.read(diaryListControllerProvider.notifier).removeFromList(diary.id);
      ref.invalidate(secretDiaryListProvider);
      // 비밀 해제 시: 일반 목록 갱신 (해제된 일기가 일반 목록에 다시 나타나도록)
      if (!isSecret) {
        ref.invalidate(diaryListControllerProvider);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('변경 중 오류가 발생했습니다.')));
      }
    }
  }
}
