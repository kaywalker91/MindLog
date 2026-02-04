import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/ai_character.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/diary.dart';
import 'result_card/result_card.dart';

/// 감정 분석 결과 카드 위젯
class ResultCard extends StatefulWidget {
  final Diary diary;
  final VoidCallback onNewDiary;

  const ResultCard({super.key, required this.diary, required this.onNewDiary});

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  bool _isActionCompleted = false;

  @override
  void initState() {
    super.initState();
    _isActionCompleted =
        widget.diary.analysisResult?.isActionCompleted ?? false;
  }

  void _onActionCheck(bool checked) {
    if (checked && !_isActionCompleted) {
      setState(() {
        _isActionCompleted = true;
      });
      final actionItem =
          widget.diary.analysisResult?.displayActionItems.firstOrNull ?? '';
      unawaited(
        AnalyticsService.logActionItemCompleted(actionItemText: actionItem),
      );
      _showSuccessMessage();
    } else if (!checked) {
      setState(() {
        _isActionCompleted = false;
      });
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 8),
            const Text('작은 성공을 축하해요! 🎉'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onEmojiTap() {
    final score = widget.diary.analysisResult?.sentimentScore ?? 5;
    final emoji = _getSentimentEmoji(score);
    final color = AppColors.getSentimentColor(score);

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('오늘의 감정 온도: ${score * 10}°C $emoji'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getSentimentEmoji(int score) {
    if (score <= 2) return '😭';
    if (score <= 4) return '😢';
    if (score <= 6) return '🙂';
    if (score <= 8) return '😊';
    return '🥰';
  }

  @override
  Widget build(BuildContext context) {
    final analysisResult = widget.diary.analysisResult;
    if (analysisResult == null) return const SizedBox.shrink();
    final character = aiCharacterFromId(analysisResult.aiCharacterId);

    // 응급 상황 처리
    if (analysisResult.isEmergency) {
      return const SOSCard();
    }

    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 0. AI 캐릭터 배지
            CharacterBanner(character: character),
            const SizedBox(height: 16),

            // 1. 감정 대시보드 (온도계 + 이모지 + 에너지 레벨)
            SentimentDashboard(
              score: analysisResult.sentimentScore,
              energyLevel: analysisResult.energyLevel,
              onEmojiTap: _onEmojiTap,
            ),
            const SizedBox(height: 24),

            // 2. 감정 범주 + 유발 요인
            if (analysisResult.emotionCategory != null ||
                analysisResult.emotionTrigger != null) ...[
              EmotionInsightCard(
                result: analysisResult,
                onTapExpand: () =>
                    AnalysisDetailSheet.show(context, analysisResult),
              ),
              const SizedBox(height: 24),
            ],

            // 3. 키워드 칩
            KeywordsSection(keywords: analysisResult.keywords),
            const SizedBox(height: 24),

            // 4. 공감 메시지 (인용구 스타일)
            EmpathyMessage(
              message: analysisResult.empathyMessage,
              onTapExpand: () =>
                  AnalysisDetailSheet.show(context, analysisResult),
            ),
            const SizedBox(height: 24),

            // 5. 단계별 추천 행동
            ActionItemsSection(
              actions: analysisResult.displayActionItems,
              isActionCompleted: _isActionCompleted,
              onActionCheck: _onActionCheck,
            ),
            const SizedBox(height: 40),

            // 6. 버튼
            _buildNewDiaryButton(),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.1, curve: Curves.easeOutQuint);
  }

  Widget _buildNewDiaryButton() {
    return ElevatedButton(
      onPressed: widget.onNewDiary,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
      ),
      child: const Text(
        '목록으로 돌아가기',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
