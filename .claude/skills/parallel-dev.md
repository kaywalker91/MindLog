# parallel-dev

일상 작업 병렬화 스킬 (`/parallel-dev [task-description]`)

## 목표
- 일반적인 개발 작업을 자동으로 병렬 분할
- 탐색 + 구현 + 검증을 동시 진행
- 개발 속도 향상 및 더 나은 결과물

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/parallel-dev [작업 설명]` 명령어
- "병렬로 개발해줘" 요청
- 독립적 작업이 2개 이상 식별되는 경우

## 프로세스

### Step 1: 작업 분석
```
입력: /parallel-dev "일기 내보내기 기능 추가"

분석:
1. 작업 유형 판별 (탐색/구현/리팩토링/버그수정)
2. 독립 작업 식별
3. 병렬화 전략 결정
```

### Step 2: 에이전트 역할 분배

#### 패턴 A: 탐색형 (2-3 에이전트)
```
작업: 버그 조사, 기존 코드 이해

Agent 1 (Explorer): 관련 코드 탐색
  - subagent_type: Explore
  - 대상 파일/패턴 검색
  - 의존성 맵핑

Agent 2 (Analyzer): 로직 분석
  - subagent_type: general-purpose
  - 동작 흐름 추적
  - 문제 지점 식별

Agent 3 (Researcher): 외부 정보 수집 (선택적)
  - subagent_type: general-purpose
  - 유사 사례 검색
  - 베스트 프랙티스 조사
```

#### 패턴 B: 구현형 (2-3 에이전트)
```
작업: 새 기능 구현

Agent 1 (Planner): 설계 및 계획
  - subagent_type: Plan
  - 아키텍처 설계
  - 파일 구조 계획

Agent 2 (Scaffolder): 보일러플레이트 생성
  - subagent_type: general-purpose
  - Entity, Repository 틀 생성
  - Provider 스켈레톤

Agent 3 (Tester): 테스트 템플릿 준비
  - subagent_type: general-purpose
  - 테스트 구조 작성
  - Mock 객체 준비
```

#### 패턴 C: 리팩토링형 (2-4 에이전트)
```
작업: 대규모 코드 정리

Agent 1-N (Workers): 파일별 독립 수정
  - 각 에이전트에 1-2개 파일 할당
  - 동일 파일 수정 금지
  - 완료 후 통합 검증
```

### Step 3: 병렬 실행
```dart
// 반드시 단일 메시지에서 여러 Task 호출
Task 1: Agent 1 실행
Task 2: Agent 2 실행
Task 3: Agent 3 실행 (해당되는 경우)
```

### Step 4: 결과 통합
```
각 에이전트 결과 수집:
1. 중복 제거
2. 충돌 해결
3. 우선순위 정렬
4. 최종 실행 계획 수립
```

### Step 5: 실행 및 검증
```
통합된 결과를 바탕으로:
1. 코드 작성/수정
2. flutter analyze
3. flutter test
4. 결과 리포트
```

## 출력 형식

### 진행 상태
```
═══════════════════════════════════════════════════════════
            Parallel Development: 일기 내보내기
═══════════════════════════════════════════════════════════

패턴: 구현형 (3 에이전트)

Agent Status:
├── [v] Planner          완료 (설계 완료)
├── [>] Scaffolder       진행 중...
└── [>] Tester           진행 중...

현재: 코드 스캐폴딩 + 테스트 템플릿 생성
```

### 최종 리포트
```
═══════════════════════════════════════════════════════════
         Parallel Development Complete
═══════════════════════════════════════════════════════════

작업: 일기 내보내기 기능 추가
패턴: 구현형
에이전트: 3개

결과 요약
├── 설계: Clean Architecture 기반 5개 레이어
├── 생성 파일: 6개
├── 테스트 템플릿: 3개
├── flutter analyze: 통과
└── flutter test: 통과

다음 단계
├── 생성된 스켈레톤에 실제 로직 추가
├── 테스트 케이스 구체화
└── UI 구현
═══════════════════════════════════════════════════════════
```

## 사용 예시

### 버그 조사
```
> "/parallel-dev 통계 화면이 가끔 빈 데이터를 보여주는 문제 조사"

AI 응답:
1. 패턴 결정: 탐색형
2. 3개 에이전트 병렬 실행:
   - Explorer: statistics_providers.dart 관련 코드 탐색
   - Analyzer: 데이터 흐름 추적
   - Researcher: 유사 이슈 검색
3. 결과 통합: 원인 후보 3가지 식별
4. 우선순위: autoDispose 타이밍 문제 가장 유력
```

### 기능 구현
```
> "/parallel-dev 일기 PDF 내보내기 기능"

AI 응답:
1. 패턴 결정: 구현형
2. 3개 에이전트 병렬 실행:
   - Planner: 아키텍처 설계
   - Scaffolder: 코드 틀 생성
   - Tester: 테스트 준비
3. 결과 통합
4. 스켈레톤 코드 완성
```

## 수동 병렬화와의 차이점

| 항목 | 수동 | `/parallel-dev` |
|------|------|-----------------|
| 작업 분석 | 사용자 | 자동 |
| 역할 분배 | 사용자 | 패턴 기반 자동 |
| 결과 통합 | 사용자 | 자동 |
| 적합 용도 | 복잡한 커스텀 | 일반적인 작업 |

## 연관 스킬
- `/swarm-review` - 리뷰 특화 병렬 (3명 고정)
- `/swarm-refactor` - 리팩토링 특화 병렬
- `/feature-pipeline` - 전체 개발 파이프라인

## 주의사항
- 단순 작업에는 오버헤드 발생 (파일 1-2개 수정 등)
- 의존성 있는 작업은 자동으로 순차 처리
- 충돌 감지 시 수동 해결 요청

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | workflow |
| Dependencies | - |
| Created | 2026-02-03 |
| Updated | 2026-02-03 |
