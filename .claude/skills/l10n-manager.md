# /l10n-manager - 다국어 키 관리 자동화

## Purpose
MindLog l10n 시스템(ko/en ARB) 의 키 추가, 동기화 검증, 누락 감사를 자동화.
ARB 파일 불일치 탐지, 하드코딩 한국어 스트링 감지, 새 키 양쪽 동기 추가를 지원.

## Usage
```
/l10n-manager audit           ← 2-agent 병렬 감사 (기본)
/l10n-manager add <key> "<ko>" "<en>"   ← 새 키 양쪽 ARB에 추가
/l10n-manager validate        ← flutter gen-l10n 실행 후 컴파일 검증
/l10n-manager status          ← 키 통계 요약만 빠르게 출력
```

## 설정 (l10n.yaml)
```yaml
arb-dir: lib/l10n
template-arb-file: app_ko.arb   # ko가 source of truth
output-localization-file: app_localizations.dart
```

## 트리거 조건
- 새 UI 화면/위젯 추가 시 (하드코딩 스트링 점검)
- ARB 파일 직접 수정 후 (키 동기화 검증)
- 배포 전 다국어 완전성 확인
- 하드코딩 스트링 리팩토링 시작 전

---

## 실행 방식

### `audit` — 2-Agent 병렬 감사
```
/l10n-manager audit 실행 시:
┌─────────────────────────────────────────────┐
│                 l10n-manager                 │
│                                             │
│  ┌──────────────────┐  ┌─────────────────┐  │
│  │ key-sync-checker │  │  usage-auditor  │  │
│  │                  │  │                 │  │
│  │ ko ↔ en ARB      │  │ 코드 ↔ ARB 키  │  │
│  │ 키 불일치 탐지    │  │ 하드코딩 스트링 │  │
│  │ 빈 값 감지        │  │ dead key 탐지   │  │
│  │ 플레이스홀더 검증 │  │ null 안전성     │  │
│  └──────────────────┘  └─────────────────┘  │
│           ↓                    ↓             │
│              통합 감사 리포트 생성             │
└─────────────────────────────────────────────┘
```

에이전트 파일:
- `.claude/agents/l10n-manager/key-sync-checker.md`
- `.claude/agents/l10n-manager/usage-auditor.md`

### `add` — 새 키 양쪽 ARB에 동기 추가
```
/l10n-manager add saveSuccess "저장되었습니다" "Saved successfully"
```

동작:
1. `app_ko.arb` → 마지막 키 뒤에 `"saveSuccess": "저장되었습니다"` 추가
2. `app_en.arb` → 동일 위치에 `"saveSuccess": "Saved successfully"` 추가
3. JSON 유효성 확인 (쉼표/중괄호 처리)
4. 추가 후 키 수 보고: "✅ saveSuccess 키 추가 완료 (ko: N+1개, en: N+1개)"

주의사항:
- 키 이름: lowerCamelCase 강제
- 키 중복 시: "⚠️ saveSuccess 키가 이미 존재합니다" 경고 후 중단
- JSON 구조 유지: 마지막 기존 항목에 쉼표 추가, 신규 항목은 쉼표 없음

### `validate` — 빌드 검증
```
flutter gen-l10n
flutter analyze lib/l10n/
```
- 생성된 `app_localizations.dart` 컴파일 오류 확인
- 플레이스홀더 타입 불일치 탐지

### `status` — 빠른 현황
출력 예시:
```
📊 L10n Status (2026-02-27)
  ko.arb: 20 keys | en.arb: 20 keys ✅ 동기화됨
  코드 사용: 0/20 키 (ARB 정의 키 미사용 — 전체 마이그레이션 필요)
  하드코딩 한국어 스트링: 탐지 필요 → /l10n-manager audit
```

---

## ARB 키 정책

### 네이밍 컨벤션
```
screen + element 조합 (lowerCamelCase):
  diaryList + Empty → diaryListEmpty
  alert + DeleteTitle → alertDeleteTitle

공용 액션 (단어):
  ok, cancel, save, delete, edit, error, loading

패턴:
  [화면명][요소명]         예: diaryWriteTitle
  [컴포넌트][상태]         예: analysisWaitMessage
  alert[액션][Title/Message]  예: alertDeleteTitle
```

### 키 우선순위 (추가 여부 판단)
```
✅ ARB에 추가:
  - 사용자에게 보이는 UI 텍스트 (버튼, 라벨, 메시지)
  - 에러 다이얼로그 제목/내용
  - 빈 상태 메시지

❌ ARB 미대상:
  - FCM 알림 본문 (notification_messages.dart — 개인화 별도)
  - AI 분석 결과 텍스트 (동적 데이터)
  - 로그/디버그 메시지
  - 감정 키워드 (AI 응답)
```

### 플레이스홀더 규칙
```json
{
  "greetingUser": "안녕하세요, {name}님!",
  "@greetingUser": {
    "placeholders": {
      "name": { "type": "String" }
    }
  }
}
```
- 플레이스홀더 메타(`@keyName`)는 ko.arb에만 정의 (template)
- en.arb에는 값만 정의, `{name}` 플레이스홀더 동일하게 포함

---

## 현재 ARB 키 목록 (20개)

| 키 | ko 값 | 카테고리 |
|----|-------|---------|
| appName | MindLog | 앱 |
| ok | 확인 | 공용 |
| cancel | 취소 | 공용 |
| error | 오류 | 공용 |
| loading | 로딩 중... | 공용 |
| save | 저장 | 공용 |
| delete | 삭제 | 공용 |
| edit | 수정 | 공용 |
| settings | 설정 | 공용 |
| version | 버전 | 공용 |
| privacyPolicy | 개인정보 처리방침 | 설정 |
| opensourceLicense | 오픈소스 라이선스 | 설정 |
| diaryListTitle | 일기 목록 | 일기 목록 |
| diaryListEmpty | 작성된 일기가 없습니다... | 일기 목록 |
| diaryWriteToday | 오늘 기록하기 | 일기 목록 |
| analysisWaitMessage | AI가 일기를 분석하고 있습니다... | 분석 |
| analysisComplete | 분석 완료 | 분석 |
| analysisFailed | 분석 실패 | 분석 |
| emotionScore | 감정 점수 | 분석 결과 |
| keywords | 키워드 | 분석 결과 |
| empathyMessage | 공감 메시지 | 분석 결과 |
| actionItem | 추천 행동 | 분석 결과 |
| alertDeleteTitle | 일기 삭제 | 다이얼로그 |
| alertDeleteMessage | 정말로 이 일기를 삭제하시겠습니까? | 다이얼로그 |
| alertDeleteAllTitle | 모든 일기 삭제 | 다이얼로그 |
| alertDeleteAllMessage | 정말로 모든 일기를 삭제하시겠습니까?... | 다이얼로그 |

---

## 출력 형식 (audit)

```markdown
# L10n Audit Report

## Executive Summary
| 영역 | 상태 | Critical | High | Medium |
|------|------|----------|------|--------|
| ARB 키 동기화 | PASS/FAIL | 0 | 0 | 0 |
| 코드 사용 현황 | PASS/WARN/FAIL | 0 | 0 | 0 |

## 즉시 조치 필요 (Critical)
...

## 상세 에이전트 리포트
[key-sync-checker 결과]
[usage-auditor 결과]

## 다음 권장 액션
1. 하드코딩 스트링 X개 → ARB 키로 마이그레이션
   실행: /l10n-manager add <key> "<ko>" "<en>"
2. 미사용 ARB 키 정리 검토
```

## 관련 스킬
- `/notification-audit` — 알림 시스템 감사 (별도 영역)
- `/arch-check` — 아키텍처 레이어 위반 감사
- `/lint-fix` — 린트 오류 자동 수정
