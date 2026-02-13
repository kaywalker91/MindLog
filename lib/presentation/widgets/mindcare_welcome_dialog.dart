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

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더 영역 — Calm Teal 브랜딩
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.mindcareAccent.withValues(alpha: 0.15),
                      AppColors.mindcareAccent.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '검증된 심리학 기반 마음케어',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.mindcareAccent,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              // 본문 영역
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.schedule_outlined,
                      text: '매일 밤 9시, 하루를 정리하는 메시지를 보내드려요',
                    ),
                    const SizedBox(height: 14),
                    _buildInfoRow(
                      context,
                      icon: Icons.psychology_outlined,
                      text: 'CBT·마인드풀니스 기반의 검증된 케어',
                    ),
                    const SizedBox(height: 14),
                    _buildInfoRow(
                      context,
                      icon: Icons.favorite_outlined,
                      text: '오늘의 감정에 맞는 맞춤 메시지를 전해드려요',
                    ),
                    const SizedBox(height: 18),

                    // Cheer Me와 차별점 안내
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cheer Me와 무엇이 다른가요?',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCompareRow(
                            context,
                            color: AppColors.cheerMeAccent,
                            label: 'Cheer Me',
                            desc: '내가 쓴 응원을 나에게 전해요.',
                          ),
                          const SizedBox(height: 6),
                          _buildCompareRow(
                            context,
                            color: AppColors.mindcareAccent,
                            label: '마음케어',
                            desc: '전문 심리 기법으로 마음을 돌봐요.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildSampleMessage(context),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.mindcareAccent,
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          '시작하기',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: AppColors.mindcareAccent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.45,
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
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
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
      padding: const EdgeInsets.all(18),
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
                height: 1.55,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
