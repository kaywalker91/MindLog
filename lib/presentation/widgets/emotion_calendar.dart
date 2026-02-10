import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'emotion_calendar/emotion_calendar.dart';

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
  static const int _initialPageIndex = 1000;

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

  int _getFirstWeekdayOfMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    return (firstDay.weekday - 1) % 7;
  }

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
    final monthsDiff =
        (targetMonth.year - _initialMonth.year) * 12 +
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
        RepaintBoundary(
          child: CalendarHeader(
            focusedMonth: _focusedMonth,
            isCurrentMonth: _isCurrentMonth,
            onPrevMonth: _prevMonth,
            onNextMonth: _nextMonth,
            onGoToToday: _goToToday,
          ),
        ),
        const SizedBox(height: 12),
        const WeekdayHeader(),
        const SizedBox(height: 8),
        SizedBox(
          height: 6 * _cellSize + 5 * 4,
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
              return RepaintBoundary(child: _buildCalendarGrid(month));
            },
          ),
        ),
        if (widget.showLegend) ...[
          const SizedBox(height: 12),
          const RepaintBoundary(child: CalendarLegend()),
        ],
      ],
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
      itemCount: 42,
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
      date = DateTime(
        month.year,
        month.month - 1,
        daysInPrevMonth - firstWeekday + index + 1,
      );
      isCurrentMonth = false;
    } else if (index < firstWeekday + daysInMonth) {
      date = DateTime(month.year, month.month, index - firstWeekday + 1);
      isCurrentMonth = true;
    } else {
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

    // DayCell은 const 생성자를 사용하고 operator==를 오버라이드하여
    // 파라미터가 변경되지 않으면 리빌드되지 않도록 최적화됨
    return DayCell(
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
}
