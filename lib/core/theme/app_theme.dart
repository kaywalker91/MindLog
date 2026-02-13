import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'healing_color_schemes.dart';

/// 앱 전체 테마 유틸리티
class AppTheme {
  AppTheme._();

  // 기본 하늘색 테마 색상 (AppColors.statsPrimary와 동일)
  static const Color primaryColor = Color(0xFF7EC8E3);
  static const Color primaryDark = Color(0xFF3A7BC8);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFFFFFFF); // Colors.white 대체
  static const Color surfaceColor = Color(0xFFFFFFFF); // 명시적 surface 색상
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF666666);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF4CAF50);

  // Dark theme colors
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color onDarkSurface = Color(0xFFFFFFFF);

  // Cheer Me 모달 기본 팔레트 (1차 범위: 모달 한정)
  static const HealingPaletteMode defaultHealingPaletteMode =
      HealingPaletteMode.mutedTeal;

  /// 힐링 모달 전용 팔레트 색상 반환
  static ColorScheme healingColorScheme({
    HealingPaletteMode mode = defaultHealingPaletteMode,
  }) {
    return HealingColorSchemes.resolve(mode);
  }

  /// 라이트 테마
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: onDarkSurface, // 하늘색 배경에 흰 텍스트
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0x00000000), // Colors.transparent 대체
          statusBarIconBrightness: Brightness.light, // 하늘색 배경에 밝은 아이콘
          statusBarBrightness: Brightness.dark, // iOS용
        ),
      ),
      cardTheme: const CardThemeData(
        color: backgroundColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onDarkSurface, // 버튼 텍스트 흰색
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(color: textColor, fontSize: 14),
        bodySmall: TextStyle(color: secondaryTextColor, fontSize: 12),
      ),
    );
  }

  /// 다크 테마
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: onDarkSurface,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Color(0x00000000), // Colors.transparent 대체
          statusBarIconBrightness: Brightness.light, // 어두운 배경에 밝은 아이콘
          statusBarBrightness: Brightness.dark, // iOS용
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onDarkSurface,
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
