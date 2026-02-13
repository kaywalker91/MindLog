import 'package:flutter/material.dart';

/// Cheer Me 모달 전용 힐링 팔레트 모드
enum HealingPaletteMode { mutedTeal, pastelComfort }

/// 치유/응원 맥락에 맞춘 Material 3 ColorScheme 세트
class HealingColorSchemes {
  HealingColorSchemes._();

  // Palette reference colors (Material 3에서 background 역할은 surface 계열로 매핑)
  static const Color mutedTealBackground = Color(0xFFF8F5F1);
  static const Color pastelComfortBackground = Color(0xFFFFF8F4);

  /// Option A: Muted Teal + Warm Neutral
  static const ColorScheme mutedTeal = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2E7D86),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCFE7EA),
    onPrimaryContainer: Color(0xFF0E2A2E),
    secondary: Color(0xFFA5673A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF3E2D6),
    onSecondaryContainer: Color(0xFF3C2415),
    tertiary: Color(0xFF7A8F78),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDDE8DA),
    onTertiaryContainer: Color(0xFF1F2C1D),
    error: Color(0xFFB84C4C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF8DCDC),
    onErrorContainer: Color(0xFF3D1111),
    surface: Color(0xFFFFFDFC),
    onSurface: Color(0xFF1F2426),
    surfaceContainerHighest: Color(0xFFE9E3DD),
    onSurfaceVariant: Color(0xFF5E6569),
    outline: Color(0xFF8B9296),
    outlineVariant: Color(0xFFC8CFD2),
    shadow: Color(0xFF000000),
    scrim: Color(0x66000000),
    inverseSurface: Color(0xFF2E3133),
    onInverseSurface: Color(0xFFF1F1F1),
    inversePrimary: Color(0xFF8AC5CD),
    surfaceTint: Color(0xFF2E7D86),
  );

  /// Option B: Pastel Comfort
  static const ColorScheme pastelComfort = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF66AFA8),
    onPrimary: Color(0xFF0E312E),
    primaryContainer: Color(0xFFDDF1EE),
    onPrimaryContainer: Color(0xFF113430),
    secondary: Color(0xFFD79680),
    onSecondary: Color(0xFF40251B),
    secondaryContainer: Color(0xFFF9E5DD),
    onSecondaryContainer: Color(0xFF4A2C20),
    tertiary: Color(0xFFBFAF7A),
    onTertiary: Color(0xFF2E2A15),
    tertiaryContainer: Color(0xFFF2EBCF),
    onTertiaryContainer: Color(0xFF3B351C),
    error: Color(0xFFB65050),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF8DCDC),
    onErrorContainer: Color(0xFF3E1010),
    surface: Color(0xFFFFFCFA),
    onSurface: Color(0xFF2A2623),
    surfaceContainerHighest: Color(0xFFF0E7E2),
    onSurfaceVariant: Color(0xFF6C6560),
    outline: Color(0xFFA49B95),
    outlineVariant: Color(0xFFD6CCC6),
    shadow: Color(0xFF000000),
    scrim: Color(0x66000000),
    inverseSurface: Color(0xFF312E2B),
    onInverseSurface: Color(0xFFF5EFEA),
    inversePrimary: Color(0xFF9ED5CF),
    surfaceTint: Color(0xFF66AFA8),
  );

  static ColorScheme resolve(HealingPaletteMode mode) {
    switch (mode) {
      case HealingPaletteMode.mutedTeal:
        return mutedTeal;
      case HealingPaletteMode.pastelComfort:
        return pastelComfort;
    }
  }
}
