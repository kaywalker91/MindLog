import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

/// 감정 정원 위젯 (사용자 친화적 캘린더)
/// 감정 점수를 식물 성장 단계로 시각화
class EmotionGarden extends StatelessWidget {
  static const double _cellSize = 22;
  static const double _cellMargin = 2;
  static const double _cellRadius = 6;
  static const double _weekdayLabelWidth = 24;
  static const double _weekdayLabelHeight = 26;
  static const double _emojiSize = 14.0;

  static final DateFormat _tooltipFormatter = DateFormat('yyyy년 M월 d일');

  final Map<DateTime, double> activityMap;
  final int weeksToShow;

  const EmotionGarden({
    super.key,
    required this.activityMap,
    this.weeksToShow = 12,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: weeksToShow * 7 - 1));
    final normalizedActivityMap = _normalizeActivityMap();

    // RepaintBoundary: 168개 셀(24주×7일) 그리드의 불필요한 repaint 방지
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGarden(context, startDate, now, normalizedActivityMap),
          const SizedBox(height: 12),
          _buildLegend(context),
        ],
      ),
    );
  }

  /// activityMap 키를 날짜만으로 정규화 (O(n) 전처리)
  Map<DateTime, double> _normalizeActivityMap() {
    final normalized = <DateTime, double>{};
    for (final entry in activityMap.entries) {
      final normalizedKey = DateTime(
        entry.key.year,
        entry.key.month,
        entry.key.day,
      );
      normalized[normalizedKey] = entry.value;
    }
    return normalized;
  }

  Widget _buildGarden(
    BuildContext context,
    DateTime startDate,
    DateTime endDate,
    Map<DateTime, double> normalizedActivityMap,
  ) {
    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    // 시작 날짜를 월요일로 조정
    final adjustedStart = startDate.subtract(
      Duration(days: startDate.weekday - 1),
    );

    // 주 단위 그룹핑
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

    final monthLabels = _getMonthLabels(weeks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 월 라벨
        Row(
          children: [
            const SizedBox(width: _weekdayLabelWidth),
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
                        style: const TextStyle(
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
        // 정원 본체
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 요일 라벨
            Column(
              mainAxisSize: MainAxisSize.min,
              children: weekdayLabels.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
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
            // 정원 그리드
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: weeks.map((week) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: week.map((date) {
                        return _buildGardenCell(
                          context,
                          date,
                          endDate,
                          normalizedActivityMap,
                        );
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

  Widget _buildGardenCell(
    BuildContext context,
    DateTime date,
    DateTime endDate,
    Map<DateTime, double> normalizedActivityMap,
  ) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // 미래 날짜
    if (date.isAfter(endDate)) {
      return Container(
        width: _cellSize,
        height: _cellSize,
        margin: const EdgeInsets.all(_cellMargin),
        decoration: BoxDecoration(
          color: AppColors.gardenSoil.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(_cellRadius),
          border: Border.all(
            color: AppColors.gardenSoilBorder.withValues(alpha: 0.5),
            width: 0.6,
          ),
        ),
      );
    }

    final score = normalizedActivityMap[normalizedDate];
    final hasRecord = score != null;
    final emoji = _getEmojiForScore(score);
    final bgColor = _getBackgroundColor(score);

    return Tooltip(
      message: _getTooltipMessage(date, score),
      decoration: BoxDecoration(
        color: AppColors.statsTextPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: Container(
        width: _cellSize,
        height: _cellSize,
        margin: const EdgeInsets.all(_cellMargin),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(_cellRadius),
          border: Border.all(
            color: hasRecord
                ? AppColors.statsAccentMint.withValues(alpha: 0.4)
                : AppColors.gardenSoilBorder,
            width: 0.8,
          ),
          boxShadow: hasRecord
              ? [
                  BoxShadow(
                    color: AppColors.statsAccentMint.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: _emojiSize)),
        ),
      ),
    );
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

  /// 감정 점수 → 배경색 매핑
  Color _getBackgroundColor(double? score) {
    if (score == null) return AppColors.gardenSoil;
    // 성장할수록 연두빛 배경
    if (score <= 2) return AppColors.gardenLegacy1;
    if (score <= 4) return AppColors.gardenLegacy2;
    if (score <= 6) return AppColors.gardenLegacy3;
    if (score <= 8) return AppColors.gardenLegacy4;
    return AppColors.gardenLegacy5;
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          '마음의 정원',
          style: TextStyle(color: AppColors.statsTextTertiary, fontSize: 10),
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
    return Text(emoji, style: const TextStyle(fontSize: 11));
  }

  Widget _buildLegendArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        '→',
        style: TextStyle(fontSize: 8, color: AppColors.statsTextTertiary),
      ),
    );
  }

  String _getTooltipMessage(DateTime date, double? score) {
    final dateStr = _tooltipFormatter.format(date);
    if (score == null) {
      return '$dateStr\n아직 씨앗을 심지 않은 날이에요';
    }
    final emoji = _getEmojiForScore(score);
    final label = _getLabelForScore(score);
    return '$dateStr\n$emoji $label · 평균 ${score.toStringAsFixed(1)}점';
  }

  String _getLabelForScore(double score) {
    if (score <= 2) return '씨앗을 심었어요';
    if (score <= 4) return '새싹이 자라요';
    if (score <= 6) return '꽃봉오리가 맺혔어요';
    if (score <= 8) return '꽃이 활짝!';
    return '해바라기가 피었어요';
  }

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
        labels.add(
          _MonthLabel(month: _getMonthName(currentMonth), weekSpan: weekSpan),
        );
        currentMonth = month;
        weekSpan = 1;
      } else {
        weekSpan++;
      }
    }

    if (currentMonth != null) {
      labels.add(
        _MonthLabel(month: _getMonthName(currentMonth), weekSpan: weekSpan),
      );
    }

    return labels.reversed.toList();
  }

  String _getMonthName(int month) {
    const months = [
      '',
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월',
    ];
    return months[month];
  }
}

class _MonthLabel {
  final String month;
  final int weekSpan;

  _MonthLabel({required this.month, required this.weekSpan});
}
