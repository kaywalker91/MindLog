# ui-dark-mode

Dark Theme 최적화 및 UI/UX 디자인 시스템 (`/ui-dark-mode [action]`)

## 목표
- Dark theme first 디자인 구현
- Material 3 (Material You) 활용
- 접근성 표준 준수
- 일관된 디자인 시스템 유지

## 트리거 조건
- `/ui-dark-mode [action]` 명령어
- 새로운 UI 컴포넌트 추가 시
- 테마 관련 버그 수정 시
- 접근성 개선 작업 시

## 핵심 파일

| 파일 | 역할 |
|------|------|
| `lib/core/theme/app_theme.dart` | 메인 테마 정의 |
| `lib/core/theme/app_colors.dart` | 색상 팔레트 |
| `lib/core/theme/app_text_styles.dart` | 타이포그래피 |
| `lib/core/theme/app_spacing.dart` | 간격 시스템 |
| `lib/presentation/widgets/` | 공통 위젯 |

## Actions

### audit-theme
테마 일관성 감사
1. 하드코딩 색상 탐지
2. Theme.of(context) 사용 검사
3. Dark/Light 모드 대응 확인
4. 접근성 대비율 검사

```bash
> /ui-dark-mode audit-theme

테마 감사 결과:
├── 하드코딩 색상: 12건 발견
├── Theme.of 사용: 94%
├── Dark mode 대응: 98%
└── 접근성 대비율: 4.5:1+ (WCAG AA 충족)
```

### migrate-colors
하드코딩 색상 → theme-aware 마이그레이션
1. 하드코딩 색상 위치 식별
2. 적절한 theme 색상 매핑
3. 자동 변환 수행
4. 변경 사항 리포트

```dart
// ❌ Before: 하드코딩
Container(color: Color(0xFF1E1E1E))

// ✅ After: theme-aware
Container(color: Theme.of(context).colorScheme.surface)
```

### add-component [name]
새 디자인 컴포넌트 추가
1. 컴포넌트 템플릿 생성
2. Dark/Light 대응 확인
3. 접근성 속성 추가
4. 문서화

### accessibility-check
접근성 표준 점검
1. 색상 대비율 검사 (WCAG AA/AAA)
2. 터치 타겟 크기 검사 (최소 48x48)
3. Semantics 위젯 사용 검사
4. 스크린 리더 호환성

## Material 3 Color System

### Semantic Colors

```dart
// Primary colors
colorScheme.primary        // 주요 액션, 강조
colorScheme.onPrimary      // primary 위 텍스트/아이콘
colorScheme.primaryContainer  // 부드러운 primary 배경
colorScheme.onPrimaryContainer

// Surface colors
colorScheme.surface        // 카드, 시트 배경
colorScheme.onSurface      // surface 위 텍스트
colorScheme.surfaceVariant // 대체 surface
colorScheme.onSurfaceVariant

// Background
colorScheme.background     // 전체 배경
colorScheme.onBackground   // background 위 텍스트

// Error colors
colorScheme.error          // 에러 상태
colorScheme.onError        // error 위 텍스트
colorScheme.errorContainer // 부드러운 에러 배경

// Outline
colorScheme.outline        // 테두리, 구분선
colorScheme.outlineVariant // 부드러운 구분선
```

### 감정 색상 시스템

```dart
// MindLog 감정별 색상 (Dark mode 최적화)
class EmotionColors {
  // Joy (기쁨) - Warm yellow
  static const joy = Color(0xFFFFD54F);
  static const joyDark = Color(0xFFFFC107);

  // Sadness (슬픔) - Cool blue
  static const sadness = Color(0xFF64B5F6);
  static const sadnessDark = Color(0xFF42A5F5);

  // Anger (분노) - Warm red
  static const anger = Color(0xFFEF5350);
  static const angerDark = Color(0xFFE53935);

  // Fear (불안) - Purple
  static const fear = Color(0xFFAB47BC);
  static const fearDark = Color(0xFF9C27B0);

  // Neutral (중립) - Gray
  static const neutral = Color(0xFF9E9E9E);
  static const neutralDark = Color(0xFF757575);
}
```

## Dark Theme Best Practices

### 배경 계층

```dart
// Dark mode 배경 계층 (Elevation 기반)
// Surface: #121212 (0dp)
// Surface + 1dp: #1E1E1E
// Surface + 2dp: #222222
// Surface + 3dp: #242424
// Surface + 4dp: #272727
// Surface + 6dp: #2C2C2C
// Surface + 8dp: #2D2D2D

// 사용 예시
Container(
  color: ElevationOverlay.applySurfaceTint(
    Theme.of(context).colorScheme.surface,
    Theme.of(context).colorScheme.surfaceTint,
    elevation, // 0, 1, 2, 3, 4, 6, 8
  ),
)
```

### 텍스트 불투명도

```dart
// Dark mode 텍스트 대비
// High emphasis: 87% white
// Medium emphasis: 60% white
// Disabled: 38% white

colorScheme.onSurface.withOpacity(0.87)  // 제목
colorScheme.onSurface.withOpacity(0.60)  // 부제목
colorScheme.onSurface.withOpacity(0.38)  // 비활성
```

### 그림자 vs 표면 색조

```dart
// ❌ Dark mode에서 피해야 할 것
BoxShadow(color: Colors.black.withOpacity(0.3))

// ✅ Dark mode 권장
// 그림자 대신 표면 색조(elevation overlay) 사용
Card(
  elevation: 4, // Material 3가 자동으로 처리
)
```

## 컴포넌트 템플릿

### 감정 카드

```dart
class EmotionCard extends StatelessWidget {
  final String emotion;
  final int sentimentScore;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Emotion icon with semantic color
            Icon(
              _getEmotionIcon(emotion),
              color: EmotionColors.getColor(emotion, context),
              size: 32,
              semanticLabel: '감정: $emotion',
            ),
            const SizedBox(height: 8),
            // Score with high emphasis
            Text(
              '$sentimentScore/10',
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 접근성 체크리스트

- [ ] 색상 대비율 4.5:1 이상 (일반 텍스트)
- [ ] 색상 대비율 3:1 이상 (큰 텍스트/아이콘)
- [ ] 터치 타겟 최소 48x48dp
- [ ] Semantics 위젯 적용
- [ ] 색상만으로 정보 전달 금지 (아이콘/텍스트 병행)

## 출력 형식

```
Dark Mode 감사 결과
===================

📊 테마 현황:
├── 총 UI 파일: 87개
├── Theme.of 사용: 82/87 (94%)
├── 하드코딩 색상: 12건
└── 접근성 대비율: WCAG AA 충족 ✅

🎨 색상 분석:
├── Primary: #6750A4 → ✅
├── Surface: #1C1B1F → ✅
├── 하드코딩 발견:
│   ├── diary_card.dart:45 → Color(0xFF...)
│   ├── emotion_chip.dart:23 → Colors.blue
│   └── ... 10건 더

📋 권장 조치:
1. 12건의 하드코딩 색상 → theme 색상으로 마이그레이션
2. emotion_chip.dart에 Semantics 추가
3. 작은 버튼 터치 타겟 확대 (현재 40x40)

다음 단계:
└── /ui-dark-mode migrate-colors
```

## 연관 스킬
- `/color-migrate` - 색상 마이그레이션
- `/widget-decompose` - 위젯 분해
- `/lint-fix` - 린트 수정

## 주의사항
- Dark mode가 기본이므로 Light mode도 반드시 테스트
- 감정 색상은 앱 아이덴티티이므로 변경 시 팀 협의
- 접근성 기준 미달 시 릴리스 차단
- 하드코딩 색상 추가 금지 (PR 리뷰 체크)

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | ui / design |
| Dependencies | color-migrate |
| Created | 2025-02-03 |
| Updated | 2025-02-03 |
