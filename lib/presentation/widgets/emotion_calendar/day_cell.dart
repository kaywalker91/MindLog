import 'package:flutter/material.dart';
import '../../../core/accessibility/app_accessibility.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/statistics_theme_tokens.dart';
import '../../../core/utils/date_formatter.dart';

/// 개별 날짜 셀 위젯 (마이크로 인터랙션 지원)
/// 성능 최적화를 위해 const 생성자와 == 연산자 오버라이드 구현
class DayCell extends StatefulWidget {
  final DateTime date;
  final double? score;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isFuture;
  final void Function(DateTime)? onTap;
  final double emojiSize;
  final double dateFontSize;

  const DayCell({
    super.key,
    required this.date,
    required this.score,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
    required this.emojiSize,
    required this.dateFontSize,
  });

  @override
  State<DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<DayCell> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!_shouldAnimate) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_shouldAnimate) return;
    setState(() => _isPressed = false);
    widget.onTap?.call(widget.date);
  }

  void _handleTapCancel() {
    if (!_shouldAnimate) return;
    setState(() => _isPressed = false);
  }

  bool get _shouldAnimate => widget.isCurrentMonth && !widget.isFuture;

  @override
  Widget build(BuildContext context) {
    final statsTokens = StatisticsThemeTokens.of(context);
    final hasRecord = widget.score != null;
    final emoji = _getEmojiForScore(widget.score);
    final bgColor = _getBackgroundColor(widget.score, statsTokens);

    // 다른 월 또는 미래 날짜는 흐리게
    final opacity = widget.isCurrentMonth && !widget.isFuture
        ? 1.0
        : statsTokens.calendarInactiveOpacity;
    final textOpacity = widget.isCurrentMonth && !widget.isFuture
        ? 1.0
        : statsTokens.calendarInactiveTextOpacity;

    // 접근성: 애니메이션 비활성화 설정 체크
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // 오늘 + 미기록 여부
    final isTodayNoRecord =
        widget.isToday && !hasRecord && widget.isCurrentMonth;

    final decoration = BoxDecoration(
      color: isTodayNoRecord
          ? statsTokens.calendarTodayBackground
          : bgColor.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(8),
      border: widget.isToday
          ? Border.all(color: statsTokens.calendarTodayBorder, width: 1.8)
          : hasRecord && widget.isCurrentMonth && !widget.isFuture
          ? Border.all(color: statsTokens.calendarRecordBorder, width: 0.8)
          : Border.all(
              color: statsTokens.calendarEmptyBorder.withValues(alpha: opacity),
              width: 0.6,
            ),
      // 기록 있는 셀에 Glow 효과
      boxShadow: hasRecord && widget.isCurrentMonth && !widget.isFuture
          ? [
              BoxShadow(
                color: statsTokens.calendarRecordGlow.withValues(alpha: 0.22),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ]
          : isTodayNoRecord
          ? [
              BoxShadow(
                color: statsTokens.calendarTodayBorder.withValues(alpha: 0.25),
                blurRadius: 5,
                spreadRadius: 0,
              ),
            ]
          : null,
    );

    final Widget content = Container(
      margin: const EdgeInsets.all(2),
      decoration: decoration,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.date.day}',
                style: TextStyle(
                  color: _getDateTextColor(
                    statsTokens,
                  ).withValues(alpha: textOpacity),
                  fontSize: widget.dateFontSize,
                  fontWeight: widget.isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (hasRecord && widget.isCurrentMonth && !widget.isFuture) ...[
                Semantics(
                  label: _getLabelForScore(widget.score!),
                  excludeSemantics: true,
                  child: Text(emoji, style: TextStyle(fontSize: widget.emojiSize)),
                ),
              ] else if (isTodayNoRecord) ...[
                Semantics(
                  label: '오늘',
                  excludeSemantics: true,
                  child: Text('✨', style: TextStyle(fontSize: widget.emojiSize - 2)),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // 현재 월이고 미래가 아닌 경우만 툴팁과 탭 이벤트 추가
    if (_shouldAnimate) {
      // 애니메이션 적용 (ImplicitlyAnimatedWidget 사용)
      final Widget animatedCell = reduceMotion
          ? content
          : AnimatedScale(
              scale: _isPressed ? 0.95 : 1.0,
              duration: Duration(milliseconds: statsTokens.microMotionMs),
              curve: Curves.easeInOut,
              child: content,
            );

      return Semantics(
        button: true,
        label: AppAccessibility.dateLabel(widget.date),
        child: Tooltip(
          message: _getTooltipMessage(),
          decoration: BoxDecoration(
            color: statsTokens.chartTooltipBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            color: statsTokens.chartTooltipForeground,
            fontSize: 12,
          ),
          child: GestureDetector(
            onTapDown: reduceMotion ? null : _handleTapDown,
            onTapUp: reduceMotion
                ? null
                : _handleTapUp, // scale 복귀 후 onTap 호출은 _handleTapUp 내부에서 처리하거나, 별도로 Future.delayed 사용 가능하나 여기서는 단순화
            onTapCancel: reduceMotion ? null : _handleTapCancel,
            onTap: reduceMotion && widget.onTap != null
                ? () => widget.onTap!(widget.date)
                : null, // reduceMotion일 때만 여기서 호출, 애니메이션시는 onTapUp에서 처리
            child: animatedCell,
          ),
        ),
      );
    }

    return content;
  }

  Color _getDateTextColor(StatisticsThemeTokens statsTokens) {
    final weekday = widget.date.weekday;
    if (weekday == 6) {
      // 토요일
      return statsTokens.primaryStrong;
    } else if (weekday == 7) {
      // 일요일
      return statsTokens.coralAccent;
    }
    return statsTokens.textPrimary;
  }

  /// 감정 점수 → 이모지 매핑
  String _getEmojiForScore(double? score) {
    if (score == null) return '';
    if (score <= 2) return '🌱'; // 씨앗
    if (score <= 4) return '🌿'; // 새싹
    if (score <= 6) return '🌷'; // 꽃봉오리
    if (score <= 8) return '🌸'; // 꽃
    return '🌻'; // 해바라기
  }

  /// 감정 점수 → 배경색 매핑 (따뜻한 톤)
  Color _getBackgroundColor(double? score, StatisticsThemeTokens statsTokens) {
    if (score == null) return statsTokens.calendarEmptyCell;
    // 따뜻한 정원 색상 팔레트 사용
    if (score <= 2) return AppColors.gardenWarm1;
    if (score <= 4) return AppColors.gardenWarm2;
    if (score <= 6) return AppColors.gardenWarm3;
    if (score <= 8) return AppColors.gardenWarm4;
    return AppColors.gardenWarm5;
  }

  /// 친근한 툴팁 메시지
  String _getTooltipMessage() {
    final dateStr = DateFormatter.formatDate(widget.date);

    // 오늘 + 미기록 특별 메시지
    if (widget.isToday && widget.score == null) {
      return '$dateStr\n오늘의 씨앗을 심어볼까요? ✨';
    }

    if (widget.score == null) {
      return '$dateStr\n이 날은 정원이 쉬었어요 🌙';
    }
    final emoji = _getEmojiForScore(widget.score);
    final label = _getLabelForScore(widget.score!);
    return '$dateStr\n$emoji $label · 평균 ${widget.score!.toStringAsFixed(1)}점';
  }

  /// 친근한 레이블
  String _getLabelForScore(double score) {
    if (score <= 2) return '작은 씨앗에서 시작!';
    if (score <= 4) return '새싹이 기지개를 켜요';
    if (score <= 6) return '예쁜 꽃봉오리가 맺혔어요';
    if (score <= 8) return '꽃이 활짝 피었어요!';
    return '환하게 빛나는 하루!';
  }
}
