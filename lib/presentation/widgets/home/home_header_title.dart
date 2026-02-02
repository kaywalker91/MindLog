import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 홈 화면 헤더 타이틀 위젯
/// 레이아웃: [로고] MindLog · 좋은 아침이에요
class HomeHeaderTitle extends StatelessWidget {
  const HomeHeaderTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 로고
        ClipOval(
          child: Image.asset(
            'assets/icons/icon_mind_log.png',
            width: 24,
            height: 24,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        // 앱 이름
        const Text(
          'MindLog',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        // 구분자
        Text(
          ' · ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary.withValues(alpha: 0.7),
          ),
        ),
        // 인사말
        Flexible(
          child: Text(
            greeting,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 시간대별 인사말 반환
  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 0 && hour < 6) {
      return '늦은 밤이에요';
    } else if (hour >= 6 && hour < 12) {
      return '좋은 아침이에요';
    } else if (hour >= 12 && hour < 18) {
      return '좋은 오후예요';
    } else {
      return '좋은 저녁이에요';
    }
  }
}
