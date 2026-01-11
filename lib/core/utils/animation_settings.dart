import 'package:flutter/material.dart';

/// 애니메이션 설정 유틸리티 (접근성 지원)
///
/// Reduced Motion 설정을 감지하여 애니메이션 Duration을 조정합니다.
/// WCAG 2.1 AA 준수를 위해 사용자의 시스템 설정을 존중합니다.
class AnimationSettings {
  AnimationSettings._();

  /// 사용자가 모션 감소를 선호하는지 확인
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Reduced Motion 설정에 따라 Duration 조정
  static Duration adjustDuration(BuildContext context, Duration duration) {
    if (prefersReducedMotion(context)) {
      return Duration.zero;
    }
    return duration;
  }

  /// 애니메이션을 실행해야 하는지 확인
  static bool shouldAnimate(BuildContext context) {
    return !prefersReducedMotion(context);
  }

  /// 기본 애니메이션 Duration 상수 (Material Design 3 기준)
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration short = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration long = Duration(milliseconds: 800);
  static const Duration emphasis = Duration(milliseconds: 1000);
}

/// 감정 점수별 애니메이션 설정
class EmotionAnimationConfig {
  final Duration scaleDuration;
  final Duration secondaryDuration;
  final Curve scaleCurve;
  final double scaleBegin;
  final bool hasShake;
  final bool hasRotation;
  final double shakeRotation;

  const EmotionAnimationConfig({
    required this.scaleDuration,
    required this.secondaryDuration,
    required this.scaleCurve,
    required this.scaleBegin,
    this.hasShake = false,
    this.hasRotation = false,
    this.shakeRotation = 0.0,
  });

  /// 감정 점수에 따른 애니메이션 설정 반환
  static EmotionAnimationConfig forScore(int score) {
    // 매우 낮음 (1-2): 느린 등장 + 미세한 떨림 (무게감 표현)
    if (score <= 2) {
      return const EmotionAnimationConfig(
        scaleDuration: Duration(milliseconds: 1200),
        secondaryDuration: Duration(milliseconds: 800),
        scaleCurve: Curves.easeOutCubic,
        scaleBegin: 0.5,
        hasShake: true,
        shakeRotation: 0.015,
      );
    }
    // 낮음 (3-4): 느린 등장 + 약한 떨림
    if (score <= 4) {
      return const EmotionAnimationConfig(
        scaleDuration: Duration(milliseconds: 1000),
        secondaryDuration: Duration(milliseconds: 600),
        scaleCurve: Curves.easeOutCubic,
        scaleBegin: 0.55,
        hasShake: true,
        shakeRotation: 0.02,
      );
    }
    // 중립 (5-6): 부드러운 등장
    if (score <= 6) {
      return const EmotionAnimationConfig(
        scaleDuration: Duration(milliseconds: 800),
        secondaryDuration: Duration(milliseconds: 400),
        scaleCurve: Curves.easeOutQuint,
        scaleBegin: 0.6,
      );
    }
    // 높음 (7-8): 빠른 등장 + 바운스
    if (score <= 8) {
      return const EmotionAnimationConfig(
        scaleDuration: Duration(milliseconds: 600),
        secondaryDuration: Duration(milliseconds: 300),
        scaleCurve: Curves.elasticOut,
        scaleBegin: 0.45,
        hasRotation: true,
      );
    }
    // 매우 높음 (9-10): 빠른 등장 + 강한 바운스 + 회전 (활력 표현)
    return const EmotionAnimationConfig(
      scaleDuration: Duration(milliseconds: 500),
      secondaryDuration: Duration(milliseconds: 250),
      scaleCurve: Curves.elasticOut,
      scaleBegin: 0.4,
      hasRotation: true,
    );
  }
}
