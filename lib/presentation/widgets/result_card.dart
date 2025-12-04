import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/diary.dart';

/// 분석 결과 카드
class ResultCard extends StatefulWidget {
  final Diary diary;
  final VoidCallback onNewDiary;

  const ResultCard({
    super.key,
    required this.diary,
    required this.onNewDiary,
  });

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  bool _isActionCompleted = false;

  AnalysisResult get result => widget.diary.analysisResult!;

  @override
  void initState() {
    super.initState();
    _isActionCompleted = result.isActionCompleted;
  }

  void _toggleAction() {
    setState(() {
      _isActionCompleted = !_isActionCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 감정 온도계
        _buildSentimentGauge()
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: -0.2, end: 0),
        const SizedBox(height: 24),

        // 감정 키워드
        _buildKeywords()
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideX(begin: -0.1, end: 0),
        const SizedBox(height: 24),

        // 위로의 말
        _buildEmpathyMessage()
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms),
        const SizedBox(height: 24),

        // 추천 액션
        _buildActionItem()
            .animate()
            .fadeIn(delay: 600.ms, duration: 500.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 32),

        // 새 일기 작성 버튼
        OutlinedButton(
          onPressed: widget.onNewDiary,
          child: const Text('새로운 마음 적기'),
        ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildSentimentGauge() {
    final color = AppColors.getSentimentColor(result.sentimentScore);
    final percentage = result.sentimentScore / 10;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.sentimentLabel,
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 16,
                      backgroundColor: color.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${result.sentimentScore}점',
                    style: AppTextStyles.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywords() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.keywordsLabel,
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.keywords.map((keyword) {
                return Chip(
                  label: Text(keyword),
                  labelStyle: AppTextStyles.keyword,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpathyMessage() {
    return Card(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 20,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.empathyLabel,
                  style: AppTextStyles.label,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              result.empathyMessage,
              style: AppTextStyles.empathyMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem() {
    return Card(
      child: InkWell(
        onTap: _toggleAction,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 체크박스
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _isActionCompleted
                      ? AppColors.success
                      : Colors.transparent,
                  border: Border.all(
                    color: _isActionCompleted
                        ? AppColors.success
                        : AppColors.textHint,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isActionCompleted
                    ? const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      ).animate().scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 200.ms,
                        )
                    : null,
              ),
              const SizedBox(width: 16),

              // 액션 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.actionLabel,
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.actionItem,
                      style: AppTextStyles.body.copyWith(
                        decoration: _isActionCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: _isActionCompleted
                            ? AppColors.textHint
                            : AppColors.textPrimary,
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
}
