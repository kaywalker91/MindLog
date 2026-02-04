import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/diary.dart';
import '../../extensions/emotion_emoji_extension.dart';
import '../common/expandable_text.dart';

/// 감정 인사이트 카드 (감정 범주 + 유발 요인)
class EmotionInsightCard extends StatelessWidget {
  final AnalysisResult result;

  /// 탭 시 전체 분석 내용을 보여주는 시트를 열기 위한 콜백
  final VoidCallback? onTapExpand;

  const EmotionInsightCard({super.key, required this.result, this.onTapExpand});

  @override
  Widget build(BuildContext context) {
    if (result.emotionCategory == null && result.emotionTrigger == null) {
      return const SizedBox.shrink();
    }

    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statsPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statsPrimary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 감정 범주
          if (result.emotionCategory != null) ...[
            Row(
              children: [
                Text(
                  result.emotionCategory!.primaryEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '감정 분류',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.statsTextSecondary,
                        ),
                      ),
                      Text(
                        '${result.emotionCategory!.primary} → ${result.emotionCategory!.secondary}',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.statsTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // 감정 유발 요인
          if (result.emotionTrigger != null) ...[
            if (result.emotionCategory != null) const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  result.emotionTrigger!.categoryEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '감정 원인 · ${result.emotionTrigger!.category}',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.statsTextSecondary,
                        ),
                      ),
                      ExpandableText(
                        text: result.emotionTrigger!.description,
                        collapsedMaxLines: 3,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.statsTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    // onTapExpand 콜백이 있으면 GestureDetector로 래핑
    final widget = onTapExpand != null
        ? GestureDetector(
            onTap: onTapExpand,
            behavior: HitTestBehavior.opaque,
            child: content,
          )
        : content;

    return widget
        .animate()
        .fadeIn(delay: 100.ms, duration: 500.ms)
        .slideX(begin: 0.1);
  }
}
