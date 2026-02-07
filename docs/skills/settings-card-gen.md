# settings-card-gen

좌측 accent 스트라이프 + 카테고리 칩 셀렉터를 가진 설정 카드 위젯 생성 스킬

## 목표
- 브랜드 컬러로 구분되는 accent 설정 카드 자동 생성
- 카테고리 칩 가로 스크롤 + 세로 목록 UX 패턴 적용
- 기존 `SettingsCard` 호환 + accent 확장

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/settings-card-gen [type] [categories]` 명령어
- "설정 카드에 accent 추가해줘" 요청
- 알림/설정 섹션에 브랜드 구분이 필요할 때

## 참조 템플릿

### Accent Card — `_AccentSettingsCard`
참조: `lib/presentation/widgets/settings/notification_section.dart`

```dart
class _AccentSettingsCard extends StatelessWidget {
  final Color accentColor;
  final List<Widget> children;

  const _AccentSettingsCard({
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 좌측 accent 스트라이프 (4px)
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // 본문 영역
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Category Chip Selector
참조: `lib/presentation/widgets/self_encouragement/message_input_dialog.dart`

```dart
// 카테고리 칩 가로 스크롤
SizedBox(
  height: 36,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    itemCount: categories.length,
    separatorBuilder: (_, _) => const SizedBox(width: 8),
    itemBuilder: (_, index) {
      final category = categories[index];
      final isSelected = _selectedCategory == category;

      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedCategory = category);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.15)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(category.icon, size: 14,
                color: isSelected ? accentColor : colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(category.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? accentColor : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                )),
            ],
          ),
        ),
      );
    },
  ),
),
```

## 프로세스

### Step 1: 요구사항 파악
```
1. 카드 유형 결정: accent-only / accent+categories / accent+toggle
2. accent 컬러 확인 (AppColors 상수 또는 신규)
3. 카테고리 enum 존재 여부 확인 → 없으면 /notification-enum-gen 선행
4. 자식 위젯 구성 결정 (토글, 시간 선택, 프리셋 목록 등)
```

### Step 2: Accent Card 생성
```
1. _AccentSettingsCard 위젯 생성 (또는 기존 것 재사용)
2. accentColor 파라미터 바인딩
3. IntrinsicHeight + Row(stretch) + Container(4px) 패턴 적용
4. 카드 내부 children 배치
```

### Step 3: Category Chip Selector 생성 (선택)
```
1. 카테고리 enum.values → 칩 리스트 매핑
2. 가로 스크롤 ListView.separated (height: 36)
3. AnimatedContainer (150ms) + accent 컬러 하이라이트
4. GestureDetector + HapticFeedback.selectionClick()
5. 선택 상태 관리 (_selectedCategory)
```

### Step 4: 아이템 리스트 생성 (선택)
```
1. 카테고리별 아이템 리스트 세로 배치
2. 선택 시 accent 보더 + 배경색 변경
3. GestureDetector + 콜백 연결
```

## 출력 형식

```
✅ settings-card-gen 완료

생성된 파일:
├── lib/presentation/widgets/settings/{feature}_card.dart
└── (optional) test/presentation/widgets/settings/{feature}_card_test.dart

위젯 구성:
- _AccentSettingsCard (accentColor: AppColors.{feature}Accent)
  ├── Title + Subtitle
  ├── Category Chip Selector ({N}개)
  └── Item List (카테고리별)

다음 단계:
└── 설정 섹션에 import + 배치
```

## 네이밍 규칙

| 항목 | 형식 | 예시 |
|------|------|------|
| 카드 위젯 | `_Accent{Feature}Card` | `_AccentCheerMeCard` |
| accent 컬러 | `AppColors.{feature}Accent` | `AppColors.cheerMeAccent` |
| 카테고리 enum | `_{Feature}Category` | `_PresetCategory` |
| 선택 상태 | `_selected{Feature}Category` | `_selectedPresetCategory` |

## 사용 예시

```
> "/settings-card-gen accent cheerme"

1. 대상: Cheer Me 설정 카드
2. accent: AppColors.cheerMeAccent (#FFA726)
3. _AccentSettingsCard 생성 + 토글/시간 자식 위젯
4. 완료

> "/settings-card-gen categories mindcare 8"

1. 대상: 마음케어 카테고리 선택 카드
2. accent: AppColors.mindcareAccent (#26A69A)
3. MindcareCategory 8개 칩 셀렉터 + 메시지 리스트
4. 완료
```

## 연관 스킬
- `/notification-enum-gen` - 카테고리 enum 선행 생성
- `/widget-decompose` - 대형 위젯 분해 후 카드 추출
- `/color-migrate` - 하드코딩 컬러 → accent 상수 전환

## 주의사항
- `IntrinsicHeight`는 비용이 있는 위젯 — 리스트 내 반복 사용 시 성능 주의
- accent 스트라이프 너비는 4px 고정 (Material Design 가이드라인)
- 카테고리 칩은 6개 이하일 때 최적 (초과 시 스크롤 힌트 필요)
- `separatorBuilder`에서 `(_, _)` 사용 (Dart 3+ wildcard lint)
- HapticFeedback은 iOS/Android 모두 지원 확인 필수

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P2 |
| Category | quality |
| Dependencies | /notification-enum-gen (카테고리 사용 시) |
| Created | 2026-02-06 |
| Updated | 2026-02-06 |
