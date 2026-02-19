# notification-enum-gen

알림/메시지 풀을 enum 기반 카테고리 구조로 변환하는 스킬

## 목표
- 평탄한(flat) 메시지 리스트를 enum 카테고리별 Map 구조로 재구조화
- 기존 통합 리스트 호환성 유지 (spread 기반 통합 getter)
- 카테고리별 선택 API 자동 생성

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/notification-enum-gen [feature]` 명령어
- "메시지 풀 카테고리화해줘" 요청
- 알림 메시지 리스트가 20개 이상일 때 구조화 제안

## 참조 템플릿
참조: `lib/core/constants/notification_messages.dart` — `MindcareCategory`

```dart
/// 카테고리 enum 정의
enum ExampleCategory {
  categoryA('카테고리 A', Icons.icon_a),
  categoryB('카테고리 B', Icons.icon_b);

  const ExampleCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// 카테고리별 메시지 리스트 (private)
const List<String> _categoryAMessages = [
  '메시지 1',
  '메시지 2',
];

const List<String> _categoryBMessages = [
  '메시지 3',
  '메시지 4',
];

/// 카테고리 → 메시지 Map
static final Map<ExampleCategory, List<String>> _messagesByCategory = {
  ExampleCategory.categoryA: _categoryAMessages,
  ExampleCategory.categoryB: _categoryBMessages,
};

/// 통합 리스트 (하위 호환)
static final List<String> _allMessages = [
  ..._categoryAMessages,
  ..._categoryBMessages,
];

/// 카테고리별 선택 API
static String getMessageByCategory(ExampleCategory category) {
  final messages = _messagesByCategory[category]!;
  return messages[_random.nextInt(messages.length)];
}

/// 통합 선택 API (기존 호환)
static String getMessage() {
  return _allMessages[_random.nextInt(_allMessages.length)];
}
```

## 프로세스

### Step 1: 대상 분석
```
1. 대상 메시지 리스트 파일 읽기
2. 현재 메시지 수 확인
3. 기존 소비자(consumer) 파악 — grep으로 해당 리스트 참조처 탐색
4. 카테고리 후보 제안
```

### Step 2: enum 설계
```
1. 카테고리명 결정 (PascalCase enum, camelCase values)
2. 각 카테고리에 label(한국어) + icon(IconData) 속성
3. 메시지를 카테고리별로 분류 (5-8개/카테고리 권장)
4. 사용자 확인 후 진행
```

### Step 3: 코드 생성
```
1. enum 정의 생성
2. 카테고리별 private const 리스트 생성
3. Map<Enum, List<String>> 생성
4. 통합 static final 리스트 생성 (spread)
5. 카테고리별 + 통합 선택 API 생성
```

### Step 4: 하위 호환 검증
```
1. 기존 통합 리스트 참조처가 동일하게 동작하는지 확인
2. const → static final 전환 시 컴파일 에러 확인
3. 테스트 실행
```

## 출력 형식

```
✅ notification-enum-gen 완료

변경된 파일:
├── lib/core/constants/{feature}_messages.dart  (enum + 카테고리 Map)
└── test/core/constants/{feature}_messages_test.dart  (카테고리 검증)

생성 요약:
- enum: {EnumName} ({N}개 카테고리)
- 메시지: {M}개 (카테고리당 {avg}개 평균)
- API: get{Feature}ByCategory() + get{Feature}()

다음 단계:
└── UI에서 카테고리 칩 셀렉터 적용 → /settings-card-gen
```

## 네이밍 규칙

| 항목 | 형식 | 예시 |
|------|------|------|
| enum 이름 | `{Feature}Category` | `MindcareCategory` |
| 카테고리 값 | `camelCase` | `behavioralActivation` |
| 카테고리별 리스트 | `_{camelCase}Messages` | `_mindfulnessMessages` |
| Map 변수 | `_{feature}ByCategory` | `_mindcareBodiesByCategory` |
| 통합 리스트 | `_{feature}All` | `_mindcareBodies` |
| 선택 API | `get{Feature}ByCategory()` | `getMindcareMessageByCategory()` |

## 사용 예시

```
> "/notification-enum-gen mindcare"

1. notification_messages.dart 분석: _mindcareBodies 32개 메시지
2. 카테고리 제안: 8개 (behavioralActivation, mindfulness, ...)
3. 사용자 승인 → enum + Map + API 생성
4. 기존 _mindcareBodies 통합 리스트 유지 (spread)
5. 테스트 실행 → 완료
```

## 연관 스킬
- `/settings-card-gen` - 카테고리 칩 UI 생성
- `/test-unit-gen` - 생성된 enum/API 테스트

## 주의사항
- `const List` → `static final List` 전환 필수 (spread 사용 시)
- 통합 리스트 반드시 유지 — 기존 소비자 깨지지 않도록
- 카테고리당 최소 3개, 최대 10개 메시지 권장
- enum에 `label` + `icon` 속성은 UI 연동 시에만 필요 (없으면 생략 가능)

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P2 |
| Category | quality |
| Dependencies | 없음 |
| Created | 2026-02-06 |
| Updated | 2026-02-06 |
