import 'dart:ui';

import 'package:flutter/material.dart';

/// 통계 탭 전용 디자인 토큰
@immutable
class StatisticsThemeTokens extends ThemeExtension<StatisticsThemeTokens> {
  const StatisticsThemeTokens({
    required this.pageBackground,
    required this.cardBackground,
    required this.cardSoftBackground,
    required this.cardBorder,
    required this.cardShadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primaryStrong,
    required this.primarySoft,
    required this.mintAccent,
    required this.coralAccent,
    required this.appBarGradientStart,
    required this.appBarGradientEnd,
    required this.appBarBubble,
    required this.appBarDivider,
    required this.navGradientTop,
    required this.navGradientBottom,
    required this.navBorder,
    required this.navShadow,
    required this.navSelected,
    required this.navUnselected,
    required this.navIndicator,
    required this.chipSelectedBackground,
    required this.chipSelectedForeground,
    required this.chipUnselectedBackground,
    required this.chipUnselectedForeground,
    required this.chartGrid,
    required this.chartTooltipBackground,
    required this.chartTooltipForeground,
    required this.calendarEmptyCell,
    required this.calendarEmptyBorder,
    required this.calendarTodayBackground,
    required this.calendarTodayBorder,
    required this.calendarRecordBorder,
    required this.calendarRecordGlow,
    required this.calendarInactiveOpacity,
    required this.calendarInactiveTextOpacity,
    required this.microMotionMs,
  });

  final Color pageBackground;
  final Color cardBackground;
  final Color cardSoftBackground;
  final Color cardBorder;
  final Color cardShadow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color primaryStrong;
  final Color primarySoft;
  final Color mintAccent;
  final Color coralAccent;
  final Color appBarGradientStart;
  final Color appBarGradientEnd;
  final Color appBarBubble;
  final Color appBarDivider;
  final Color navGradientTop;
  final Color navGradientBottom;
  final Color navBorder;
  final Color navShadow;
  final Color navSelected;
  final Color navUnselected;
  final Color navIndicator;
  final Color chipSelectedBackground;
  final Color chipSelectedForeground;
  final Color chipUnselectedBackground;
  final Color chipUnselectedForeground;
  final Color chartGrid;
  final Color chartTooltipBackground;
  final Color chartTooltipForeground;
  final Color calendarEmptyCell;
  final Color calendarEmptyBorder;
  final Color calendarTodayBackground;
  final Color calendarTodayBorder;
  final Color calendarRecordBorder;
  final Color calendarRecordGlow;
  final double calendarInactiveOpacity;
  final double calendarInactiveTextOpacity;
  final int microMotionMs;

  static const StatisticsThemeTokens light = StatisticsThemeTokens(
    pageBackground: Color(0xFFF8FBFF),
    cardBackground: Color(0xFFFFFFFF),
    cardSoftBackground: Color(0xFFF2F8FC),
    cardBorder: Color(0xFFE8F4FA),
    cardShadow: Color(0xFF1F2A37),
    textPrimary: Color(0xFF1F2A37),
    textSecondary: Color(0xFF4B5F72),
    textTertiary: Color(0xFF617488),
    primaryStrong: Color(0xFF7EC8E3),
    primarySoft: Color(0xFFE8F4FA),
    mintAccent: Color(0xFFA8E6CF),
    coralAccent: Color(0xFFF5A895),
    appBarGradientStart: Color(0xFF7EC8E3),
    appBarGradientEnd: Color(0xFFB8C5E2),
    appBarBubble: Color(0xFFFFFFFF),
    appBarDivider: Color(0xFFFFFFFF),
    navGradientTop: Color(0xFFFFFFFF),
    navGradientBottom: Color(0xFFF2F8FC),
    navBorder: Color(0xFFE8F4FA),
    navShadow: Color(0xFF7EC8E3),
    navSelected: Color(0xFF2C3E50),
    navUnselected: Color(0xFF6B7B8A),
    navIndicator: Color(0xFFEAF4FA),
    chipSelectedBackground: Color(0xFFDCEEF7),
    chipSelectedForeground: Color(0xFF1F2A37),
    chipUnselectedBackground: Color(0xFFF2F8FC),
    chipUnselectedForeground: Color(0xFF4B5F72),
    chartGrid: Color(0xFFD3E2EC),
    chartTooltipBackground: Color(0xFF1F2A37),
    chartTooltipForeground: Color(0xFFF8FBFF),
    calendarEmptyCell: Color(0xFFF0F4F8),
    calendarEmptyBorder: Color(0xFFE0ECF5),
    calendarTodayBackground: Color(0xFFEAF4FA),
    calendarTodayBorder: Color(0xFF7EC8E3),
    calendarRecordBorder: Color(0xFFA8E6CF),
    calendarRecordGlow: Color(0xFFA8E6CF),
    calendarInactiveOpacity: 0.55,
    calendarInactiveTextOpacity: 0.68,
    microMotionMs: 180,
  );

  static const StatisticsThemeTokens dark = StatisticsThemeTokens(
    pageBackground: Color(0xFF0F1A24),
    cardBackground: Color(0xFF152230),
    cardSoftBackground: Color(0xFF1D2E40),
    cardBorder: Color(0xFF2A3F53),
    cardShadow: Color(0xFF000000),
    textPrimary: Color(0xFFEAF4FF),
    textSecondary: Color(0xFFC5D6E4),
    textTertiary: Color(0xFF9FB5C8),
    primaryStrong: Color(0xFF74AFC8),
    primarySoft: Color(0xFF2A4458),
    mintAccent: Color(0xFF9FD6CC),
    coralAccent: Color(0xFFE3A8AE),
    appBarGradientStart: Color(0xFF203547),
    appBarGradientEnd: Color(0xFF39556A),
    appBarBubble: Color(0xFFFFFFFF),
    appBarDivider: Color(0xFFEAF4FF),
    navGradientTop: Color(0xFF152230),
    navGradientBottom: Color(0xFF1D2E40),
    navBorder: Color(0xFF2A3F53),
    navShadow: Color(0xFF74AFC8),
    navSelected: Color(0xFFDCEAF5),
    navUnselected: Color(0xFF9FB5C8),
    navIndicator: Color(0xFF2C455A),
    chipSelectedBackground: Color(0xFF36556C),
    chipSelectedForeground: Color(0xFFEAF4FF),
    chipUnselectedBackground: Color(0xFF1D2E40),
    chipUnselectedForeground: Color(0xFFC5D6E4),
    chartGrid: Color(0xFF3A5367),
    chartTooltipBackground: Color(0xFFEAF4FF),
    chartTooltipForeground: Color(0xFF0F1A24),
    calendarEmptyCell: Color(0xFF182736),
    calendarEmptyBorder: Color(0xFF2A3F53),
    calendarTodayBackground: Color(0xFF274257),
    calendarTodayBorder: Color(0xFF74AFC8),
    calendarRecordBorder: Color(0xFF5A8D83),
    calendarRecordGlow: Color(0xFF9FD6CC),
    calendarInactiveOpacity: 0.62,
    calendarInactiveTextOpacity: 0.72,
    microMotionMs: 180,
  );

  static StatisticsThemeTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<StatisticsThemeTokens>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  StatisticsThemeTokens copyWith({
    Color? pageBackground,
    Color? cardBackground,
    Color? cardSoftBackground,
    Color? cardBorder,
    Color? cardShadow,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primaryStrong,
    Color? primarySoft,
    Color? mintAccent,
    Color? coralAccent,
    Color? appBarGradientStart,
    Color? appBarGradientEnd,
    Color? appBarBubble,
    Color? appBarDivider,
    Color? navGradientTop,
    Color? navGradientBottom,
    Color? navBorder,
    Color? navShadow,
    Color? navSelected,
    Color? navUnselected,
    Color? navIndicator,
    Color? chipSelectedBackground,
    Color? chipSelectedForeground,
    Color? chipUnselectedBackground,
    Color? chipUnselectedForeground,
    Color? chartGrid,
    Color? chartTooltipBackground,
    Color? chartTooltipForeground,
    Color? calendarEmptyCell,
    Color? calendarEmptyBorder,
    Color? calendarTodayBackground,
    Color? calendarTodayBorder,
    Color? calendarRecordBorder,
    Color? calendarRecordGlow,
    double? calendarInactiveOpacity,
    double? calendarInactiveTextOpacity,
    int? microMotionMs,
  }) {
    return StatisticsThemeTokens(
      pageBackground: pageBackground ?? this.pageBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardSoftBackground: cardSoftBackground ?? this.cardSoftBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      primarySoft: primarySoft ?? this.primarySoft,
      mintAccent: mintAccent ?? this.mintAccent,
      coralAccent: coralAccent ?? this.coralAccent,
      appBarGradientStart: appBarGradientStart ?? this.appBarGradientStart,
      appBarGradientEnd: appBarGradientEnd ?? this.appBarGradientEnd,
      appBarBubble: appBarBubble ?? this.appBarBubble,
      appBarDivider: appBarDivider ?? this.appBarDivider,
      navGradientTop: navGradientTop ?? this.navGradientTop,
      navGradientBottom: navGradientBottom ?? this.navGradientBottom,
      navBorder: navBorder ?? this.navBorder,
      navShadow: navShadow ?? this.navShadow,
      navSelected: navSelected ?? this.navSelected,
      navUnselected: navUnselected ?? this.navUnselected,
      navIndicator: navIndicator ?? this.navIndicator,
      chipSelectedBackground:
          chipSelectedBackground ?? this.chipSelectedBackground,
      chipSelectedForeground:
          chipSelectedForeground ?? this.chipSelectedForeground,
      chipUnselectedBackground:
          chipUnselectedBackground ?? this.chipUnselectedBackground,
      chipUnselectedForeground:
          chipUnselectedForeground ?? this.chipUnselectedForeground,
      chartGrid: chartGrid ?? this.chartGrid,
      chartTooltipBackground:
          chartTooltipBackground ?? this.chartTooltipBackground,
      chartTooltipForeground:
          chartTooltipForeground ?? this.chartTooltipForeground,
      calendarEmptyCell: calendarEmptyCell ?? this.calendarEmptyCell,
      calendarEmptyBorder: calendarEmptyBorder ?? this.calendarEmptyBorder,
      calendarTodayBackground:
          calendarTodayBackground ?? this.calendarTodayBackground,
      calendarTodayBorder: calendarTodayBorder ?? this.calendarTodayBorder,
      calendarRecordBorder: calendarRecordBorder ?? this.calendarRecordBorder,
      calendarRecordGlow: calendarRecordGlow ?? this.calendarRecordGlow,
      calendarInactiveOpacity:
          calendarInactiveOpacity ?? this.calendarInactiveOpacity,
      calendarInactiveTextOpacity:
          calendarInactiveTextOpacity ?? this.calendarInactiveTextOpacity,
      microMotionMs: microMotionMs ?? this.microMotionMs,
    );
  }

  @override
  StatisticsThemeTokens lerp(
    ThemeExtension<StatisticsThemeTokens>? other,
    double t,
  ) {
    if (other is! StatisticsThemeTokens) {
      return this;
    }

    return StatisticsThemeTokens(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardSoftBackground: Color.lerp(
        cardSoftBackground,
        other.cardSoftBackground,
        t,
      )!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      primaryStrong: Color.lerp(primaryStrong, other.primaryStrong, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      mintAccent: Color.lerp(mintAccent, other.mintAccent, t)!,
      coralAccent: Color.lerp(coralAccent, other.coralAccent, t)!,
      appBarGradientStart: Color.lerp(
        appBarGradientStart,
        other.appBarGradientStart,
        t,
      )!,
      appBarGradientEnd: Color.lerp(
        appBarGradientEnd,
        other.appBarGradientEnd,
        t,
      )!,
      appBarBubble: Color.lerp(appBarBubble, other.appBarBubble, t)!,
      appBarDivider: Color.lerp(appBarDivider, other.appBarDivider, t)!,
      navGradientTop: Color.lerp(navGradientTop, other.navGradientTop, t)!,
      navGradientBottom: Color.lerp(
        navGradientBottom,
        other.navGradientBottom,
        t,
      )!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      navShadow: Color.lerp(navShadow, other.navShadow, t)!,
      navSelected: Color.lerp(navSelected, other.navSelected, t)!,
      navUnselected: Color.lerp(navUnselected, other.navUnselected, t)!,
      navIndicator: Color.lerp(navIndicator, other.navIndicator, t)!,
      chipSelectedBackground: Color.lerp(
        chipSelectedBackground,
        other.chipSelectedBackground,
        t,
      )!,
      chipSelectedForeground: Color.lerp(
        chipSelectedForeground,
        other.chipSelectedForeground,
        t,
      )!,
      chipUnselectedBackground: Color.lerp(
        chipUnselectedBackground,
        other.chipUnselectedBackground,
        t,
      )!,
      chipUnselectedForeground: Color.lerp(
        chipUnselectedForeground,
        other.chipUnselectedForeground,
        t,
      )!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      chartTooltipBackground: Color.lerp(
        chartTooltipBackground,
        other.chartTooltipBackground,
        t,
      )!,
      chartTooltipForeground: Color.lerp(
        chartTooltipForeground,
        other.chartTooltipForeground,
        t,
      )!,
      calendarEmptyCell: Color.lerp(
        calendarEmptyCell,
        other.calendarEmptyCell,
        t,
      )!,
      calendarEmptyBorder: Color.lerp(
        calendarEmptyBorder,
        other.calendarEmptyBorder,
        t,
      )!,
      calendarTodayBackground: Color.lerp(
        calendarTodayBackground,
        other.calendarTodayBackground,
        t,
      )!,
      calendarTodayBorder: Color.lerp(
        calendarTodayBorder,
        other.calendarTodayBorder,
        t,
      )!,
      calendarRecordBorder: Color.lerp(
        calendarRecordBorder,
        other.calendarRecordBorder,
        t,
      )!,
      calendarRecordGlow: Color.lerp(
        calendarRecordGlow,
        other.calendarRecordGlow,
        t,
      )!,
      calendarInactiveOpacity: lerpDouble(
        calendarInactiveOpacity,
        other.calendarInactiveOpacity,
        t,
      )!,
      calendarInactiveTextOpacity: lerpDouble(
        calendarInactiveTextOpacity,
        other.calendarInactiveTextOpacity,
        t,
      )!,
      microMotionMs: lerpDouble(
        microMotionMs.toDouble(),
        other.microMotionMs.toDouble(),
        t,
      )!.round(),
    );
  }
}
