import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
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
    if (checked == true && !_isActionCompleted) {
      // 체크하는 순간 축하 효과
      setState(() {
        _isActionCompleted = true;
      });
      _showSuccessMessage();
    } else if (checked == false) {
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
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('작은 성공을 축하해요! 🎉'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getSentimentColor() {
    final score = widget.diary.analysisResult?.sentimentScore ?? 5;
    return AppColors.getSentimentColor(score);
  }

  String _getSentimentEmoji() {
    final score = widget.diary.analysisResult?.sentimentScore ?? 5;
    if (score <= 2) return '😭';
    if (score <= 4) return '😢';
    if (score <= 6) return '🙂';
    if (score <= 8) return '😊';
    return '🥰';
  }

  String _getSentimentText() {
    final score = widget.diary.analysisResult?.sentimentScore ?? 5;
    if (score <= 2) return '마음이 많이 아프시군요';
    if (score <= 4) return '조금 지치신 것 같아요';
    if (score <= 6) return '평범한 하루였네요';
    if (score <= 8) return '기분 좋은 하루였군요!';
    return '정말 행복한 하루였네요!';
  }

  @override
  Widget build(BuildContext context) {
    final analysisResult = widget.diary.analysisResult;
    if (analysisResult == null) return const SizedBox.shrink();

    // 응급 상황 처리
    if (analysisResult.isEmergency) {
      return _buildSOSCard(analysisResult);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. 감정 대시보드 (온도계 + 이모지)
        _buildSentimentDashboard(),
        const SizedBox(height: 24),

        // 2. 키워드 칩
        _buildKeywords(analysisResult.keywords),
        const SizedBox(height: 24),

        // 3. 공감 메시지 (인용구 스타일)
        _buildEmpathyMessage(analysisResult.empathyMessage),
        const SizedBox(height: 24),

        // 4. 추천 행동 (티켓 스타일)
        _buildActionItem(analysisResult.actionItem),
        const SizedBox(height: 40),

        // 5. 버튼
        _buildNewDiaryButton(),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, curve: Curves.easeOutQuint);
  }

  Widget _buildSOSCard(AnalysisResult result) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 56, color: Colors.red)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1000.ms),
          const SizedBox(height: 20),
          Text(
            '전문가의 도움이 필요할 수 있어요',
            style: AppTextStyles.headline.copyWith(color: Colors.red.shade800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '혼자서 너무 힘들어하지 마세요.\n당신의 이야기를 들어줄 전문가가 기다리고 있습니다.',
            style: AppTextStyles.body.copyWith(height: 1.5, color: Colors.red.shade900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildEmergencyButton('24시간 자살예방상담전화', '1393', Icons.phone_in_talk),
          const SizedBox(height: 12),
          _buildEmergencyButton('정신건강상담전화', '1577-0199', Icons.support_agent),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(String label, String number, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () async {
        final Uri launchUri = Uri(scheme: 'tel', path: number);
        if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSentimentDashboard() {
    final score = widget.diary.analysisResult?.sentimentScore ?? 5;
    final color = _getSentimentColor();
    final emoji = _getSentimentEmoji();
    final text = _getSentimentText();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 64),
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
            begin: const Offset(0.5, 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: AppTextStyles.subtitle.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '오늘의 마음 온도: ${score * 10}°C',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // 게이지 바
          Stack(
            children: [
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.5), color],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    ),
                  ).animate().custom(
                    duration: 1200.ms,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => SizedBox(
                      width: constraints.maxWidth * (score / 10) * value,
                      child: child,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeywords(List<String> keywords) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: keywords.map((keyword) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Text(
            '#$keyword',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2);
      }).toList(),
    );
  }

  Widget _buildEmpathyMessage(String message) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Text(
                message,
                style: AppTextStyles.body.copyWith(
                  height: 1.8,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).moveY(begin: 10);
  }

  Widget _buildActionItem(String actionItem) {
    return GestureDetector(
      onTap: () => _onActionCheck(!_isActionCompleted),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isActionCompleted 
              ? AppColors.success.withValues(alpha: 0.1) 
              : Colors.amber.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isActionCompleted 
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
                color: _isActionCompleted ? AppColors.success : Colors.white,
                border: Border.all(
                  color: _isActionCompleted ? AppColors.success : Colors.amber,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.check,
                size: 16,
                color: _isActionCompleted ? Colors.white : Colors.transparent,
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
                      color: _isActionCompleted ? AppColors.success : Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    actionItem,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: _isActionCompleted ? TextDecoration.lineThrough : null,
                      color: _isActionCompleted ? Colors.grey : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(target: _isActionCompleted ? 1 : 0).shimmer(duration: 400.ms, color: Colors.white),
    );
  }

  Widget _buildNewDiaryButton() {
    return ElevatedButton(
      onPressed: widget.onNewDiary,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
