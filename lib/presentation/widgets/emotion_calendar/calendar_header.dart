import 'package:flutter/material.dart';
import '../../../core/theme/statistics_theme_tokens.dart';

/// 캘린더 헤더 위젯 (월 네비게이션)
class CalendarHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final bool isCurrentMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onGoToToday;

  const CalendarHeader({
    super.key,
    required this.focusedMonth,
    required this.isCurrentMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onGoToToday,
  });

  @override
  Widget build(BuildContext context) {
    final statsTokens = StatisticsThemeTokens.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrevMonth,
          icon: const Icon(Icons.chevron_left),
          tooltip: '이전 달',
          color: statsTokens.textSecondary,
          iconSize: 24,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: EdgeInsets.zero,
        ),
        Text(
          '${focusedMonth.year}년 ${focusedMonth.month}월',
          style: TextStyle(
            color: statsTokens.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCurrentMonth)
              TextButton(
                onPressed: onGoToToday,
                style: TextButton.styleFrom(
                  foregroundColor: statsTokens.primaryStrong,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text(
                  '오늘',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            IconButton(
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right),
              tooltip: '다음 달',
              color: statsTokens.textSecondary,
              iconSize: 24,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }
}

/// 요일 헤더 위젯
class WeekdayHeader extends StatelessWidget {
  const WeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final statsTokens = StatisticsThemeTokens.of(context);
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return Row(
      children: weekdays.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        Color textColor;
        FontWeight fontWeight;

        if (index == 5) {
          // 토요일
          textColor = statsTokens.primaryStrong;
          fontWeight = FontWeight.w600;
        } else if (index == 6) {
          // 일요일
          textColor = statsTokens.coralAccent;
          fontWeight = FontWeight.w600;
        } else {
          textColor = statsTokens.textTertiary;
          fontWeight = FontWeight.w500;
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
}
