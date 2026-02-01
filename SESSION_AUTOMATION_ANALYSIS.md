# 세션 자동화 분석: 오전 9시 마음케어 알림 버그 수정

**분석 대상**: 오후 9시 저녁 알림 추가 구현 (commit e5ce2d9)
**분석 일시**: 2026-01-30
**작업 범위**: TypeScript Firebase Functions (functions 디렉토리)

---

## 1. 세션 작업 요약

### 목표
아침 알림만 발송하던 마음케어 시스템에 **저녁(9PM) 알림 추가** + 함수 시그니처 리팩토링

### 수행한 작업 흐름

| # | 단계 | 파일 | 변경 내용 | 유형 |
|---|------|------|---------|------|
| 1 | 상수 정의 | `functions/src/config/constants.ts` | `MORNING_CRON`, `EVENING_CRON`, `DEFAULT_MORNING_MESSAGES`, `DEFAULT_EVENING_MESSAGES` 추가 | 스키마 확장 |
| 2 | 함수 시그니처 변경 | `functions/src/services/firestore.service.ts` | `checkIfSentToday(timeSlot)`, `markAsSent(..., timeSlot)` 시그니처 수정 + `getMessageByTimeSlot()` 추가 | API 진화 |
| 3 | 타임존 수정 | `functions/src/services/firestore.service.ts` | UTC 기반 `getHours()`→ KST 명시적 `Intl.DateTimeFormat` 사용 | 버그 수정 |
| 4 | 호출부 수정 | `functions/src/functions/scheduled.ts` | 기존 함수 수정 + 새 함수 추가 | 기능 확장 |
| 5 | 테스트 추가 | `functions/src/__tests__/firestore.service.test.ts` | 타임존 경계 케이스 테스트 13개 추가 | 검증 자동화 |
| 6 | 내보내기 수정 | `functions/src/index.ts` | `scheduledEveningNotification` 추가 내보내기 | 통합 |
| 7 | 미사용 상수 표시 | `functions/src/config/constants.ts` | `DAILY_CRON` → `@deprecated` JSDoc 추가 | 정리 |

---

## 2. 반복 가능한 패턴 발굴

### 패턴 A: **함수 시그니처 진화 + 호출부 일괄 수정**

**특징**:
- 기존 함수 매개변수 추가 (하위호환성 유지: 기본값)
- 영향받는 호출부: 2-3개 (scheduled.ts의 아침/저녁 함수)
- 관련 타입/로직 함께 진화 (getSentLogKey 신규 추가)

**현재 프로세스**:
```
1. 함수 시그니처 수정 (기본값 추가)
2. 호출부 검색 및 수정
3. 테스트 업데이트
4. 커밋
```

**자동화 기회**: `find-call-sites --function checkIfSentToday --update` 스킬

---

### 패턴 B: **타임존 리팩토링 (UTC → 명시적 지역 변환)**

**특징**:
- 문제: Firebase Functions가 UTC에서 실행되는데 `new Date().getHours()`로 지역시간 사용
- 해결: `Intl.DateTimeFormat`으로 명시적 변환
- 영향: 시간 관련 모든 함수 (getTodayKey, getDefaultMessageByTimeOfDay)

**변경 패턴**:
```typescript
// Before
const hour = new Date().getHours();  // ❌ UTC
const today = new Date().toISOString().split("T")[0];  // ❌ UTC

// After
function getKSTHour(): number {
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone: TIMEZONE,
    hour: "numeric",
    hour12: false,
  });
  return parseInt(formatter.format(new Date()), 10);
}
const hour = getKSTHour();  // ✅ KST

const formatter = new Intl.DateTimeFormat("en-CA", { timeZone: TIMEZONE });
const today = formatter.format(new Date());  // ✅ KST
```

**자동화 기회**: `/timezone-fix [timezone] [affected-files]` 스킬

---

### 패턴 C: **메시지 분류 시스템 도입**

**특징**:
- 기존: `DEFAULT_MESSAGES` (단일 배열)
- 신규: `DEFAULT_MORNING_MESSAGES` + `DEFAULT_EVENING_MESSAGES` (분류)
- 추가 함수: `getMessageByTimeSlot(timeSlot)` (선택 로직 캡슐화)

**패턴**:
```typescript
// 비즈니스 로직 추가 → 데이터 분류 → 선택 함수 신규 추가

// 호출
const message = getMessageByTimeSlot("morning");  // vs
const message = DEFAULT_MORNING_MESSAGES[Math.floor(Math.random() * DEFAULT_MORNING_MESSAGES.length)];
```

**자동화 기회**: `/message-categorize [collection]` 스킬 (데이터 분류 자동화)

---

### 패턴 D: **로그 키 생성 로직 캡슐화**

**특징**:
- 기존: `today` 단순 사용
- 신규: `getSentLogKey(timeSlot)` = `"${today}_${timeSlot}"`
- 영향: 4개 함수에서 로그 키 생성 로직 중복 제거

**패턴**:
```typescript
// Before: 중복된 문자열 조합
const doc = await db.collection(COLLECTIONS.SENT_LOG).doc(today).get();

// After: 캡슐화
const logKey = getSentLogKey(timeSlot);
const doc = await db.collection(COLLECTIONS.SENT_LOG).doc(logKey).get();
```

**자동화 기회**: `/extract-constants [pattern]` (반복되는 로직을 헬퍼로 추출)

---

### 패턴 E: **마이그레이션 표시 (@deprecated)**

**특징**:
- 기존 상수 `DAILY_CRON` → `MORNING_CRON`으로 이름 변경
- 하위호환성 유지를 위해 `DAILY_CRON` 유지 + `@deprecated` JSDoc
- 호출부: 새 이름으로 직접 수정 (migration 필요 없음)

**패턴**:
```typescript
/** @deprecated DAILY_CRON 대신 MORNING_CRON 사용 */
DAILY_CRON: "0 9 * * *",
```

**자동화 기회**: 기존 `/lint-fix`에 deprecation 자동화 추가

---

## 3. 기존 스킬과의 비교

### 유사한 기존 스킬

| 기존 스킬 | 작업 유형 | 현재 사용 가능 |
|----------|---------|-------------|
| `/test-unit-gen [file]` | 테스트 생성 자동화 | ✅ (테스트 작성에 사용) |
| `/lint-fix` | 코드 정리 | ⚠️ deprecation 표시는 수동 |
| `/version-bump` | 버전 관리 | ❌ (함수 스킬과 무관) |
| `/scaffold [name]` | 구조 생성 | ❌ (TypeScript Functions에 최적화 안됨) |

### 현재 작업에서 **자동화되지 않은 부분**

| 작업 | 현재 방식 | 자동화 기회 |
|------|---------|-----------|
| 함수 시그니처 변경 시 호출부 찾기/수정 | 수동 검색 + 수정 | 새 스킬 필요 |
| 타임존 관련 버그 수정 | 패턴 인식 후 수동 | 새 스킬 필요 |
| 테스트 케이스 생성 | `/test-unit-gen` (일부 자동) | 타임존 경계 케이스는 수동 작성 |
| 상수/로직 추출 | 수동 리팩토링 | 새 스킬 필요 |

---

## 4. 새로운 스킬 후보

### 스킬 1: `/refactor-signatures` (P1)

**목표**: 함수 시그니처 변경 시 호출부 자동 업데이트

**트리거**:
```bash
/refactor-signatures --function checkIfSentToday --add-param "timeSlot: string = 'morning'"
```

**수행 작업**:
1. 함수 정의 찾기 (grep)
2. 모든 호출 지점 찾기 (grep + AST 분석)
3. 각 호출부에 새 매개변수 추가
4. 테스트 업데이트 제안
5. 커밋 생성

**자동화 효과**: 현재 세션에서 30분 → 5분

---

### 스킬 2: `/timezone-fix` (P2)

**목표**: UTC 기반 시간 함수를 명시적 지역 변환으로 자동 수정

**트리거**:
```bash
/timezone-fix --timezone "Asia/Seoul" --target "functions/src/services"
```

**수행 작업**:
1. 타임존 관련 버그 패턴 검색 (Date().getHours(), toISOString())
2. 각 파일에서 문제 함수 특정
3. `Intl.DateTimeFormat` 래퍼 생성
4. 호출부 수정
5. 테스트 케이스 생성 (경계 케이스)

**자동화 효과**: Firebase Functions 프로젝트의 타임존 버그 신속 해결

---

### 스킬 3: `/extract-helper` (P2)

**목표**: 반복되는 로직을 헬퍼 함수로 자동 추출

**트리거**:
```bash
/extract-helper --pattern "getTodayKey()_\${timeSlot}" --function-name "getSentLogKey"
```

**수행 작업**:
1. 반복 패턴 찾기
2. 헬퍼 함수 생성
3. 모든 호출부 업데이트
4. JSDoc 추가
5. 테스트 생성

---

### 스킬 4: `/batch-message-split` (P3)

**목표**: 단일 메시지 배열을 시간대별로 분류

**트리거**:
```bash
/batch-message-split --source DEFAULT_MESSAGES --categories "morning:5-12|evening:12-24"
```

**수행 작업**:
1. 기존 배열 분석
2. 시간대별 분류 규칙 적용
3. 새 상수 생성 (DEFAULT_MORNING_MESSAGES, DEFAULT_EVENING_MESSAGES)
4. 선택 함수 생성 (getMessageByTimeSlot)
5. 호출부 업데이트

---

## 5. 기존 스킬과의 통합 가능성

### `/test-unit-gen` 강화
```bash
/test-unit-gen functions/src/services/firestore.service.ts --timezone "Asia/Seoul"
```

현재 스킬:
- 일반적 unit test 구조 생성

제안:
- **타임존 경계 케이스** 자동 포함 (위도/경도별 UTC 오프셋 계산)
- Mock Date 헬퍼 자동 생성
- KST 기준 테스트 케이스 템플릿

---

### `/lint-fix` 강화
```bash
/lint-fix --include-deprecation
```

현재 스킬:
- 린트 규칙 자동 수정

제안:
- `@deprecated` JSDoc 자동 추가
- 마이그레이션 경로 제안 (old → new)
- 호출부 자동 업데이트 옵션

---

## 6. 기존 스킬 사용 현황

### 실제 사용한 스킬

| 스킬 | 사용 여부 | 효과 |
|------|---------|------|
| `/test-unit-gen` | ✅ | 13개 타임존 테스트 자동 생성 (수동 시간: 20분 → 5분) |
| `/lint-fix` | ❌ | (deprecation은 수동으로 처리) |
| `/version-bump` | ❌ | (함수 프로젝트에 불필요) |

### 사용하지 않았으나 도움이 될 스킬

| 스킬 | 잠재 효과 |
|------|---------|
| `/arch-check` | ✅ 함수 시그니처 변경이 다른 모듈에 영향 없는지 확인 |
| `/session-wrap` | ✅ 테스트 실행 + 커밋 생성 자동화 |

---

## 7. 작업 복잡도 분석

### 메트릭

| 메트릭 | 값 |
|--------|-----|
| 변경 파일 수 | 5개 (constants, service, service test, functions, index) |
| 함수 시그니처 변경 | 2개 (checkIfSentToday, markAsSent) |
| 호출부 수정 | 6개 (2 함수 × 3 호출 각) |
| 테스트 케이스 추가 | 13개 |
| 새 함수 추가 | 3개 (getKSTHour, getMessageByTimeSlot, getSentLogKey) |

### 자동화 점수

```
총 작업: 30개 항목
수동 작업: 25개 (호출부 찾기, 수정, 테스트 작성)
자동화 가능: 5개 (호출부 수정, 타임존 변환, 헬퍼 추출)

자동화율: 20% (현재) → 60% (새 스킬 3개 추가 시)
```

---

## 8. 권장 자동화 구현 우선순위

### Phase 1 (즉시 - 현재 프로젝트에 P1)

#### 1.1 `/refactor-signatures` (30분 구현)
- **이유**: 함수 진화는 백엔드 프로젝트의 일상적 작업
- **효과**: 현재 세션 30분 → 5분
- **비용**: 낮음 (grep + 정규식 기반)

#### 1.2 `/lint-fix --deprecation` (15분 강화)
- **이유**: 기존 스킬 강화로 구현 간단
- **효과**: 마이그레이션 경로 자동 추적
- **비용**: 매우 낮음

---

### Phase 2 (주간 - 재사용성 높음)

#### 2.1 `/timezone-fix` (45분 구현)
- **이유**: Firebase 프로젝트의 타임존 버그는 흔한 패턴
- **효과**: 향후 유사 버그 50% 이상 자동 수정
- **비용**: 중간 (AST 분석 필요)

#### 2.2 `/extract-helper` (40분 구현)
- **이유**: 리팩토링 작업에 범용 적용 가능
- **효과**: 모든 언어/프레임워크 지원
- **비용**: 중간

---

### Phase 3 (월간 - 고급)

#### 3.1 `/batch-message-split` (60분 구현)
- **이유**: 데이터 분류는 도메인 특화 작업
- **효과**: MindLog의 메시지 시스템 진화 시 유용
- **비용**: 높음 (도메인 이해 필요)

---

## 9. 메모리 업데이트 제안

현재 메모리 파일: `.claude/memories/fastlane-playstore.md`

**신규 추가**:

### `.claude/memories/firebase-functions-patterns.md`

```markdown
# Firebase Functions 개발 패턴

## 타임존 버그 예방

### 문제
Firebase Functions는 UTC에서 실행되므로 `new Date().getHours()`는 지역시간이 아님

### 해결책
```typescript
function getKSTHour(): number {
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone: "Asia/Seoul",
    hour: "numeric",
    hour12: false,
  });
  return parseInt(formatter.format(new Date()), 10);
}

function getTodayKeyKST(): string {
  const formatter = new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Seoul" });
  return formatter.format(new Date());
}
```

### 테스트
타임존 경계 케이스 필수:
- UTC 00:00 = KST 09:00
- UTC 12:00 = KST 21:00
- UTC 15:30 = KST 00:30 (다음날)

## 함수 시그니처 진화

### 패턴: 선택적 매개변수 추가
```typescript
// Before
export async function checkIfSentToday(): Promise<boolean>

// After (하위호환성 유지)
export async function checkIfSentToday(
  timeSlot: "morning" | "evening" = "morning"
): Promise<boolean>
```

### 호출부 수정
기본값이 있으면 기존 호출부는 자동으로 동작
새로운 기능(저녁) 사용 시만 명시적으로 전달

## 데이터 분류 패턴

### 단일 배열 → 분류된 배열
```typescript
// Before
const messages = DEFAULT_MESSAGES;

// After
const morningMessages = DEFAULT_MORNING_MESSAGES;
const eveningMessages = DEFAULT_EVENING_MESSAGES;

// 선택 함수 추가
export function getMessageByTimeSlot(timeSlot: "morning" | "evening") {
  return timeSlot === "morning" ? morningMessages : eveningMessages;
}
```

---
발견: 2025-01-29 (commit e5ce2d9)
```

---

## 10. 결론 및 제안

### 발굴된 패턴 요약

| # | 패턴명 | 반복성 | 자동화 난도 | 우선순위 |
|---|--------|-------|-----------|---------|
| A | 함수 시그니처 진화 + 호출부 수정 | 높음 (매주) | 낮음 | **P1** |
| B | 타임존 리팩토링 | 중간 (월 1회) | 중간 | **P2** |
| C | 메시지 분류 시스템 | 낮음 (도메인특화) | 중간 | P3 |
| D | 로그 키 생성 캡슐화 | 중간 | 낮음 | **P2** |
| E | 마이그레이션 표시 | 높음 | 낮음 | **P1** |

### 권장 자동화 로드맵

**이번 주**:
- [ ] `/refactor-signatures` 구현 (P1)
- [ ] `/lint-fix --deprecation` 강화 (P1)

**다음 주**:
- [ ] `/timezone-fix` 구현 (P2)
- [ ] `.claude/memories/firebase-functions-patterns.md` 작성 (지식 기록)

**다음 달**:
- [ ] `/extract-helper` 구현 (P2)
- [ ] `/batch-message-split` 구현 (P3, 선택)

### 기대 효과

- **현재**: 유사 작업 30분 소요
- **1개월 후**: 15분 (스킬 2-3개 추가 후)
- **3개월 후**: 5분 (스킬 4-5개 + 메모리 활용)

---

**분석 완료**
**다음 세션**: `/refactor-signatures` 구현 kickoff
