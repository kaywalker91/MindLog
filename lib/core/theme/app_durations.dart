/// UI 애니메이션/트랜지션 공통 Duration 상수 (Material 3 기준)
class AppDurations {
  AppDurations._();

  /// 빠른 응답 (버튼 피드백, 도트 애니메이션)
  static const fast = Duration(milliseconds: 150);

  /// 표준 전환 (카드 展開, 크로스페이드, 페이지 전환)
  static const normal = Duration(milliseconds: 250);

  /// 느린 강조 (전체 레이아웃 전환, 모달 등장)
  static const slow = Duration(milliseconds: 400);
}
