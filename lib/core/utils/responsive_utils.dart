import 'package:flutter/material.dart';

/// 반응형 디자인 유틸리티
class ResponsiveUtils {
  ResponsiveUtils._();

  /// 시스템 네비게이션 바를 고려한 스크롤 패딩
  ///
  /// [horizontal] 좌우 패딩 (기본 20)
  /// [top] 상단 패딩 (기본 20)
  /// [bottomExtra] 하단 추가 여유 공간 (기본 24)
  static EdgeInsets scrollPadding(
    BuildContext context, {
    double horizontal = 20,
    double top = 20,
    double bottomExtra = 24,
  }) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return EdgeInsets.only(
      left: horizontal,
      right: horizontal,
      top: top,
      bottom: top + bottomPadding + bottomExtra,
    );
  }

  /// 하단 시스템 네비게이션 바 높이 + 여유 공간
  static double bottomSafeAreaPadding(
    BuildContext context, {
    double extra = 24,
  }) {
    return MediaQuery.of(context).padding.bottom + extra;
  }

  /// 화면이 태블릿 크기인지 확인 (shortest side >= 600dp)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  /// 화면이 가로 모드인지 확인
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// 화면 너비에 따른 콘텐츠 최대 너비 반환
  /// 태블릿에서는 너무 넓어지지 않도록 제한
  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return 600; // 태블릿에서 최대 너비 제한
    }
    return width;
  }

  /// 화면 크기에 따른 그리드 열 개수
  static int gridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  /// 반응형 수평 패딩
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) return 40;
    if (width >= 600) return 32;
    return 20;
  }
}
