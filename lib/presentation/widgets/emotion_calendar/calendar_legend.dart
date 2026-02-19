import 'package:flutter/material.dart';
import '../../../core/theme/statistics_theme_tokens.dart';

/// 캘린더 범례 위젯
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final statsTokens = StatisticsThemeTokens.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '마음의 정원',
          style: TextStyle(color: statsTokens.textTertiary, fontSize: 10),
        ),
        const SizedBox(width: 8),
        _buildLegendItem('🌱'),
        _buildLegendArrow(statsTokens.textTertiary),
        _buildLegendItem('🌿'),
        _buildLegendArrow(statsTokens.textTertiary),
        _buildLegendItem('🌷'),
        _buildLegendArrow(statsTokens.textTertiary),
        _buildLegendItem('🌸'),
        _buildLegendArrow(statsTokens.textTertiary),
        _buildLegendItem('🌻'),
      ],
    );
  }

  Widget _buildLegendItem(String emoji) {
    return Text(emoji, style: const TextStyle(fontSize: 11));
  }

  Widget _buildLegendArrow(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text('→', style: TextStyle(fontSize: 8, color: color)),
    );
  }
}
