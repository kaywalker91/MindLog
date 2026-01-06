import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:characters/characters.dart';

/// 앱 전역 접근성 설정 및 유틸리티
/// 
/// 스크린 리더 사용자를 위한 시맨틱 정보를 제공합니다.
class AppAccessibility {
  AppAccessibility._();

  /// 감정 점수에 대한 접근성 레이블 생성
  static String emotionScoreLabel(int score) {
    if (score <= 2) {
      return '감정 점수 $score점, 매우 부정적인 상태입니다';
    } else if (score <= 4) {
      return '감정 점수 $score점, 부정적인 상태입니다';
    } else if (score <= 6) {
      return '감정 점수 $score점, 보통 상태입니다';
    } else if (score <= 8) {
      return '감정 점수 $score점, 긍정적인 상태입니다';
    } else {
      return '감정 점수 $score점, 매우 긍정적인 상태입니다';
    }
  }

  /// 감정 이모지에 대한 접근성 레이블 생성
  static String emotionEmojiLabel(int score) {
    if (score <= 2) {
      return '매우 슬픔';
    } else if (score <= 4) {
      return '슬픔';
    } else if (score <= 6) {
      return '보통';
    } else if (score <= 8) {
      return '기쁨';
    } else {
      return '매우 기쁨';
    }
  }

  /// 날짜에 대한 접근성 레이블 생성
  static String dateLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '어제';
    } else if (difference < 7) {
      return '$difference일 전';
    } else {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }

  /// 일기 항목에 대한 전체 접근성 레이블 생성
  static String diaryItemLabel({
    required DateTime date,
    required int? sentimentScore,
    required String contentPreview,
    required List<String> keywords,
  }) {
    final dateStr = dateLabel(date);
    final emotionStr = sentimentScore != null 
        ? emotionScoreLabel(sentimentScore) 
        : '분석 전 일기';
    final keywordStr = keywords.isNotEmpty 
        ? '키워드: ${keywords.join(', ')}' 
        : '';
    final preview = contentPreview.characters.length > 50 
        ? '${contentPreview.characters.take(50)}...' 
        : contentPreview;

    return '$dateStr 작성된 일기. $emotionStr. $preview. $keywordStr';
  }

  /// 버튼에 대한 접근성 힌트
  static String buttonHint(String action) {
    return '두 번 탭하면 $action';
  }

  /// 분석 상태에 대한 접근성 레이블
  static String analysisStatusLabel(bool isAnalyzing, bool isAnalyzed) {
    if (isAnalyzing) {
      return 'AI 분석 진행 중입니다. 잠시만 기다려주세요.';
    } else if (isAnalyzed) {
      return 'AI 분석이 완료되었습니다.';
    } else {
      return 'AI 분석 전입니다.';
    }
  }
}

/// 접근성이 개선된 아이콘 버튼
/// 
/// 시맨틱 레이블과 힌트가 자동으로 추가됩니다.
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    this.onPressed,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: hint ?? AppAccessibility.buttonHint(label),
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: onPressed,
        tooltip: label,
      ),
    );
  }
}

/// 접근성이 개선된 카드 위젯
/// 
/// 탭 가능 여부와 시맨틱 정보를 포함합니다.
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AccessibleCard({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);

    return Semantics(
      button: onTap != null,
      label: label,
      hint: hint,
      child: InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: effectiveBorderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 접근성 설정을 위한 위젯 래퍼
/// 
/// 화면 전체에 접근성 속성을 적용합니다.
class AccessibilityWrapper extends StatelessWidget {
  final Widget child;
  final String? screenTitle;

  const AccessibilityWrapper({
    super.key,
    required this.child,
    this.screenTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      namesRoute: true,
      label: screenTitle,
      child: child,
    );
  }
}

/// 감정 점수 시각화에 접근성 추가
class AccessibleEmotionIndicator extends StatelessWidget {
  final int score;
  final double size;

  const AccessibleEmotionIndicator({
    super.key,
    required this.score,
    this.size = 48,
  });

  String get _emoji {
    if (score <= 2) return '😭';
    if (score <= 4) return '😢';
    if (score <= 6) return '🙂';
    if (score <= 8) return '😊';
    return '🥰';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppAccessibility.emotionScoreLabel(score),
      excludeSemantics: true,
      child: Text(
        _emoji,
        style: TextStyle(fontSize: size),
      ),
    );
  }
}

/// 스크린 리더 알림을 위한 유틸리티
class AccessibilityAnnouncer {
  AccessibilityAnnouncer._();

  /// 스크린 리더에게 메시지 알림
  static void announce(String message, {bool isPolite = true}) {
    // ignore: deprecated_member_use
    SemanticsService.announce(
      message,
      isPolite ? TextDirection.ltr : TextDirection.ltr,
    );
  }

  /// 분석 시작 알림
  static void announceAnalysisStart() {
    announce('AI 분석을 시작합니다. 잠시만 기다려주세요.');
  }

  /// 분석 완료 알림
  static void announceAnalysisComplete() {
    announce('AI 분석이 완료되었습니다.');
  }

  /// 저장 완료 알림
  static void announceSaved() {
    announce('저장되었습니다.');
  }

  /// 삭제 완료 알림
  static void announceDeleted() {
    announce('삭제되었습니다.');
  }

  /// 에러 알림
  static void announceError(String message) {
    announce('오류: $message', isPolite: false);
  }
}
