import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/diary.dart';
import '../../extensions/emotion_emoji_extension.dart';

/// 분석 결과 전체 내용을 보여주는 바텀 시트
///
/// 감정 범주, 원인, 공감 메시지 등을 축약 없이 전체 표시합니다.
/// [AiCharacterSheet] 패턴을 따라 DraggableScrollableSheet를 사용합니다.
class AnalysisDetailSheet extends StatelessWidget {
  final AnalysisResult result;

  const AnalysisDetailSheet({super.key, required this.result});

  /// 바텀 시트 표시 유틸리티 메서드
  static Future<void> show(BuildContext context, AnalysisResult result) {
    final theme = Theme.of(context);

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: AnalysisDetailSheet(
            result: result,
          )._buildContent(context, scrollController),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 드래그 핸들
        _buildDragHandle(theme),

        // 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '분석 결과 상세',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
              ),
            ],
          ),
        ),

        const Divider(height: 24),

        // 스크롤 가능한 콘텐츠
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              // 감정 범주
              if (result.emotionCategory != null) ...[
                _buildSectionTitle('감정 분류', Icons.psychology_outlined),
                const SizedBox(height: 12),
                _buildEmotionCategorySection(theme),
                const SizedBox(height: 24),
              ],

              // 감정 원인
              if (result.emotionTrigger != null) ...[
                _buildSectionTitle('감정 원인', Icons.lightbulb_outline),
                const SizedBox(height: 12),
                _buildEmotionTriggerSection(theme),
                const SizedBox(height: 24),
              ],

              // 공감 메시지
              _buildSectionTitle('공감 메시지', Icons.favorite_outline),
              const SizedBox(height: 12),
              _buildEmpathySection(theme),

              // 인지 패턴 (있는 경우)
              if (result.cognitivePattern != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('인지 패턴', Icons.psychology_alt_outlined),
                const SizedBox(height: 12),
                _buildCognitivePatternSection(theme),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    return Container(
      width: 44,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.subtitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionCategorySection(ThemeData theme) {
    final category = result.emotionCategory!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statsPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statsPrimary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Text(category.primaryEmoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1차 감정',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.statsTextSecondary,
                  ),
                ),
                Text(
                  category.primary,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.statsTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '2차 감정',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.statsTextSecondary,
                  ),
                ),
                Text(
                  category.secondary,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.statsTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionTriggerSection(ThemeData theme) {
    final trigger = result.emotionTrigger!;

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
          Row(
            children: [
              Text(trigger.categoryEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trigger.category,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            trigger.description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.statsTextPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpathySection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: AppColors.primary.withValues(alpha: 0.5),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            result.empathyMessage,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.8,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCognitivePatternSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.cognitivePattern!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 직접 빌드는 지원하지 않음 - show() 메서드를 사용
    return const SizedBox.shrink();
  }
}
