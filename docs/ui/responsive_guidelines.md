# MindLog 반응형 UI 가이드라인

이 문서는 MindLog 앱의 모든 화면에서 일관된 반응형 UI를 구현하기 위한 가이드라인입니다.

---

## 1. 디바이스 브레이크포인트

| 카테고리 | 화면 너비 | 대표 디바이스 | 특징 |
|---------|----------|--------------|------|
| **Compact** | 320-359dp | iPhone SE, 구형 폰 | 최소 지원 해상도 |
| **Standard** | 360-411dp | 일반 스마트폰 | 기본 타겟 |
| **Large** | 412-599dp | 대형 폰, 폴더블 | 넓은 여백 활용 |
| **Tablet** | 600dp+ | iPad, 태블릿 | 2열 레이아웃 고려 |

### 브레이크포인트 감지 방법

```dart
// 화면 너비 가져오기
final screenWidth = MediaQuery.of(context).size.width;

// 브레이크포인트 확인
bool isCompact = screenWidth < 360;
bool isStandard = screenWidth >= 360 && screenWidth < 412;
bool isLarge = screenWidth >= 412 && screenWidth < 600;
bool isTablet = screenWidth >= 600;
```

---

## 2. 레이아웃 원칙

### 2.1 Row/Column 안전 규칙

#### DO (권장)

```dart
// Row에서 최소 하나는 Expanded/Flexible 사용
Row(
  children: [
    Expanded(
      child: Text('긴 텍스트...', overflow: TextOverflow.ellipsis),
    ),
    Icon(Icons.chevron_right),
  ],
)

// 복잡한 Row는 Column으로 분리
Column(
  children: [
    Row(children: [/* 제목 + 배지 */]),
    Row(children: [/* 필터 칩들 */]),
  ],
)
```

#### DON'T (피해야 할 패턴)

```dart
// Row 안에 고정 크기 위젯만 사용 - Overflow 위험!
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(children: [Text('제목'), Container(...)]),  // 고정
    Row(children: [Chip('A'), Chip('B'), Chip('C')]),  // 고정
  ],
)
```

### 2.2 여백 및 패딩 기준

| 화면 크기 | 수평 패딩 | 수직 패딩 | 카드 간격 |
|----------|----------|----------|----------|
| Compact | 12dp | 8dp | 8dp |
| Standard | 16dp | 12dp | 12dp |
| Large+ | 20dp | 16dp | 16dp |

```dart
// 반응형 패딩 적용 예시
EdgeInsets getScreenPadding(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 360) {
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  } else if (width < 412) {
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  } else {
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  }
}
```

---

## 3. 텍스트 처리

### 3.1 말줄임(Ellipsis) 규칙

| 텍스트 유형 | maxLines | overflow |
|------------|----------|----------|
| 제목 (카드, 섹션) | 1 | ellipsis |
| 부제목, 설명 | 2 | ellipsis |
| 본문, 내용 | 상황에 따라 | ellipsis 또는 fade |
| 버튼 텍스트 | 1 | ellipsis |

```dart
// 제목 스타일
Text(
  '긴 제목 텍스트...',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)

// 부제목 스타일
Text(
  '설명 텍스트...',
  style: TextStyle(fontSize: 14),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

### 3.2 폰트 스케일링 대응

시스템 폰트 크기 설정에 대응하기 위해 `textScaleFactor`를 고려합니다.

```dart
// 현재 텍스트 스케일 확인
final textScale = MediaQuery.textScaleFactorOf(context);

// 최대 스케일 제한 (1.3x 권장)
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(textScale.clamp(0.8, 1.3)),
  ),
  child: child,
)
```

---

## 4. 컴포넌트 가이드

### 4.1 카드

- **최소 너비**: 280dp
- **내부 콘텐츠**: Flexible/Expanded 적용
- **패딩**: 16dp (Compact에서 12dp)

```dart
Container(
  constraints: const BoxConstraints(minWidth: 280),
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 헤더: Row + Expanded
      Row(
        children: [
          Expanded(child: Text('제목', overflow: TextOverflow.ellipsis)),
          Icon(Icons.more_vert),
        ],
      ),
      // 콘텐츠
    ],
  ),
)
```

### 4.2 버튼/칩

- **최소 터치 영역**: 44x44dp (접근성 기준)
- **칩 패딩**: horizontal 8dp, vertical 4dp (좁은 화면용)
- **텍스트**: overflow 처리 필수

```dart
// 터치 영역 보장
GestureDetector(
  behavior: HitTestBehavior.opaque,
  child: Container(
    constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Text('칩'),
  ),
)
```

### 4.3 히트맵/차트

- **LayoutBuilder** 사용하여 가용 너비 계산
- **최소 너비 미달 시** 수평 스크롤 허용

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final availableWidth = constraints.maxWidth;
    final minWidth = 280.0;

    if (availableWidth < minWidth) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: minWidth,
          child: HeatmapWidget(),
        ),
      );
    }

    return HeatmapWidget();
  },
)
```

---

## 5. 가로 스크롤 사용 기준

### 스크롤 허용

- 데이터 테이블 (열이 4개 이상)
- 날짜 기반 히트맵/차트
- 가로 탭/칩 리스트 (5개 이상)

### 스크롤 지양

- 주요 액션 버튼
- 제목 + 필터 조합
- 카드 헤더

---

## 6. 테스트 체크리스트

### 개발 중 확인 사항

- [ ] 320dp (iPhone SE) 에뮬레이터에서 overflow 에러 없음
- [ ] 360dp (일반 폰) 에뮬레이터에서 정상 렌더링
- [ ] 412dp+ (대형 폰) 에뮬레이터에서 적절한 여백
- [ ] 세로/가로 회전 시 레이아웃 유지
- [ ] 시스템 폰트 크기 "Large" 적용 시 콘텐츠 잘림 없음

### 테스트 명령어

```bash
# 정적 분석
flutter analyze

# 위젯 테스트 실행
flutter test

# 골든 테스트 업데이트 (시각적 회귀 테스트)
flutter test --update-goldens
```

### 에뮬레이터 설정

| 테스트 목적 | 디바이스 | 해상도 |
|-----------|---------|--------|
| 최소 지원 | iPhone SE (2nd) | 375x667 @ 2x |
| 폴더블 접힌 상태 | Galaxy Fold | 280dp 너비 |
| 기본 타겟 | Pixel 4 | 392x851 |
| 태블릿 | iPad Pro 11" | 834x1194 |

---

## 7. 일반적인 Overflow 해결 패턴

### 문제 1: Row 안 텍스트 overflow

```dart
// Before (문제)
Row(children: [Text('긴 텍스트'), Icon(Icons.arrow)])

// After (해결)
Row(children: [
  Expanded(child: Text('긴 텍스트', overflow: TextOverflow.ellipsis)),
  Icon(Icons.arrow),
])
```

### 문제 2: Row 안 Row overflow

```dart
// Before (문제)
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Row(children: [Text('A'), Text('B')]),
    Row(children: [Chip('1'), Chip('2')]),
  ],
)

// After (해결) - Column 분리
Column(children: [
  Row(children: [Expanded(child: Text('A')), Text('B')]),
  Align(
    alignment: Alignment.centerRight,
    child: Row(children: [Chip('1'), Chip('2')]),
  ),
])
```

### 문제 3: 동적 콘텐츠 overflow

```dart
// Wrap 사용 (자동 줄바꿈)
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: chips.map((chip) => Chip(label: Text(chip))).toList(),
)
```

---

## 8. 참고 자료

- [Flutter Layout Constraints](https://docs.flutter.dev/ui/layout/constraints)
- [Material Design Responsive Layout](https://m3.material.io/foundations/layout/understanding-layout/overview)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
