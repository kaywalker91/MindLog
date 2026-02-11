import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/diary.dart';
import '../../extensions/emotion_emoji_extension.dart';

/// 감정 인사이트 카드 (감정 범주 + 유발 요인)
///
/// 감정 분류와 유발 요인을 표시하는 정보 카드입니다.
class EmotionInsightCard extends StatelessWidget {
  final AnalysisResult result;

  const EmotionInsightCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.emotionCategory == null && result.emotionTrigger == null) {
      return const SizedBox.shrink();
    }

    return Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 4),
                      Text(
                        result.emotionTrigger!.description,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.statsTextPrimary,
                          height: 1.5,
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
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.05);
  }
}
