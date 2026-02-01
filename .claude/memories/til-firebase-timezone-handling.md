# TIL: Firebase Functions 시간대 처리 버그 디버깅

**Date**: 2026-01-30
**Session**: 마음케어 알림 시간 버그 수정
**Commit**: e5ce2d9 (feature) → `getTodayMessage(timeSlot)` 파라미터 추가

---

## 버그 분석: UTC vs KST 시간대 불일치

### 문제 현상
- **예상**: 오전 9시(KST)에 아침 메시지 발송
- **실제**: 저녁 메시지가 발송됨

### 근본 원인: 시간대 체인 끊김

```typescript
// ❌ 버그 코드: Firebase Functions UTC에서 실행되는 사실 무시
function getKSTHour(): number {
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone: TIMEZONE,  // "Asia/Seoul"로 설정했으니 안전할 거라고 착각
    hour: "numeric",
    hour12: false,
  });
  return parseInt(formatter.format(new Date()), 10);
}

// 조건 검사
const hour = getKSTHour();  // KST 9시라고 생각했으나...
if (hour >= 5 && hour < 12) {  // true여야 하는데 false 반환
  // 아침 메시지
} else {
  // 저녁 메시지 ← 실제로 여기 실행됨
}
```

### 시간대 변환 흐름 추적

| 단계 | 시간 | 설명 |
|------|------|------|
| 1. 실제 시각 | `09:00 KST` | 한국 아침 9시 |
| 2. UTC 변환 | `00:00 UTC` | Firebase에서 인식하는 시각 (9시간 뒤) |
| 3. `Intl.DateTimeFormat` | `00:00` | **timeZone 옵션이 있어도 입력값은 UTC 기반** |
| 4. hour 추출 | `hour = 0` | → 조건 `0 >= 5` = false |
| 5. 결과 | 저녁 메시지 | 버그 발현 ❌ |

### 핵심 통찰: Intl.DateTimeFormat의 한계
```javascript
// timeZone 옵션이 있어도, 입력 Date 객체가 UTC이면
// 단순히 "표시용으로만" 변환할 뿐, 동작 로직에는 영향 없음
const date = new Date();  // UTC 기준 Date 객체
const formatter = new Intl.DateTimeFormat("en-US", {
  timeZone: "Asia/Seoul"  // "표시"만 하고, 계산에는 미반영
});
// → 화면에 보여줄 때는 KST로 표시하지만
// → 내부 로직은 여전히 UTC 기반
```

---

## 해결책: 시간대 의존성 제거

### 구조적 전환: 시간대 "계산"에서 "선택지"로

```typescript
// ✅ 개선 코드: 호출자가 명시적으로 timeSlot 지정
export async function getTodayMessage(
  timeSlot: "morning" | "evening" = "morning"  // 파라미터화
): Promise<{ title: string; body: string } | null> {
  // ... Firestore 쿼리 ...

  // Fallback: 시간대 자동 계산 대신 파라미터 사용
  return getMessageByTimeSlot(timeSlot);  // 시간대 "선택"
}

// 호출 측에서 명시적으로 지정
const message = await getTodayMessage("morning");  // 아침으로 고정
```

### 왜 이 방식이 나은가?

| 항목 | 이전 (시간대 자동 계산) | 이후 (명시적 지정) |
|------|------------------------|-------------------|
| **시간대 의존** | O (버그 원인) | X |
| **타이밍 버그** | 가능성 높음 | 불가능 |
| **테스트 용이성** | 어려움 (실행 시각에 따라 변함) | 쉬움 (시간대 파라미터만 변경) |
| **디버깅** | "왜 저녁이지?" (불명확) | `getTodayMessage("morning")` (명확) |
| **코드 의도** | 암묵적 | 명시적 (self-documenting) |

---

## Firebase Functions 시간대 처리 Best Practices

### ✅ DO: 명시적 timeSlot 파라미터

```typescript
// scheduled.ts: 각 이벤트에서 timeSlot 명시
export const scheduledMorningNotification = onSchedule({
  schedule: SCHEDULE.MORNING_CRON,
  timeZone: TIMEZONE,  // onSchedule에 timeZone 지정 (올바름)
}, async (_event) => {
  const message = await getTodayMessage("morning");  // ← 명시적
});

export const scheduledEveningNotification = onSchedule({
  schedule: SCHEDULE.EVENING_CRON,
  timeZone: TIMEZONE,
}, async (_event) => {
  const message = await getTodayMessage("evening");  // ← 명시적
});
```

### ❌ DON'T: 실행 시간 기반 조건문

```typescript
// ❌ 위험: Firebase Functions의 런타임 시간대 가정
if (getKSTHour() >= 5) { ... }  // 버그 위험

// ❌ 위험: 클라이언트 시간대 신뢰
const clientHour = someDate.getHours();  // 클라이언트 로컬 시간
if (clientHour >= 5) { ... }  // 부정확

// ❌ 위험: SDK 내부 시간대 변환 다중화
// Intl.DateTimeFormat로 보이기만 변경, 논리는 여전히 UTC
```

### ✅ DO: 시간대 처리는 "Trigger 레벨"에서만

```typescript
// Firebase Scheduler가 올바른 시간에 자동 트리거
onSchedule({
  schedule: "0 9 * * *",      // 정확한 cron (UTC 아님!)
  timeZone: "Asia/Seoul",     // 여기서만 시간대 명시
}, async (event) => {
  // 이미 정확한 시간에 도착했으므로,
  // 함수 내부에서 시간대 계산할 필요 없음
  const message = getTodayMessage("morning");
});
```

### 날짜 처리: `Intl.DateTimeFormat` + `en-CA` 조합

```typescript
// ✅ 올바른 날짜 생성 (YYYY-MM-DD)
export function getTodayKey(): string {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: TIMEZONE,  // "Asia/Seoul"
  });
  return formatter.format(new Date());  // "2026-01-30" (KST 기준)
}

// 근거: en-CA 로케일은 YYYY-MM-DD 형식 (ISO 8601)
```

### Fallback 전략: Safe Default 선택

```typescript
// ✅ 에러 발생 시 안전한 기본값 제공
export async function getTodayMessage(
  timeSlot: "morning" | "evening" = "morning"  // ← 안전한 기본값
): Promise<{ title: string; body: string } | null> {
  try {
    // ... Firestore 쿼리 ...
    return getMessageByTimeSlot(timeSlot);
  } catch (error) {
    logger.error("[Firestore] Failed", { error });
    // 에러 시에도 timeSlot 파라미터 신뢰
    return getMessageByTimeSlot(timeSlot);  // ← 같은 로직
  }
}
```

---

## 유사 버그 패턴 및 방지법

### 패턴 1: "모든 곳에서 시간대 계산" 안티패턴

```typescript
// ❌ 여러 곳에서 시간대 계산 → 불일치 위험
function getKSTHour() { /* UTC 기반 버그 */ }
function getKSTDate() { /* 다른 방식으로 구현 */ }
function getKSTMinute() { /* 또 다른 방식 */ }
// → 세 함수가 일관되지 않은 결과 반환 가능
```

**방지법**: 시간대 변환을 한 곳에서만 관리
```typescript
// ✅ 중앙화된 시간대 처리
const getTodayKey = () => /* 한 번만 정의 */
// 나머지는 시간대를 파라미터로 받음
```

### 패턴 2: "런타임 조건"을 "배포 타임 설정"으로 대체

```typescript
// ❌ 버그 위험: 런타임에 결정
if (currentHour >= 5) {  // 실행 시각에 따라 결과 변함
  sendMorningMessage();
} else {
  sendEveningMessage();
}

// ✅ 안전: 배포 타임에 결정
// morning-notification.ts
sendMorningMessage();  // 명시적, 테스트 가능

// evening-notification.ts
sendEveningMessage();  // 명시적, 테스트 가능
```

### 패턴 3: "Scheduler의 timeZone"을 신뢰

```typescript
// ✅ Firebase Scheduler가 이미 시간대를 처리
onSchedule({
  schedule: "0 9 * * *",      // cron 표현식
  timeZone: "Asia/Seoul",     // Firebase가 해석
  // → Firebase가 내부적으로 UTC로 변환하여 정확한 시간에 트리거
}, async (event) => {
  // 이 핸들러는 이미 정확한 시간에 호출됨
  // → 함수 내부에서 다시 시간대 계산할 필요 없음
});
```

---

## 테스트 전략: 시간대 독립성 검증

```typescript
describe("getTodayMessage", () => {
  // ✅ 시간대와 무관하게 테스트 가능
  it("should return morning message when timeSlot is morning", async () => {
    const message = await getTodayMessage("morning");
    expect(message).toBeTruthy();
    // 검증: morning 메시지인지 확인
  });

  it("should return evening message when timeSlot is evening", async () => {
    const message = await getTodayMessage("evening");
    expect(message).toBeTruthy();
    // 검증: evening 메시지인지 확인
  });

  // ❌ 피해야 할 테스트 (시간대에 의존)
  // it("should return morning message at 9 AM", async () => {
  //   // 이 테스트는 9시에만 통과 → 불안정
  // });
});
```

---

## 결론: "시간대는 Trigger 문제, 비즈니스 로직 문제 아님"

### 핵심 교훈
1. **Firebase Functions는 항상 UTC에서 실행** → Scheduler의 `timeZone` 옵션이 변환 처리
2. **함수 내부에서 시간대 "계산"하면 버그** → Trigger가 이미 처리함
3. **timeSlot을 파라미터화** → 호출자가 명시적으로 지정 → 시간대 버그 원천 차단
4. **Intl.DateTimeFormat은 "표시용"** → 날짜 문자열에만 사용 (getTodayKey), 조건문에는 금지
5. **Safe Default 원칙** → 에러 시에도 일관된 timeSlot 사용

### 다음 세션 체크리스트
- [ ] Firebase Functions 내 시간대 계산 로직 모두 확인 (Grep: `getHours`, `getMinutes`, `Date()`)
- [ ] 모든 Scheduled 함수가 명시적 `timeSlot` 파라미터 전달 확인
- [ ] 테스트 케이스: 모든 시간대에서 동일한 메시지 반환 검증
- [ ] 문서화: README에 "시간대 처리" 섹션 추가
