import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 활동 히트맵 위젯 (GitHub 스타일 캘린더)
class ActivityHeatmap extends StatelessWidget {
  final Map<DateTime, double> activityMap;
  final int weeksToShow;

  const ActivityHeatmap({
    super.key,
    required this.activityMap,
    this.weeksToShow = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: weeksToShow * 7 - 1));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '일기 작성 기록',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '최근 ${weeksToShow}주간 기록이에요',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _buildHeatmap(context, startDate, now),
          const SizedBox(height: 16),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context, DateTime startDate, DateTime endDate) {
    final colorScheme = Theme.of(context).colorScheme;

    // 요일 라벨
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 요일 라벨
        Column(
          mainAxisSize: MainAxisSize.min,
          children: weekdays.map((day) {
            return SizedBox(
              height: 16,
              width: 20,
              child: Text(
                day,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
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
    );
  }

  Widget _buildCell(BuildContext context, DateTime date, DateTime endDate) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // 미래 날짜는 비활성화
    if (date.isAfter(endDate)) {
      return Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: colorScheme.outline.withOpacity(0.05),
          borderRadius: BorderRadius.circular(2),
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

    final color = _getColorForScore(score, colorScheme);

    return Tooltip(
      message: _getTooltipMessage(date, score),
      child: Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '감정 점수',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        // 낮음
        _buildLegendItem(colorScheme.outline.withOpacity(0.2)),
        _buildLegendItem(_getColorForScore(3, colorScheme)),
        _buildLegendItem(_getColorForScore(5, colorScheme)),
        _buildLegendItem(_getColorForScore(7, colorScheme)),
        _buildLegendItem(_getColorForScore(9, colorScheme)),
        const SizedBox(width: 4),
        Text(
          '높음',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _getTooltipMessage(DateTime date, double? score) {
    final dateStr = DateFormat('yyyy년 M월 d일').format(date);
    if (score == null) {
      return '$dateStr\n기록 없음';
    }
    return '$dateStr\n평균 ${score.toStringAsFixed(1)}점';
  }

  Color _getColorForScore(double? score, ColorScheme colorScheme) {
    if (score == null) {
      return colorScheme.outline.withOpacity(0.1);
    }

    // 감정 점수에 따른 색상 (1-10)
    // 낮은 점수: 빨간색 계열 → 높은 점수: 초록색 계열
    if (score <= 2) return Colors.red.shade300;
    if (score <= 4) return Colors.orange.shade300;
    if (score <= 6) return Colors.amber.shade300;
    if (score <= 8) return Colors.lightGreen.shade400;
    return Colors.green.shade500;
  }
}
