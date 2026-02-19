# /responsive-overflow-fix - Column 오버플로우 반응형 변환

## Purpose
`Column` 위젯의 bottom overflow 에러를 반응형 UI 패턴으로 자동 변환합니다.

## Usage
```
/responsive-overflow-fix [file-path] [--dry-run] [--compact-threshold 500]
```

## Arguments
- `file-path` - 수정할 파일 경로 (필수)
- `--dry-run` - 실제 변경 없이 제안만 출력
- `--compact-threshold` - compact 모드 전환 기준 높이 (기본: 500px)

## Pattern

### Before (오버플로우 발생)
```dart
return Center(
  child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 고정 크기 요소들...
      ],
    ),
  ),
);
```

### After (반응형)
```dart
return LayoutBuilder(
  builder: (context, constraints) {
    final isCompact = constraints.maxHeight < 500;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // isCompact 기반 조건부 크기 조절...
              ],
            ),
          ),
        ),
      ),
    );
  },
);
```

## Execution Flow

### Phase 1: 분석
1. 파일 읽기 및 Column 위젯 탐지
2. 오버플로우 가능성 평가 (고정 크기 요소 수, SizedBox 합계)
3. 현재 래핑 구조 확인

### Phase 2: 변환 (--dry-run이 아닌 경우)
1. `LayoutBuilder` 래핑 추가
2. `SingleChildScrollView` + `ConstrainedBox` 삽입
3. `const` → 동적 값 변환 (패딩, 간격)
4. `isCompact` 조건 변수 추가
5. 하위 위젯에 `isCompact` 파라미터 전파 (필요시)

### Phase 3: 검증
1. `flutter analyze` 실행
2. 변경 사항 요약 출력

## Compact 모드 변환 가이드

| 요소 | 기본값 | Compact 값 |
|-----|-------|-----------|
| 외부 패딩 | 32px | 16px |
| 아이콘 크기 | 64px | 48px |
| 주요 간격 | 24px | 16px |
| 보조 간격 | 8px | 4px |
| 버튼 상하 간격 | 32px | 20px |

## Example
```bash
# 분석만 수행
/responsive-overflow-fix lib/presentation/widgets/empty_state.dart --dry-run

# 변환 적용
/responsive-overflow-fix lib/presentation/widgets/empty_state.dart

# 커스텀 임계값
/responsive-overflow-fix lib/presentation/widgets/compact_view.dart --compact-threshold 400
```

## Related
- MEMORY.md > 반응형 오버플로우 해결 패턴
- `/widget-decompose` - 대형 위젯 분해 시 함께 사용
