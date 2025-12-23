import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

/// 활동 히트맵 위젯 (GitHub 스타일 캘린더)
/// 하늘색 단일 색조 5단계로 표현
class ActivityHeatmap extends StatelessWidget {
  static const double _cellSize = 16;
  static const double _cellMargin = 2;
  static const double _cellRadius = 4;
  static const double _weekdayLabelWidth = 24;
  static const double _weekdayLabelHeight = 20;

  final Map<DateTime, double> activityMap;
  final int weeksToShow;

  const ActivityHeatmap({
    super.key,
    required this.activityMap,
    this.weeksToShow = 12,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: weeksToShow * 7 - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeatmap(context, startDate, now),
        const SizedBox(height: 12),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildHeatmap(BuildContext context, DateTime startDate, DateTime endDate) {
    // 요일 라벨 (월~일 모두 표시)
    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    // 시작 날짜를 월요일로 맞춤
    final adjustedStart = startDate.subtract(
      Duration(days: startDate.weekday - 1),
    );

    // 주 단위로 날짜 그룹핑
    final List<List<DateTime>> weeks = [];
    var currentDate = adjustedStart;

    while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
      final week = <DateTime>[];
      for (var i = 0; i < 7; i++) {
        week.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    // 월 라벨 계산
    final monthLabels = _getMonthLabels(weeks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 월 라벨
        Row(
          children: [
            const SizedBox(width: _weekdayLabelWidth), // 요일 라벨 공간
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: monthLabels.map((label) {
                    return SizedBox(
                      width: label.weekSpan * (_cellSize + _cellMargin * 2),
                      child: Text(
                        label.month,
                        style: TextStyle(
                          color: AppColors.statsTextTertiary,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 히트맵 본체
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 요일 라벨 (주말 색상 구분)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: weekdayLabels.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                // 토요일(5): 파란색, 일요일(6): 빨간색
                Color textColor;
                if (index == 5) {
                  textColor = AppColors.statsPrimary;
                } else if (index == 6) {
                  textColor = AppColors.statsAccentCoral;
                } else {
                  textColor = AppColors.statsTextTertiary;
                }
                return SizedBox(
                  height: _weekdayLabelHeight,
                  width: _weekdayLabelWidth,
                  child: Text(
                    day,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontWeight: (index == 5 || index == 6)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 4),
            // 히트맵 그리드
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // 최신이 오른쪽에
                child: Row(
                  children: weeks.map((week) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: week.map((date) {
                        return _buildCell(context, date, endDate);
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, DateTime date, DateTime endDate) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // 미래 날짜는 비활성화
    if (date.isAfter(endDate)) {
      return Container(
        width: _cellSize,
        height: _cellSize,
        margin: const EdgeInsets.all(_cellMargin),
        decoration: BoxDecoration(
          color: AppColors.heatmapLevel0.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(_cellRadius),
          border: Border.all(
            color: AppColors.statsCardBorder.withValues(alpha: 0.6),
            width: 0.6,
          ),
        ),
      );
    }

    // 해당 날짜의 감정 점수 찾기
    double? score;
    for (final entry in activityMap.entries) {
      final entryDate = DateTime(
        entry.key.year,
        entry.key.month,
        entry.key.day,
      );
      if (entryDate == normalizedDate) {
        score = entry.value;
        break;
      }
    }

    final color = AppColors.getHeatmapColor(score);
    final highlight = Color.lerp(color, Colors.white, 0.35) ?? color;
    final hasRecord = score != null;

    return Tooltip(
      message: _getTooltipMessage(date, score),
      decoration: BoxDecoration(
        color: AppColors.statsTextPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      child: Container(
        width: _cellSize,
        height: _cellSize,
        margin: const EdgeInsets.all(_cellMargin),
        decoration: BoxDecoration(
          color: hasRecord ? null : color.withValues(alpha: 0.45),
          gradient: hasRecord
              ? LinearGradient(
                  colors: [highlight, color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(_cellRadius),
          border: Border.all(
            color: hasRecord
                ? color.withValues(alpha: 0.35)
                : AppColors.statsCardBorder,
            width: 0.6,
          ),
          boxShadow: hasRecord
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '기분 온도',
          style: TextStyle(
            color: AppColors.statsTextTertiary,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          '🙂',
          style: TextStyle(fontSize: 11),
        ),
        const SizedBox(width: 4),
        // 5단계 색상 범례
        ...AppColors.heatmapLegendColors.map((color) {
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
        const SizedBox(width: 4),
        const Text(
          '😊',
          style: TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  String _getTooltipMessage(DateTime date, double? score) {
    final dateStr = DateFormat('yyyy년 M월 d일').format(date);
    if (score == null) {
      return '$dateStr\n쉬어간 날이에요';
    }
    return '$dateStr\n기록한 날이에요 · 평균 ${score.toStringAsFixed(1)}점';
  }

  /// 월 라벨 계산
  List<_MonthLabel> _getMonthLabels(List<List<DateTime>> weeks) {
    final labels = <_MonthLabel>[];
    int? currentMonth;
    int weekSpan = 0;

    for (int i = weeks.length - 1; i >= 0; i--) {
      final week = weeks[i];
      final firstDayOfWeek = week.first;
      final month = firstDayOfWeek.month;

      if (currentMonth == null) {
        currentMonth = month;
        weekSpan = 1;
      } else if (month != currentMonth) {
        labels.add(_MonthLabel(
          month: _getMonthName(currentMonth),
          weekSpan: weekSpan,
        ));
        currentMonth = month;
        weekSpan = 1;
      } else {
        weekSpan++;
      }
    }

    // 마지막 월 추가
    if (currentMonth != null) {
      labels.add(_MonthLabel(
        month: _getMonthName(currentMonth),
        weekSpan: weekSpan,
      ));
    }

    return labels.reversed.toList();
  }

  String _getMonthName(int month) {
    const months = ['', '1월', '2월', '3월', '4월', '5월', '6월',
                    '7월', '8월', '9월', '10월', '11월', '12월'];
    return months[month];
  }
}

class _MonthLabel {
  final String month;
  final int weekSpan;

  _MonthLabel({required this.month, required this.weekSpan});
}
