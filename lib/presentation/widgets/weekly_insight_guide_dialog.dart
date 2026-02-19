import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum WeeklyInsightGuideResult { later, viewStats }

/// 주간 감정 인사이트 첫 활성화 시 표시되는 안내 다이얼로그
class WeeklyInsightGuideDialog extends StatelessWidget {
  const WeeklyInsightGuideDialog({super.key});

  static Future<WeeklyInsightGuideResult?> show(BuildContext context) {
    return showDialog<WeeklyInsightGuideResult>(
      context: context,
      builder: (context) => const WeeklyInsightGuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mindcareOnAccent =
        ThemeData.estimateBrightnessForColor(AppColors.mindcareAccent) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;

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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 22,
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
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.mindcareAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.insights_outlined,
                        size: 36,
                        color: AppColors.mindcareAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '주간 감정 리포트 받기',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.2,
                        fontSize: 20,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '한 주의 감정 흐름을 한눈에 정리해드려요',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.mindcareAccent,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    _buildSummaryCard(context),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      icon: Icons.schedule_outlined,
                      text: '매주 일요일 밤 8시, 요약 알림이 도착해요',
                    ),
                    const SizedBox(height: 14),
                    _buildInfoRow(
                      context,
                      icon: Icons.analytics_outlined,
                      text: '최근 7일 평균 감정·연속 기록·핵심 키워드를 확인해요',
                    ),
                    const SizedBox(height: 14),
                    _buildInfoRow(
                      context,
                      icon: Icons.open_in_new_rounded,
                      text: '알림을 탭하면 통계 탭으로 바로 이동해요',
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop(WeeklyInsightGuideResult.later);
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              '나중에',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop(WeeklyInsightGuideResult.viewStats);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.mindcareAccent,
                              foregroundColor: mindcareOnAccent,
                              minimumSize: const Size.fromHeight(52),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              '통계 보기',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.mindcareAccent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 주 인사이트 한눈에',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(context, label: '언제', value: '매주 일요일 밤 8시'),
          const SizedBox(height: 6),
          _buildSummaryRow(context, label: '무엇', value: '최근 7일 감정 흐름 요약'),
          const SizedBox(height: 6),
          _buildSummaryRow(context, label: '어디서', value: '통계 탭에서 바로 확인'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label  ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
