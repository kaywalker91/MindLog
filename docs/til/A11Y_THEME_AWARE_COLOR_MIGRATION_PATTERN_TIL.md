# Flutter 접근성 색상 마이그레이션 패턴

**분류**: Flutter / Accessibility / Theme
**난이도**: 초급~중급
**예상 소요**: 15분
**최종 업데이트**: 2026-02-27
**연관 태스크**: TASK-A11Y-001~009 (Sprint 1+2)

---

## 배경

MindLog Accessibility Sprint 1+2에서 14개 화면의 하드코딩 색상(`Colors.*`)을 Material 3 `colorScheme` 기반의 theme-aware 색상으로 전환했다. 다크 모드 완전 지원 + 접근성 요구사항(WCAG 2.1 AA) 충족이 목표였다.

---

## 핵심 매핑 테이블

| 하드코딩 (비권장) | theme-aware 대체 | 사용 맥락 |
|----------------|----------------|---------|
| `Colors.black87` | `colorScheme.scrim.withValues(alpha: 0.87)` | 배경 오버레이, 스크림 |
| `Colors.black54` | `colorScheme.shadow` | 반투명 그림자 레이어 |
| `Colors.white` (텍스트/아이콘) | `colorScheme.onSurface` | 표면 위 콘텐츠 색상 |
| `Colors.white` (배경) | `colorScheme.surface` | 카드/시트 배경 |
| `Colors.grey[900]` | `colorScheme.surfaceContainerLowest` | 깊은 배경 레이어 |
| `Colors.grey[600]` | `colorScheme.onSurfaceVariant` | 보조 텍스트, 아이콘 |
| `Colors.grey[300]` | `colorScheme.outlineVariant` | 구분선, 비활성 테두리 |
| `Color.lerp(Colors.white, color, t)` | `Color.lerp(colorScheme.surface, color, t)` | 색상 보간 (히트맵 등) |

---

## 코드 패턴

### Before (하드코딩)
```dart
// fullscreen_image_viewer.dart (Sprint 2 이전)
Container(
  color: Colors.black87,  // ❌ 다크 모드 무관
  child: Icon(Icons.close, color: Colors.white),  // ❌
)
```

### After (theme-aware)
```dart
// fullscreen_image_viewer.dart (Sprint 2 이후)
final colorScheme = Theme.of(context).colorScheme;
Container(
  color: colorScheme.scrim.withValues(alpha: 0.87),  // ✅ 다크 모드 대응
  child: Icon(Icons.close, color: colorScheme.onSurface),  // ✅
)
```

### Color.lerp 변환
```dart
// Before
Color.lerp(Colors.white, AppColors.getSentimentColor(score), intensity)

// After
Color.lerp(colorScheme.surface, AppColors.getSentimentColor(score), intensity)
```

---

## AccessibilityWrapper 패턴

Sprint 1+2에서 14개 화면 전체에 `AccessibilityWrapper`를 적용했다.

```dart
// 모든 Screen 파일에서
import '../../core/accessibility/app_accessibility.dart';

@override
Widget build(BuildContext context) {
  return AccessibilityWrapper(
    screenTitle: '화면 이름',  // 스크린 리더용 제목
    child: Scaffold(
      // ...
    ),
  );
}
```

**Import 경로**: `../../core/accessibility/app_accessibility.dart` (Screen 파일 기준)

---

## Colors.white 맥락 구분 주의사항

`Colors.white`는 맥락에 따라 다른 토큰으로 교체해야 한다:

| 맥락 | 교체 토큰 |
|------|---------|
| 배경색 | `colorScheme.surface` |
| 텍스트/아이콘 색상 | `colorScheme.onSurface` |
| 오버레이 위 텍스트 | `colorScheme.onPrimary` (primary 위) |
| 다이얼로그 배경 | `colorScheme.surface` 또는 `surfaceContainerHigh` |

---

## 적용 완료 화면 (14개)

Sprint 1: diary_list_screen, statistics_screen, calendar_screen, home_screen, settings_screen
Sprint 2: fullscreen_image_viewer, mindcare_welcome_dialog, weekly_insight_guide_dialog, activity_heatmap, diary_item_card + 4개 추가

---

## 교훈

1. **`Colors.white` → `colorScheme.onSurface`가 가장 흔한 교체**이지만, 배경인지 텍스트인지 반드시 확인
2. **`withOpacity()` → `withValues(alpha: ...)`** Flutter 3.x에서 권장 API 변경
3. **ThemeExtension 패턴**이 화면별 라이트/다크 분리에 가장 확장성 높음 (`StatisticsThemeTokens` 참조)

---

## 참조 파일

- `lib/core/theme/app_colors.dart` — AppColors 전역 팔레트
- `lib/core/accessibility/app_accessibility.dart` — AccessibilityWrapper 정의
- `docs/til/COLOR_SYSTEM.md` — 4-팔레트 구조 전체 레퍼런스
- `memory/a11y-backlog.md` — Sprint 3 백로그
