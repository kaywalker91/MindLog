import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/accessibility/app_accessibility.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/animation_settings.dart';

/// 감정 점수별 차별화된 이모지 애니메이션 설정
class EmotionAnimationConfig {
  final Duration scaleDuration;
  final Curve scaleCurve;
  final double scaleBegin;
  final bool hasShake;
  final bool hasRotation;
  final double shakeRotation;
  final Duration secondaryDuration;

  const EmotionAnimationConfig({
    required this.scaleDuration,
    required this.scaleCurve,
    required this.scaleBegin,
    this.hasShake = false,
    this.hasRotation = false,
    this.shakeRotation = 0,
    this.secondaryDuration = Duration.zero,
  });

  factory EmotionAnimationConfig.forScore(int score) {
    if (score <= 4) {
      // 낮은 감정: 느린 등장 + 미세한 떨림
      return const EmotionAnimationConfig(
        scaleDuration: Duration(milliseconds: 800),
        scaleCurve: Curves.easeOutCubic,
        scaleBegin: 0.7,
        hasShake: true,
        shakeRotation: 0.02,
        secondaryDuration: Duration(milliseconds: 600),
      );
    } else if (score >= 8) {
      // 높은 감정: 빠른 등장 + 회전 + 바운스
      return const EmotionAnimationConfig(
        scaleDuration: Duration(milliseconds: 400),
        scaleCurve: Curves.easeOutBack,
        scaleBegin: 0.5,
        hasRotation: true,
        secondaryDuration: Duration(milliseconds: 300),
      );
    } else {
      // 중립: 부드러운 등장
      return const EmotionAnimationConfig(
        scaleDuration: Duration(milliseconds: 600),
        scaleCurve: Curves.easeOutQuint,
        scaleBegin: 0.8,
      );
    }
  }
}

/// 감정 대시보드 위젯 (온도계 + 이모지 + 에너지 레벨)
class SentimentDashboard extends StatelessWidget {
  final int score;
  final int? energyLevel;
  final VoidCallback? onEmojiTap;

  const SentimentDashboard({
    super.key,
    required this.score,
    this.energyLevel,
    this.onEmojiTap,
  });

  Color get _sentimentColor => AppColors.getSentimentColor(score);

  String get _sentimentEmoji {
    if (score <= 2) return '😭';
    if (score <= 4) return '😢';
    if (score <= 6) return '🙂';
    if (score <= 8) return '😊';
    return '🥰';
  }

  String get _sentimentText {
    if (score <= 2) return '마음이 많이 아프시군요';
    if (score <= 4) return '조금 지치신 것 같아요';
    if (score <= 6) return '평범한 하루였네요';
    if (score <= 8) return '기분 좋은 하루였군요!';
    return '정말 행복한 하루였네요!';
  }

  @override
  Widget build(BuildContext context) {
    final color = _sentimentColor;
    final emoji = _sentimentEmoji;
    final text = _sentimentText;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          _buildAnimatedEmoji(context, emoji, score),
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
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _buildGaugeBar(context, color),
          if (energyLevel != null) ...[
            const SizedBox(height: 16),
            _buildEnergyLevel(energyLevel!),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedEmoji(BuildContext context, String emoji, int score) {
    final shouldAnimate = AnimationSettings.shouldAnimate(context);
    final config = EmotionAnimationConfig.forScore(score);

    final emojiWidget = Text(emoji, style: const TextStyle(fontSize: 64));

    if (!shouldAnimate) {
      return Semantics(
        label: AppAccessibility.emotionScoreLabel(score),
        child: emojiWidget,
      );
    }

    Widget animatedEmoji;

    if (config.hasShake) {
      animatedEmoji = emojiWidget
          .animate()
          .scale(
            duration: config.scaleDuration,
            curve: config.scaleCurve,
            begin: Offset(config.scaleBegin, config.scaleBegin),
          )
          .then(delay: 200.ms)
          .shake(
            hz: 2,
            rotation: config.shakeRotation,
            duration: config.secondaryDuration,
          );
    } else if (config.hasRotation) {
      animatedEmoji = emojiWidget
          .animate()
          .scale(
            duration: config.scaleDuration,
            curve: config.scaleCurve,
            begin: Offset(config.scaleBegin, config.scaleBegin),
          )
          .rotate(
            begin: -0.08,
            end: 0.04,
            duration: config.secondaryDuration,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            begin: const Offset(1.08, 1.08),
            end: const Offset(1.0, 1.0),
            duration: 200.ms,
            curve: Curves.easeOut,
          );
    } else {
      animatedEmoji = emojiWidget.animate().scale(
        duration: config.scaleDuration,
        curve: config.scaleCurve,
        begin: Offset(config.scaleBegin, config.scaleBegin),
      );
    }

    return Semantics(
      label: '감정 점수 $score점, $_sentimentText',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onEmojiTap?.call();
        },
        child: animatedEmoji,
      ),
    );
  }

  Widget _buildGaugeBar(BuildContext context, Color color) {
    final shouldAnimate = AnimationSettings.shouldAnimate(context);

    return Stack(
      children: [
        Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final gaugeBar = Container(
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
                  ),
                ],
              ),
            );

            if (!shouldAnimate) {
              return SizedBox(
                width: constraints.maxWidth * (score / 10),
                child: gaugeBar,
              );
            }

            return gaugeBar
                .animate()
                .custom(
                  duration: 1200.ms,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => SizedBox(
                    width: constraints.maxWidth * (score / 10) * value,
                    child: child,
                  ),
                )
                .then(delay: 200.ms)
                .shimmer(
                  duration: 1500.ms,
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.35),
                );
          },
        ),
      ],
    );
  }

  Widget _buildEnergyLevel(int level) {
    final emoji = level <= 3 ? '🔋' : (level <= 6 ? '⚡' : '💪');
    final label = level <= 3 ? '에너지 부족' : (level <= 6 ? '보통' : '활력 넘침');
    final color = level <= 3
        ? AppColors.warning
        : (level <= 6 ? AppColors.statsPrimary : AppColors.success);

    return Semantics(
      label: '에너지 레벨 $level점 중 10점, $label',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            '에너지 레벨: $level/10 ($label)',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
