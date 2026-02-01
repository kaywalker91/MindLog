# 자동화 로드맵 (2026-01-30)

> 마음케어 저녁 알림 구현 세션(commit e5ce2d9)에서 발굴한 자동화 기회

---

## 발굴된 5가지 반복 패턴

### 1. **함수 시그니처 진화 + 호출부 일괄 수정** (반복성: 높음)

**현재 세션 예시**:
```typescript
// Before
export async function checkIfSentToday(): Promise<boolean>

// After (기본값으로 하위호환성 유지)
export async function checkIfSentToday(
  timeSlot: "morning" | "evening" = "morning"
): Promise<boolean>
```

변경 과정:
1. 함수 정의 수정 (1곳)
2. 호출부 찾기/수정 (6곳: 아침/저녁 함수 각 3곳)
3. 테스트 업데이트 (선택적)

**자동화 스킬**: `/refactor-signatures` (P1)

---

### 2. **타임존 버그 리팩토링** (반복성: 중간)

**문제**: Firebase Functions는 UTC에서 실행되는데 `new Date().getHours()` 사용
**현재 세션 수정**:
```typescript
// Before (❌ UTC 시간)
const hour = new Date().getHours();

// After (✅ KST 명시적 변환)
const hour = parseInt(
  new Intl.DateTimeFormat("en-US", {
    timeZone: "Asia/Seoul",
    hour: "numeric",
    hour12: false,
  }).format(new Date()),
  10
);
```

영향 함수: `getTodayKey()`, `getDefaultMessageByTimeOfDay()`

**자동화 스킬**: `/timezone-fix` (P2)

---

### 3. **메시지 분류 시스템 도입** (반복성: 낮음)

**패턴**:
- 단일 배열 `DEFAULT_MESSAGES` → 분류 배열 `DEFAULT_MORNING_MESSAGES` + `DEFAULT_EVENING_MESSAGES`
- 선택 함수 추가: `getMessageByTimeSlot(timeSlot)`

```typescript
// Before
const message = DEFAULT_MESSAGES[Math.random() * DEFAULT_MESSAGES.length];

// After
const message = getMessageByTimeSlot("morning");
```

**자동화 스킬**: `/batch-message-split` (P3, 도메인특화)

---

### 4. **로그 키 생성 로직 캡슐화** (반복성: 중간)

**패턴**: 반복되는 문자열 조합을 헬퍼로 추출

```typescript
// Before (중복)
const logKey = `${getTodayKey()}_${timeSlot}`;  // 여러 곳에서 반복

// After (캡슐화)
export function getSentLogKey(timeSlot: "morning" | "evening"): string {
  return `${getTodayKey()}_${timeSlot}`;
}
```

영향: 4개 함수에서 동일 로직 제거

**자동화 스킬**: `/extract-helper` (P2)

---

### 5. **마이그레이션 표시 (@deprecated)** (반복성: 높음)

**패턴**: 상수/함수 이름 변경 시 하위호환성 유지

```typescript
/** @deprecated DAILY_CRON 대신 MORNING_CRON 사용 */
DAILY_CRON: "0 9 * * *",

// 기존 코드는 동작, 새 코드는 MORNING_CRON 사용
```

**자동화 강화**: `/lint-fix --deprecation` (P1)

---

## 신규 스킬 구현 계획

| 스킬 | 목표 | 구현 시간 | 효과 | 우선순위 |
|-----|------|---------|------|---------|
| `/refactor-signatures` | 함수 시그니처 변경 시 호출부 자동 업데이트 | 30분 | 함수 진화 30분→5분 | **P1** |
| `/lint-fix --deprecation` | deprecation 자동 표시 및 추적 | 15분 (강화) | 마이그레이션 자동화 | **P1** |
| `/timezone-fix` | UTC→명시적 지역 변환 자동화 | 45분 | Firebase 타임존 버그 자동 해결 | **P2** |
| `/extract-helper` | 반복 로직을 헬퍼로 자동 추출 | 40분 | 모든 리팩토링에 범용 | **P2** |
| `/batch-message-split` | 배열 분류 및 선택 함수 생성 | 60분 | MindLog 메시지 진화 | P3 |

---

## 현재 프로젝트에서의 효과 예측

### 세션 작업 시간 비교

| 작업 | 현재 방식 | 스킬 적용 후 | 절감 |
|-----|---------|-----------|------|
| 함수 시그니처 변경 (checkIfSentToday) | 15분 | 3분 | -80% |
| 호출부 찾기 및 수정 (6곳) | 10분 | 1분 | -90% |
| 타임존 변환 함수 추가 | 15분 | 5분 | -67% |
| 테스트 케이스 작성 (13개) | 25분 | 8분 | -68% |
| **총 세션 시간** | **65분** | **17분** | **-74%** |

---

## 기존 스킬과의 통합

### `/test-unit-gen` 강화 (타임존 인식)
```bash
/test-unit-gen functions/src/services/firestore.service.ts --timezone "Asia/Seoul"
```

현재:
- 일반적 테스트 구조 생성

강화 제안:
- KST 경계 케이스 자동 포함
- Mock Date 헬퍼 자동 생성
- UTC/KST 변환 검증 테스트 자동 생성

---

## 메모리 기록 (지식 보존)

### 신규 메모리 파일: `.claude/memories/firebase-functions-patterns.md`

**내용**:
1. 타임존 버그 패턴 및 해결책
2. 함수 시그니처 진화 하위호환성 전략
3. 데이터 분류 패턴 (배열 → 분류)
4. 발송 로그 설계 (idempotency)

---

## 구현 일정 제안

### **이번 주** (2026-02-01)
- [ ] `/refactor-signatures` 구현 (30분)
- [ ] `/lint-fix --deprecation` 강화 (15분)

### **다음 주** (2026-02-08)
- [ ] `/timezone-fix` 구현 (45분)
- [ ] 메모리 파일 작성 (20분)

### **다음 달** (2026-03-01)
- [ ] `/extract-helper` 구현 (40분)
- [ ] 스킬 통합 테스트 및 문서화

---

## 결론

**발굴 요약**:
- 5가지 반복 가능한 패턴 확인
- 5개 신규 스킬 후보 (P1: 2개, P2: 2개, P3: 1개)
- 유사 작업 최대 74% 시간 절감 가능
- 기존 스킬 강화로 추가 효과 예상

**다음 액션**: `/refactor-signatures` 스킬 명세서 작성 후 구현

---

**분석자**: Claude Code
**분석 대상**: commit e5ce2d9 (오전 9시 마음케어 알림 저녁 버전 추가)
**분석 일시**: 2026-01-30
