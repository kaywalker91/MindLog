import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/diary.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 감정 분석 결과 카드 위젯
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

  @override
  void initState() {
    super.initState();
    _isActionCompleted = widget.diary.analysisResult?.isActionCompleted ?? false;
  }

  void _onActionCheck(bool? checked) {
    setState(() {
      _isActionCompleted = checked ?? false;
    });
    
    if (_isActionCompleted) {
      _showSuccessMessage();
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 작은 성공! 오늘 하루도 잘 해냈어요!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getSentimentColor() {
    final score = widget.diary.analysisResult?.sentimentScore ?? 5;
    
    if (score <= 3) {
      return Colors.red.shade300; // 매우 부정
    } else if (score <= 5) {
      return Colors.orange.shade300; // 부정
    } else if (score <= 7) {
      return Colors.yellow.shade700; // 중간
    } else if (score <= 8) {
      return Colors.lightGreen.shade400; // 긍정
    } else {
      return Colors.green.shade400; // 매우 긍정
    }
  }

  String _getSentimentEmoji() {
    final score = widget.diary.analysisResult?.sentimentScore ?? 5;
    
    if (score <= 3) return '😢';
    if (score <= 5) return '😔';
    if (score <= 7) return '😐';
    if (score <= 8) return '🙂';
    return '😊';
  }

  String _getSentimentText() {
    final score = widget.diary.analysisResult?.sentimentScore ?? 5;
    
    if (score <= 3) return '많이 힘드셨네요';
    if (score <= 5) return '좀 힘드셨군요';
    if (score <= 7) return '보통이셨네요';
    if (score <= 8) return '좋은 하루셨네요';
    return '아주 좋은 하루셨네요';
  }

  @override
  Widget build(BuildContext context) {
    final analysisResult = widget.diary.analysisResult;
    if (analysisResult == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 감정 온도계
        _buildSentimentMeter(),
        const SizedBox(height: 24),

        // 키워드
        _buildKeywords(analysisResult.keywords),
        const SizedBox(height: 24),

        // 공감 메시지
        _buildEmpathyMessage(analysisResult.empathyMessage),
        const SizedBox(height: 24),

        // 추천 행동
        _buildActionItem(analysisResult.actionItem),
        const SizedBox(height: 32),

        // 새 일기 작성 버튼
        _buildNewDiaryButton(),
      ],
    ).animate(delay: const Duration(milliseconds: 100)).slideY(
      begin: 0.3,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  Widget _buildSentimentMeter() {
    final score = widget.diary.analysisResult?.sentimentScore ?? 5;
    final color = _getSentimentColor();
    final emoji = _getSentimentEmoji();
    final text = _getSentimentText();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: AppTextStyles.subtitle.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '감정 지수: $score/10',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
        
            // 게이지 바
            Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey.shade200,
              ),
              child: FractionallySizedBox(
                widthFactor: score / 10,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywords(List<String> keywords) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘의 감정 키워드',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: keywords.map((keyword) {
                return Chip(
                  label: Text(keyword),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpathyMessage(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '마음의 응원',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(
                  height: 1.5,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 400))
                .slideX(
                  begin: -0.1,
                  duration: const Duration(milliseconds: 800),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(String actionItem) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '추천하는 작은 행동',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _isActionCompleted,
                    onChanged: _onActionCheck,
                    activeColor: Colors.amber.shade600,
                  ),
                  Expanded(
                    child: Text(
                      actionItem,
                      style: AppTextStyles.body.copyWith(
                        decoration: _isActionCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: _isActionCompleted
                            ? Colors.grey
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewDiaryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onNewDiary,
        icon: const Icon(Icons.edit),
        label: const Text('새 일기 작성하기'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
