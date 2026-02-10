import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// 감정 점수 기반 Cheer Me 유도 카드
///
/// 일기 분석 결과 하단에 표시되어, 감정 점수에 따른
/// 맞춤 프롬프트로 자기 응원 메시지 작성을 유도합니다.
class EmotionLinkedPromptCard extends StatelessWidget {
  final int sentimentScore;

  const EmotionLinkedPromptCard({
    super.key,
    required this.sentimentScore,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = _getPrompt();

    return InkWell(
      onTap: () => context.push('/settings/self-encouragement'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.cheerMeAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: const Border(
            left: BorderSide(color: AppColors.cheerMeAccent, width: 4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: AppColors.cheerMeAccent,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    prompt.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prompt.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  _PromptData _getPrompt() {
    if (sentimentScore <= 3) {
      return const _PromptData(
        title: '힘든 날, 나에게 따뜻한 한마디를 써보세요',
        subtitle: '자기 응원 메시지가 힘이 될 거예요',
      );
    }
    if (sentimentScore <= 6) {
      return const _PromptData(
        title: '오늘의 감정을 응원 메시지로 남겨보세요',
        subtitle: '나만의 응원이 내일의 힘이 돼요',
      );
    }
    return const _PromptData(
      title: '이 좋은 기분을 응원 메시지로 간직해보세요',
      subtitle: '긍정의 에너지를 매일 전달받아요',
    );
  }
}

/// 감정 범위별 프롬프트 텍스트 데이터
class _PromptData {
  final String title;
  final String subtitle;

  const _PromptData({
    required this.title,
    required this.subtitle,
  });
}
