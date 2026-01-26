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
      return _buildSingleActionItem(actions.first);
    }

    // 다단계 행동인 경우 새 스타일 사용
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                '오늘의 마음 챙김 미션',
                style: AppTextStyles.subtitle.copyWith(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return _buildSteppedActionItem(action, index);
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildSingleActionItem(String actionItem) {
    return GestureDetector(
      onTap: () => onActionCheck(!isActionCompleted),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActionCompleted
              ? AppColors.success.withValues(alpha: 0.1)
              : Colors.amber.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActionCompleted
                ? AppColors.success
                : Colors.amber.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActionCompleted ? AppColors.success : Colors.white,
                border: Border.all(
                  color: isActionCompleted ? AppColors.success : Colors.amber,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.check,
                size: 16,
                color: isActionCompleted ? Colors.white : Colors.transparent,
              ),
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
                          : Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    actionItem,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration:
                          isActionCompleted ? TextDecoration.lineThrough : null,
                      color: isActionCompleted
                          ? Colors.grey
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(target: isActionCompleted ? 1 : 0).shimmer(
            duration: 400.ms,
            color: Colors.white,
          ),
    );
  }

  Widget _buildSteppedActionItem(String action, int index) {
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
                    color: AppColors.textPrimary,
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
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      default:
        return Colors.grey;
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
        return '';
    }
  }
}
