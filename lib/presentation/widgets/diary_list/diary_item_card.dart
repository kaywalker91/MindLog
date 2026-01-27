import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/diary.dart';
import '../../extensions/diary_display_extension.dart';
import '../../providers/diary_list_controller.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return TappableCard(
      onTap: () => context.goDiaryDetail(diary),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
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
                  const Icon(Icons.chevron_right, color: AppColors.textHint),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: _buildPinButton(ref),
            ),
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
        child: Text(
          diary.emotionEmoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _dateFormatter.format(diary.createdAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
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
            style: AppTextStyles.body,
          ),
          if (diary.analysisResult?.keywords.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            _buildKeywordChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildKeywordChips() {
    return Wrap(
      spacing: 4,
      children: diary.analysisResult!.keywords.take(2).map((k) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.textHint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '#$k',
            style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPinButton(WidgetRef ref) {
    return IconButton(
      icon: Icon(
        diary.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        color: diary.isPinned ? AppColors.statsPrimary : AppColors.textHint,
        size: 20,
      ),
      onPressed: () {
        ref.read(diaryListControllerProvider.notifier)
           .togglePin(diary.id, !diary.isPinned);
      },
    );
  }
}
