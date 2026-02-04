import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 캘린더 범례 위젯
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
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
}
