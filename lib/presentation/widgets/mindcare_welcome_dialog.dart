import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// 마음케어 첫 활성화 시 표시되는 환영 다이얼로그
///
/// Cheer Me와의 차별점을 명확히 전달하고,
/// CBT/마인드풀니스 기반 전문 케어 서비스임을 안내한다.
class MindcareWelcomeDialog extends StatelessWidget {
  const MindcareWelcomeDialog({super.key});

  /// 다이얼로그 표시
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const MindcareWelcomeDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 영역 — Calm Teal 브랜딩
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.mindcareAccent.withValues(alpha: 0.15),
                  AppColors.mindcareAccent.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mindcareAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    size: 40,
                    color: AppColors.mindcareAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '마음케어를 시작해요',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '심리학 기반 전문 마음 케어',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.mindcareAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 본문 영역
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.schedule_outlined,
                  text: '매일 저녁 9시, 하루 마무리 메시지가 도착해요',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  icon: Icons.psychology_outlined,
                  text: 'CBT, 마인드풀니스 등 검증된 심리 기법 기반',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  icon: Icons.favorite_outlined,
                  text: '감정 상태에 맞춘 맞춤 메시지를 보내드려요',
                ),
                const SizedBox(height: 16),

                // Cheer Me와 차별점 안내
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cheer Me와 무엇이 다른가요?',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildCompareRow(
                        context,
                        color: AppColors.cheerMeAccent,
                        label: 'Cheer Me',
                        desc: '내가 쓴 응원을 나에게 보내요',
                      ),
                      const SizedBox(height: 4),
                      _buildCompareRow(
                        context,
                        color: AppColors.mindcareAccent,
                        label: '마음케어',
                        desc: '전문 심리 기법으로 마음을 케어해요',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _buildSampleMessage(context),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mindcareAccent,
                    ),
                    child: const Text('시작하기'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.mindcareAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompareRow(
    BuildContext context, {
    required Color color,
    required String label,
    required String desc,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            desc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSampleMessage(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mindcareAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mindcareAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.spa_outlined,
            size: 20,
            color: AppColors.mindcareAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '"잠시 멈추고 현재를 느껴보세요.\n지금 이 순간, 있는 그대로 충분해요"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
