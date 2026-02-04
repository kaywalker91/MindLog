import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

/// 개별 날짜 셀 위젯 (마이크로 인터랙션 지원)
class DayCell extends StatefulWidget {
  final DateTime date;
  final double? score;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isFuture;
  final void Function(DateTime)? onTap;
  final DateFormat tooltipFormatter;
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
    required this.tooltipFormatter,
    required this.emojiSize,
    required this.dateFontSize,
  });

  @override
  State<DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<DayCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRecord = widget.score != null;
    final emoji = _getEmojiForScore(widget.score);
    final bgColor = _getBackgroundColor(widget.score);

    // 다른 월 또는 미래 날짜는 흐리게
    final opacity = widget.isCurrentMonth && !widget.isFuture ? 1.0 : 0.35;
    final textOpacity = widget.isCurrentMonth && !widget.isFuture ? 1.0 : 0.5;

    // 접근성: 애니메이션 비활성화 설정 체크
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // 오늘 + 미기록 여부
    final isTodayNoRecord =
        widget.isToday && !hasRecord && widget.isCurrentMonth;

    final Widget cell = Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isTodayNoRecord
            ? AppColors.todayGlow.withValues(alpha: 0.3)
            : bgColor.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(8),
        border: widget.isToday
            ? Border.all(color: AppColors.statsPrimary, width: 2)
            : hasRecord && widget.isCurrentMonth && !widget.isFuture
            ? Border.all(
                color: AppColors.statsAccentMint.withValues(alpha: 0.4),
                width: 0.8,
              )
            : Border.all(
                color: AppColors.gardenSoilBorder.withValues(alpha: opacity),
                width: 0.6,
              ),
        // 기록 있는 셀에 Glow 효과
        boxShadow: hasRecord && widget.isCurrentMonth && !widget.isFuture
            ? [
                BoxShadow(
                  color: AppColors.gardenGlow.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : isTodayNoRecord
            ? [
                BoxShadow(
                  color: AppColors.todayGlow.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
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
                  color: _getDateTextColor().withValues(alpha: textOpacity),
                  fontSize: widget.dateFontSize,
                  fontWeight: widget.isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (hasRecord && widget.isCurrentMonth && !widget.isFuture) ...[
                Text(emoji, style: TextStyle(fontSize: widget.emojiSize)),
              ] else if (isTodayNoRecord) ...[
                Text('✨', style: TextStyle(fontSize: widget.emojiSize - 2)),
              ],
            ],
          ),
        ),
      ),
    );

    // 현재 월이고 미래가 아닌 경우만 툴팁과 탭 이벤트 추가
    if (widget.isCurrentMonth && !widget.isFuture) {
      // 애니메이션 적용 (접근성 설정 존중)
      Widget animatedCell = reduceMotion
          ? cell
          : AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: cell,
            );

      animatedCell = Tooltip(
        message: _getTooltipMessage(),
        decoration: BoxDecoration(
          color: AppColors.statsTextPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        child: GestureDetector(
          onTapDown: reduceMotion ? null : (_) => _controller.forward(),
          onTapUp: reduceMotion
              ? null
              : (_) {
                  _controller.reverse();
                  widget.onTap?.call(widget.date);
                },
          onTapCancel: reduceMotion ? null : () => _controller.reverse(),
          onTap: reduceMotion && widget.onTap != null
              ? () => widget.onTap!(widget.date)
              : null,
          child: animatedCell,
        ),
      );

      return animatedCell;
    }

    return cell;
  }

  Color _getDateTextColor() {
    final weekday = widget.date.weekday;
    if (weekday == 6) {
      // 토요일
      return AppColors.statsPrimary;
    } else if (weekday == 7) {
      // 일요일
      return AppColors.statsAccentCoral;
    }
    return AppColors.statsTextPrimary;
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
  Color _getBackgroundColor(double? score) {
    if (score == null) return AppColors.gardenSoil;
    // 따뜻한 정원 색상 팔레트 사용
    if (score <= 2) return AppColors.gardenWarm1;
    if (score <= 4) return AppColors.gardenWarm2;
    if (score <= 6) return AppColors.gardenWarm3;
    if (score <= 8) return AppColors.gardenWarm4;
    return AppColors.gardenWarm5;
  }

  /// 친근한 툴팁 메시지
  String _getTooltipMessage() {
    final dateStr = widget.tooltipFormatter.format(widget.date);

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
