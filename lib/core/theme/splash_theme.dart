import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 스플래시스크린 테마 설정
class SplashTheme {
  static const Color primaryColor = AppColors.statsPrimary;
  static const Color secondaryColor = AppColors.statsSecondary;
  static const Color backgroundColor = AppColors.statsBackground;
  static const Color textColor = AppColors.statsTextPrimary;
  static const Color secondaryTextColor = AppColors.statsTextSecondary;
  
  /// 스플래시스크린 화면 설정
  static ThemeData createSplashTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        onSurface: textColor,
      ),
    );
  }
}
