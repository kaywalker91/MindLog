import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/statistics_theme_tokens.dart';
import '../../domain/entities/statistics.dart';

/// 감정 점수 라인 차트 위젯 (하늘색 단일 색조)
class EmotionLineChart extends StatelessWidget {
  // DateFormat 인스턴스 재사용 (생성 비용 최적화)
  static final DateFormat _shortDateFormatter = DateFormat('M/d');
  static final DateFormat _tooltipDateFormatter = DateFormat('M월 d일');

  final List<DailyEmotion> dailyEmotions;
  final StatisticsPeriod period;

  const EmotionLineChart({
    super.key,
    required this.dailyEmotions,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final statsTokens = StatisticsThemeTokens.of(context);
    final chartAccent = statsTokens.primaryStrong;
    final axisColor = statsTokens.textSecondary;
    final gridColor = statsTokens.chartGrid;

    if (dailyEmotions.isEmpty) {
      return _buildEmptyState(context);
    }

    // Repository에서 이미 최신순 정렬됨 → 역순으로 변환 (복사+정렬 제거)
    final sortedEmotions = dailyEmotions.reversed.toList();

    // RepaintBoundary: fl_chart의 CustomPaint가 상위 위젯 rebuild 시 불필요하게 repaint되는 것 방지
    return RepaintBoundary(
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 2,
              getDrawingHorizontalLine: (value) {
                return FlLine(color: gridColor, strokeWidth: 1);
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: _calculateInterval(sortedEmotions.length),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedEmotions.length) {
                      final date = sortedEmotions[index].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _shortDateFormatter.format(date),
                          style: TextStyle(color: axisColor, fontSize: 10),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 2,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value > 10) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: axisColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (sortedEmotions.length - 1).toDouble(),
            minY: 0,
            maxY: 10,
            lineBarsData: [
              LineChartBarData(
                spots: sortedEmotions.asMap().entries.map((entry) {
                  return FlSpot(entry.key.toDouble(), entry.value.averageScore);
                }).toList(),
                isCurved: true,
                curveSmoothness: 0.3,
                color: chartAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: sortedEmotions.length <= 14,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: chartAccent,
                      strokeWidth: 2,
                      strokeColor: statsTokens.cardBackground,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      chartAccent.withValues(alpha: 0.3),
                      chartAccent.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) =>
                    statsTokens.chartTooltipBackground,
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    if (index >= 0 && index < sortedEmotions.length) {
                      final emotion = sortedEmotions[index];
                      return LineTooltipItem(
                        '${_tooltipDateFormatter.format(emotion.date)}\n'
                        '평균 ${emotion.averageScore.toStringAsFixed(1)}점',
                        TextStyle(
                          color: statsTokens.chartTooltipForeground,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final statsTokens = StatisticsThemeTokens.of(context);

    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: statsTokens.textSecondary),
            const SizedBox(height: 12),
            Text(
              '아직 분석된 일기가 없어요',
              style: TextStyle(
                color: statsTokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '일기를 작성하면 감정 추이를 볼 수 있어요',
              style: TextStyle(
                color: statsTokens.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateInterval(int dataLength) {
    if (dataLength <= 7) return 1;
    if (dataLength <= 14) return 2;
    if (dataLength <= 30) return 5;
    return 7;
  }
}
