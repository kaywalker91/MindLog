import 'package:flutter/material.dart';

/// 스플래시스크린 테마 설정
class SplashTheme {
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.white;
  
  /// 스플래시스크린 화면 설정
  static ThemeData createSplashTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
    );
  }
}
