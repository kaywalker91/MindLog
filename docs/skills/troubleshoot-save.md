# troubleshoot-save

Resolved 이슈를 구조화된 트러블슈팅 메모리로 자동 캡처하는 스킬

## 목표
- 해결된 버그/이슈를 검색 가능한 JSON 인덱스 + 상세 MD 문서로 저장
- 근본 원인 분류 체계(Root Cause Taxonomy)로 패턴 클러스터링
- 다음 세션에서 유사 이슈 발생 시 즉시 검색 가능한 지식 베이스 구축
- `/debug` → 해결 → `/troubleshoot-save` 자동 연계

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/troubleshoot-save [id]` 명령어 (수동 캡처)
- `/debug` Stage 4 완료 후 **자동 제안** ("트러블슈팅 메모리에 저장하시겠습니까?")
- `/session-wrap` 실행 시 미저장 해결 이슈 감지되면 **자동 제안**
- "트러블슈팅 저장", "이슈 기록" 요청

## 아키텍처: 2-Layer Retrieval Memory

```
┌─────────────────────────────────────────────────────────────┐
│                    QUERY (유사 이슈 검색)                      │
│                         │                                    │
│    ┌────────────────────▼────────────────────┐               │
│    │  Layer 1: docs/troubleshooting.json     │  ← 빠른 검색  │
│    │  (Index: id, tags, rootCause, symptoms) │               │
│    └────────────────────┬────────────────────┘               │
│                         │ match found                        │
│    ┌────────────────────▼────────────────────┐               │
│    │  Layer 2: docs/troubleshooting/{id}.md  │  ← 상세 문서  │
│    │  (진단 과정, 코드, 검증 방법, 교훈)        │               │
│    └─────────────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

**검색 전략**:
1. `tags[]` + `symptoms[]` 키워드 매칭 → 후보 필터링
2. `rootCauseType` + `category` → 유형별 클러스터링
3. `relatedIssues[]` → 연관 이슈 그래프 탐색

## JSON 인덱스 스키마 (Layer 1)

```jsonc
{
  "title": "MindLog 트러블슈팅 가이드",
  "description": "알려진 이슈와 해결 방법",
  "schemaVersion": "2.0",
  "issues": [
    {
      // === 식별자 ===
      "id": "kebab-case-unique-id",          // URL-safe, 파일명과 동일
      "title": "사람이 읽을 수 있는 제목",

      // === 상태 ===
      "status": "resolved",                   // open | investigating | resolved | wontfix
      "resolvedAt": "2026-01-09",
      "affectedVersions": ["< 1.4.11"],
      "fixedInVersion": "1.4.11",            // 수정된 버전

      // === 분류 (Taxonomy) ===
      "category": "notification",             // notification | ui | build | api | database | state | navigation | performance
      "severity": "critical",                 // critical | high | medium | low
      "platform": "android",                  // android | ios | both | backend | ci
      "rootCauseType": "config",             // ← 근본 원인 분류 (아래 표 참조)

      // === 검색 최적화 ===
      "summary": "한 줄 요약 (검색 스니펫용)",
      "symptoms": [                           // 사용자가 경험하는 증상 키워드
        "알림이 안 옴",
        "Release에서만 발생",
        "Debug에서는 정상"
      ],
      "cause": "기술적 근본 원인 한 줄 설명",
      "solution": "해결책 한 줄 설명",

      // === 연결 ===
      "documentation": "troubleshooting/{id}.md",
      "relatedIssues": [],                    // 관련 이슈 ID 배열
      "relatedCommits": ["abc1234"],          // 관련 커밋 해시
      "tags": ["android", "proguard", "r8"],  // 자유 태그 (검색용)

      // === 방어 규칙 ===
      "preventionRule": "외부 패키지 사용 시 proguard keep 규칙 확인", // 재발 방지 한 줄
      "confidence": "high"                    // 근본 원인 확신도: high | medium | low
    }
  ],
  "categories": {
    "notification": "알림 관련",
    "ui": "UI/UX 관련",
    "build": "빌드/배포 관련",
    "api": "API 연동 관련",
    "database": "데이터베이스 관련",
    "state": "상태 관리 관련",
    "navigation": "라우팅/네비게이션 관련",
    "performance": "성능 관련"
  },
  "rootCauseTypes": {
    "config": "설정/구성 오류 (proguard, manifest, yaml 등)",
    "dependency": "외부 패키지/라이브러리 이슈",
    "timing": "비동기/타이밍/레이스 컨디션",
    "state": "상태 관리 버그 (Provider, DB 등)",
    "platform": "플랫폼 특이 동작 (Android/iOS 차이)",
    "logic": "비즈니스 로직 오류",
    "environment": "환경 차이 (Debug/Release, CI/Local)",
    "data": "데이터 무결성/형식 오류",
    "integration": "컴포넌트 간 통합 이슈",
    "ui": "레이아웃/렌더링/UX 이슈"
  },
  "updatedAt": "2026-01-09"
}
```

## Root Cause Taxonomy (근본 원인 분류 체계)

| Type | 설명 | 대표 패턴 | 예시 |
|------|------|-----------|------|
| `config` | 설정/구성 오류 | proguard, manifest, yaml | R8이 클래스 제거 |
| `dependency` | 외부 패키지 이슈 | 버전 충돌, breaking change | flutter_local_notifications 호환 |
| `timing` | 비동기/레이스 컨디션 | async 순서, Provider 초기화 | Provider 미전달 → 빈 리스트 |
| `state` | 상태 관리 버그 | 무효화 누락, stale state | 이름 변경 후 알림 미반영 |
| `platform` | 플랫폼 특이 동작 | Android/iOS 차이, OS 버전 | FCM 백그라운드 제약 |
| `logic` | 비즈니스 로직 오류 | 조건문, 계산, 분기 | 감정 점수 역전 |
| `environment` | 환경 차이 | Debug/Release, 난독화 | Release 빌드 알림 실패 |
| `data` | 데이터 무결성 오류 | null, 형식, 마이그레이션 | DB 스키마 불일치 |
| `integration` | 컴포넌트 통합 이슈 | 레이어 간 계약 위반 | UseCase ↔ Repository 불일치 |
| `ui` | 렌더링/레이아웃 이슈 | 오버플로우, 테마, 반응형 | Column 오버플로우 |

## 프로세스

### Step 1: 이슈 컨텍스트 추출

현재 세션에서 다음 정보를 자동 추출합니다:

```
추출 대상:
├── 버그 증상 (사용자 보고 또는 테스트 실패)
├── 근본 원인 (Stage 2-3 분석 결과)
├── 해결 방법 (Stage 4 구현 내용)
├── 진단 과정 (시도한 가설, 확인/기각 이력)
├── 수정 파일 목록
├── 관련 커밋 해시
└── 교훈 (재발 방지 규칙)
```

**자동 추출 규칙**:
- `/debug` 세션 이력이 있으면 4단계 결과에서 자동 매핑
- 수동 호출 시 대화 컨텍스트에서 추론

### Step 2: ID 및 분류 결정

```
ID 생성 규칙:
- 형식: {증상-키워드}-{환경/조건}
- 예시: notification-not-firing-release
- 예시: provider-stale-after-name-change
- 예시: overflow-diary-list-small-screen

분류 결정 체인:
1. category ← 영향 받는 기능 영역
2. severity ← 사용자 영향도 (critical: 핵심 기능 불가, high: 주요 기능 저하, medium: 불편, low: 미미)
3. platform ← 발생 플랫폼
4. rootCauseType ← Root Cause Taxonomy 매칭
5. confidence ← 원인 확신도 (재현 가능 + 단일 원인 = high)
```

### Step 3: JSON 인덱스 엔트리 추가

`docs/troubleshooting.json`의 `issues[]`에 새 엔트리를 추가합니다.

**필수 필드 체크리스트**:
```
□ id (고유, kebab-case)
□ title (한국어, 명확한 제목)
□ status
□ category + severity + platform + rootCauseType
□ summary + cause + solution (각 한 줄)
□ symptoms[] (최소 2개, 사용자 관점 키워드)
□ tags[] (최소 3개, 기술 키워드)
□ documentation (상세 MD 경로)
□ preventionRule (재발 방지 한 줄)
□ confidence
```

### Step 4: 상세 MD 문서 생성

`docs/troubleshooting/{id}.md` 파일을 아래 템플릿으로 생성합니다:

```markdown
# {제목} 트러블슈팅

> **{status}** | {날짜} | {category} | {platform}

## 문제 요약

| 항목 | 내용 |
|------|------|
| 증상 | {사용자가 경험하는 현상} |
| 환경 | {발생 조건: 기기, OS, 빌드 타입 등} |
| 영향 | {기능적 영향 범위} |
| 심각도 | {severity} |
| 근본 원인 유형 | {rootCauseType} |
| 해결책 | {한 줄 해결책} |

---

## 근본 원인

### 원인 분석
{기술적 원인 상세 설명}

### 데이터 흐름
```
{입력} → {처리1} → {처리2} → {실패 지점} ← 여기서 실패
```

### 증거
{로그, 코드, 상태 등 구체적 증거}

---

## 해결 방법

### 수정 내용
{구체적 코드 변경사항}

### 적용 방법
{실행 명령어, 설정 변경 등}

---

## 진단 과정

### 1차: {초기 조사}
{수행한 조사와 발견}

### 2차: {패턴 비교}
{정상 동작과 비교 결과}

### 3차: {가설 검증}
| 가설 | 결과 | 비고 |
|------|------|------|
| {가설1} | 확인/기각 | {상세} |

---

## 검증 방법

### 자동 검증
```bash
{테스트 명령어}
```

### 수동 검증
{수동 확인 단계}

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| {파일경로} | {역할} |

---

## 교훈

### 재발 방지 규칙
- {preventionRule 상세}

### 일반화된 패턴
- {이 이슈에서 배운 범용적 교훈}

---

## 관련 이슈
- {relatedIssues 링크}

## 관련 커밋
- {commit hash}: {설명}
```

### Step 5: README 업데이트

`docs/troubleshooting/README.md`의 Known Issues 테이블에 새 항목을 추가합니다.

### Step 6: 검증 및 완료

```
검증 체크리스트:
□ JSON이 valid JSON인가? (파싱 테스트)
□ id가 기존 이슈와 중복되지 않는가?
□ documentation 경로에 실제 MD 파일이 존재하는가?
□ relatedIssues의 ID가 실제 존재하는가?
□ README에 항목이 추가되었는가?
□ symptoms 키워드가 검색에 유용한가?
```

## 검색 프로토콜 (Retrieval)

유사 이슈 발생 시 다음 순서로 검색합니다:

```
1. 증상 매칭
   → troubleshooting.json의 symptoms[] 배열에서 키워드 검색
   → 매칭된 이슈 목록 반환

2. 태그 매칭
   → tags[] 배열에서 기술 키워드 검색
   → 1번 결과와 교집합 우선

3. 근본 원인 유형 필터
   → rootCauseType으로 유형별 클러스터링
   → "같은 유형의 이전 이슈" 제시

4. 상세 문서 로드
   → 매칭된 이슈의 documentation 경로 읽기
   → 진단 과정 + 해결 방법 참조

5. 관련 이슈 확장
   → relatedIssues[] 그래프 탐색
   → "함께 보면 좋은 이슈" 제시
```

**검색 트리거 시점**:
- `/debug` Stage 1 시작 시 자동으로 유사 이슈 검색
- "이전에 이런 문제 있었나?" 질문 시
- 에러 메시지/스택트레이스에서 자동 키워드 추출 후 검색

## 출력 형식

### 저장 완료
```
================================================================
              Troubleshooting Memory Saved
================================================================

Index: docs/troubleshooting.json (entry added)
Detail: docs/troubleshooting/{id}.md (created)
README: docs/troubleshooting/README.md (updated)

Entry:
  ID:            {id}
  Title:         {title}
  Category:      {category}
  Severity:      {severity}
  Root Cause:    {rootCauseType}
  Confidence:    {confidence}
  Tags:          [{tags}]
  Prevention:    {preventionRule}

Files:
  + docs/troubleshooting.json (modified)
  + docs/troubleshooting/{id}.md (created)
  + docs/troubleshooting/README.md (modified)

Next:
  git add docs/troubleshooting/
================================================================
```

### 검색 결과
```
================================================================
           Troubleshooting Search Results
================================================================

Query: "{검색 키워드}"
Matches: {N}건

  #1 [{severity}] {title}
     Root Cause: {rootCauseType} | Platform: {platform}
     Symptoms: {symptoms 요약}
     → docs/troubleshooting/{id}.md

  #2 [{severity}] {title}
     ...

Related by Root Cause Type ({rootCauseType}):
  - {같은 유형의 다른 이슈 목록}
================================================================
```

## 사용 예시

### 수동 저장
```
> "/troubleshoot-save notification-cancel-on-boot"

AI 응답:
1. 컨텍스트 추출: 앱 시작 시 selfEncouragementProvider 미전달 → 알림 취소
2. 분류: category=notification, severity=high, rootCauseType=timing
3. JSON 인덱스 추가
4. 상세 MD 문서 생성
5. README 업데이트
6. 완료
```

### 디버깅 후 자동 제안
```
> "/debug" 완료 후...

AI 응답:
"해결된 이슈를 트러블슈팅 메모리에 저장하시겠습니까?"
"추천 ID: provider-stale-after-name-change"
"분류: state / high / both"

> "저장해줘"

→ /troubleshoot-save 자동 실행
```

### 유사 이슈 검색
```
> "/debug 알림이 안 와요"

AI 응답 (Stage 1 시작 전):
"유사 트러블슈팅 기록 발견 (1건):
  [critical] Release 빌드에서 예약 알림 미작동
  Root Cause: config (R8 난독화)
  → docs/troubleshooting/notification-not-firing-release.md

이 이슈와 관련이 있을 수 있습니다. 참조하시겠습니까?"
```

## `/debug` 연계 자동화

### 디버깅 완료 후 자동 감지
```
조건: /debug Stage 4 완료 + 테스트 통과 + 커밋 생성
  → "이 이슈를 트러블슈팅 메모리에 저장할까요?" 자동 제안

자동 매핑:
  /debug Stage 1 Investigation Report → symptoms[], cause
  /debug Stage 2 Pattern Analysis     → rootCauseType, relatedIssues
  /debug Stage 3 Hypothesis Test      → 진단 과정 섹션
  /debug Stage 4 Implementation       → solution, 수정 파일, 커밋
```

### 세션 마무리 연계
```
조건: /session-wrap 실행 시 해결된 이슈 중 미저장 건 감지
  → 후보 목록 제시 → 선택 시 /troubleshoot-save 실행
```

## 연관 스킬
- `/debug` - 4단계 체계적 디버깅 (해결 후 자동 연계)
- `/til-save` - TIL 메모리 저장 (교훈 → TIL, 이슈 전체 → troubleshoot)
- `/session-wrap` - 세션 마무리 (미저장 이슈 감지)
- `/test-unit-gen` - 회귀 테스트 생성 (검증 방법 섹션)

## `/til-save` vs `/troubleshoot-save` 구분

| 항목 | `/til-save` | `/troubleshoot-save` |
|------|-------------|---------------------|
| 대상 | 학습 내용 전반 | 해결된 버그/이슈 전용 |
| 형식 | 자유 형식 MD | 구조화된 JSON + MD |
| 검색 | 파일명 기반 | 태그/증상/원인 인덱스 |
| 저장 | `.claude/memories/` | `docs/troubleshooting/` |
| 수명 | 세션 지식 | 프로젝트 영구 기록 |
| 공유 | 로컬 (git-ignored 가능) | 팀 공유 (git-tracked) |

**경험 법칙**: 버그 해결 → `/troubleshoot-save`, 그 외 학습 → `/til-save`

## 주의사항
- JSON 유효성 검사 필수 (파싱 실패 시 기존 인덱스 손상)
- id 중복 방지: 생성 전 기존 issues[] 확인
- 민감 정보 제외: API 키, 사용자 데이터, 비밀번호 절대 포함 금지
- `SafetyBlockedFailure` 관련 이슈는 `severity: critical` + 보안 태그 필수
- 기존 이슈 업데이트 시 `updatedAt` 갱신
- 너무 사소한 이슈(오타 수정 등)는 저장하지 않음

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | workflow / debugging |
| Dependencies | systematic-debugging, til-save, session-wrap |
| Created | 2026-02-07 |
| Updated | 2026-02-07 |
