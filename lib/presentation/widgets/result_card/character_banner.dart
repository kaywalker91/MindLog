import 'package:flutter/material.dart';
import '../../../core/constants/ai_character.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// AI 캐릭터 배너 위젯
class CharacterBanner extends StatelessWidget {
  final AiCharacter character;

  const CharacterBanner({
    super.key,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.statsPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statsPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              character.imagePath,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 44,
                  height: 44,
                  color: Theme.of(context).colorScheme.surface,
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.statsPrimaryDark,
                    size: 20,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 캐릭터',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.statsPrimaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  character.displayName,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.statsTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  character.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.statsTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
