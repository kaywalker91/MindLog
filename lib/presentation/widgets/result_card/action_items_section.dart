import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 단계별 추천 행동 섹션
class ActionItemsSection extends StatelessWidget {
  final List<String> actions;
  final bool isActionCompleted;
  final ValueChanged<bool> onActionCheck;

  const ActionItemsSection({
    super.key,
    required this.actions,
    required this.isActionCompleted,
    required this.onActionCheck,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    // 단일 행동인 경우 기존 스타일 사용
    if (actions.length == 1) {
      return _buildSingleActionItem(context, actions.first);
    }

    // 다단계 행동인 경우 새 스타일 사용
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.actionAmber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.actionAmber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.actionAmber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '오늘의 마음 챙김 미션',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.actionAmberDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return _buildSteppedActionItem(context, action, index);
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildSingleActionItem(BuildContext context, String actionItem) {
    return GestureDetector(
      onTap: () => onActionCheck(!isActionCompleted),
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isActionCompleted
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.actionAmber.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActionCompleted
                        ? AppColors.success
                        : AppColors.actionAmber.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) {
                        final colorScheme = Theme.of(context).colorScheme;
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActionCompleted
                                ? AppColors.success
                                : colorScheme.surface,
                            border: Border.all(
                              color: isActionCompleted
                                  ? AppColors.success
                                  : AppColors.actionAmber,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: isActionCompleted
                                ? colorScheme.onPrimary
                                : Colors.transparent,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '오늘의 작은 미션',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActionCompleted
                                  ? AppColors.success
                                  : AppColors.actionAmberDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            actionItem,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: isActionCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isActionCompleted
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate(target: isActionCompleted ? 1 : 0)
              .shimmer(
                duration: 400.ms,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
    );
  }

  Widget _buildSteppedActionItem(
    BuildContext context,
    String action,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // 이모지가 있다면 제거하고 남은 텍스트만 추출
    final chars = action.characters;
    final hasEmoji =
        chars.isNotEmpty && ['🚀', '☀️', '📅'].contains(chars.first);
    final textContent = hasEmoji ? chars.skip(1).toString().trim() : action;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _getStepColor(index).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: _getStepColor(index),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStepLabel(index),
                  style: TextStyle(
                    fontSize: 11,
                    color: _getStepColor(index),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  textContent,
                  style: AppTextStyles.body.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStepColor(int index) {
    switch (index) {
      case 0:
        return AppColors.actionStep1;
      case 1:
        return AppColors.actionStep2;
      case 2:
        return AppColors.actionStep3;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStepLabel(int index) {
    switch (index) {
      case 0:
        return '🚀 지금 바로';
      case 1:
        return '☀️ 오늘 중으로';
      case 2:
        return '📅 이번 주';
      default:
        return '📌 추가 미션';
    }
  }
}
