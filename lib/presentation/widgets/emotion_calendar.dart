import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

/// 감정 달력 위젯 (월간 캘린더 UI)
/// 감정 점수를 식물 성장 단계로 시각화
class EmotionCalendar extends StatefulWidget {
  /// 날짜별 감정 점수 (1-10)
  final Map<DateTime, double> activityMap;

  /// 초기 표시할 월 (기본값: 현재 월)
  final DateTime? initialMonth;

  /// 날짜 탭 콜백
  final void Function(DateTime)? onDayTap;

  /// 월 변경 콜백
  final void Function(DateTime)? onMonthChanged;

  /// 범례 표시 여부
  final bool showLegend;

  const EmotionCalendar({
    super.key,
    required this.activityMap,
    this.initialMonth,
    this.onDayTap,
    this.onMonthChanged,
    this.showLegend = true,
  });

  @override
  State<EmotionCalendar> createState() => _EmotionCalendarState();
}

class _EmotionCalendarState extends State<EmotionCalendar> {
  static const double _cellSize = 44.0;
  static const double _emojiSize = 16.0;
  static const double _dateFontSize = 12.0;
  static const int _initialPageIndex = 1000; // 충분한 과거/미래 범위

  static final DateFormat _tooltipFormatter = DateFormat('yyyy년 M월 d일');

  late DateTime _initialMonth;
  late DateTime _focusedMonth;
  late PageController _pageController;
  late Map<DateTime, double> _normalizedActivityMap;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _initialMonth = widget.initialMonth ?? DateTime(now.year, now.month);
    _focusedMonth = _initialMonth;
    _pageController = PageController(initialPage: _initialPageIndex);
    _normalizedActivityMap = _normalizeActivityMap();
  }

  @override
  void didUpdateWidget(EmotionCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activityMap != oldWidget.activityMap) {
      _normalizedActivityMap = _normalizeActivityMap();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// activityMap 키를 날짜만으로 정규화 (O(n) 전처리)
  Map<DateTime, double> _normalizeActivityMap() {
    final normalized = <DateTime, double>{};
    for (final entry in widget.activityMap.entries) {
      final normalizedKey = _normalizeDate(entry.key);
      normalized[normalizedKey] = entry.value;
    }
    return normalized;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _focusedMonth.year == now.year && _focusedMonth.month == now.month;
  }

  /// 월의 시작 요일 (월요일 기준, 0 = 월요일)
  int _getFirstWeekdayOfMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    return (firstDay.weekday - 1) % 7;
  }

  /// 월의 총 일수
  int _getDaysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  void _prevMonth() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextMonth() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToToday() {
    final now = DateTime.now();
    final targetMonth = DateTime(now.year, now.month);
    final monthsDiff = (targetMonth.year - _initialMonth.year) * 12 +
        (targetMonth.month - _initialMonth.month);
    final targetPage = _initialPageIndex + monthsDiff;

    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildWeekdayHeader(),
        const SizedBox(height: 8),
        SizedBox(
          height: 6 * _cellSize + 5 * 4, // 6주 * 셀 높이 + 간격
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              final newMonth = DateTime(
                _initialMonth.year,
                _initialMonth.month + (index - _initialPageIndex),
              );
              setState(() {
                _focusedMonth = newMonth;
              });
              widget.onMonthChanged?.call(newMonth);
            },
            itemBuilder: (context, index) {
              final month = DateTime(
                _initialMonth.year,
                _initialMonth.month + (index - _initialPageIndex),
              );
              return _buildCalendarGrid(month);
            },
          ),
        ),
        if (widget.showLegend) ...[
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _prevMonth,
          icon: const Icon(Icons.chevron_left),
          color: AppColors.statsTextSecondary,
          iconSize: 24,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: EdgeInsets.zero,
        ),
        Text(
          '${_focusedMonth.year}년 ${_focusedMonth.month}월',
          style: const TextStyle(
            color: AppColors.statsTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isCurrentMonth)
              TextButton(
                onPressed: _goToToday,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text(
                  '오늘',
                  style: TextStyle(
                    color: AppColors.statsPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right),
              color: AppColors.statsTextSecondary,
              iconSize: 24,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return Row(
      children: weekdays.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        Color textColor;
        FontWeight fontWeight;

        if (index == 5) {
          // 토요일
          textColor = AppColors.statsPrimary;
          fontWeight = FontWeight.w600;
        } else if (index == 6) {
          // 일요일
          textColor = AppColors.statsAccentCoral;
          fontWeight = FontWeight.w600;
        } else {
          textColor = AppColors.statsTextTertiary;
          fontWeight = FontWeight.normal;
        }

        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: fontWeight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstWeekday = _getFirstWeekdayOfMonth(month);
    final daysInMonth = _getDaysInMonth(month);
    final daysInPrevMonth = _getDaysInMonth(
      DateTime(month.year, month.month - 1),
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
      ),
      itemCount: 42, // 6주 × 7일
      itemBuilder: (context, index) => _buildDayCell(
        index,
        month,
        firstWeekday,
        daysInMonth,
        daysInPrevMonth,
      ),
    );
  }

  Widget _buildDayCell(
    int index,
    DateTime month,
    int firstWeekday,
    int daysInMonth,
    int daysInPrevMonth,
  ) {
    DateTime date;
    bool isCurrentMonth;

    if (index < firstWeekday) {
      // 이전 월
      date = DateTime(
        month.year,
        month.month - 1,
        daysInPrevMonth - firstWeekday + index + 1,
      );
      isCurrentMonth = false;
    } else if (index < firstWeekday + daysInMonth) {
      // 현재 월
      date = DateTime(
        month.year,
        month.month,
        index - firstWeekday + 1,
      );
      isCurrentMonth = true;
    } else {
      // 다음 월
      date = DateTime(
        month.year,
        month.month + 1,
        index - firstWeekday - daysInMonth + 1,
      );
      isCurrentMonth = false;
    }

    final normalizedDate = _normalizeDate(date);
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final isFuture = date.isAfter(now);
    final score = _normalizedActivityMap[normalizedDate];

    return _DayCell(
      date: date,
      score: score,
      isCurrentMonth: isCurrentMonth,
      isToday: isToday,
      isFuture: isFuture,
      onTap: widget.onDayTap,
      tooltipFormatter: _tooltipFormatter,
      emojiSize: _emojiSize,
      dateFontSize: _dateFontSize,
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          '마음의 정원',
          style: TextStyle(
            color: AppColors.statsTextTertiary,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 8),
        _buildLegendItem('🌱'),
        _buildLegendArrow(),
        _buildLegendItem('🌿'),
        _buildLegendArrow(),
        _buildLegendItem('🌷'),
        _buildLegendArrow(),
        _buildLegendItem('🌸'),
        _buildLegendArrow(),
        _buildLegendItem('🌻'),
      ],
    );
  }

  Widget _buildLegendItem(String emoji) {
    return Text(
      emoji,
      style: const TextStyle(fontSize: 11),
    );
  }

  Widget _buildLegendArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        '→',
        style: TextStyle(
          fontSize: 8,
          color: AppColors.statsTextTertiary,
        ),
      ),
    );
  }
}

/// 개별 날짜 셀 위젯 (마이크로 인터랙션 지원)
class _DayCell extends StatefulWidget {
  final DateTime date;
  final double? score;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isFuture;
  final void Function(DateTime)? onTap;
  final DateFormat tooltipFormatter;
  final double emojiSize;
  final double dateFontSize;

  const _DayCell({
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
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
            ? Border.all(
                color: AppColors.statsPrimary,
                width: 2,
              )
            : hasRecord && widget.isCurrentMonth && !widget.isFuture
                ? Border.all(
                    color: AppColors.statsAccentMint.withValues(alpha: 0.4),
                    width: 0.8,
                  )
                : Border.all(
                    color:
                        AppColors.gardenSoilBorder.withValues(alpha: opacity),
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
                  fontWeight: widget.isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (hasRecord && widget.isCurrentMonth && !widget.isFuture) ...[
                Text(
                  emoji,
                  style: TextStyle(fontSize: widget.emojiSize),
                ),
              ] else if (isTodayNoRecord) ...[
                Text(
                  '✨',
                  style: TextStyle(fontSize: widget.emojiSize - 2),
                ),
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
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
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
