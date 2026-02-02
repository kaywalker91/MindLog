import 'package:flutter/material.dart';

/// 홈 화면 헤더 타이틀 위젯
/// 레이아웃: 😊 MindLog (좌측 정렬, 흰색)
class HomeHeaderTitle extends StatelessWidget {
  const HomeHeaderTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '😊',
          style: TextStyle(fontSize: 22),
        ),
        SizedBox(width: 8),
        Text(
          'MindLog',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
