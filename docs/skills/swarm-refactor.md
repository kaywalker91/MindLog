# swarm-refactor

자기조직화 리팩토링 Swarm 스킬 (`/swarm-refactor [scope] [strategy]`)

## 목표
- 대규모 리팩토링을 파일별 독립 작업으로 분해
- 여러 에이전트가 독립 작업을 병렬 수행
- 완료 후 통합 테스트로 일관성 검증

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/swarm-refactor [scope] [strategy]` 명령어
- "대규모 리팩토링 실행해줘" 요청
- `/refactor-plan` 결과에서 독립 파일 다수 발견 시

## Scope 옵션
| Scope | 설명 | 예시 |
|-------|------|------|
| `providers` | Provider 파일 리팩토링 | `/swarm-refactor providers centralize` |
| `widgets` | 위젯 파일 리팩토링 | `/swarm-refactor widgets decompose` |
| `usecases` | UseCase 파일 리팩토링 | `/swarm-refactor usecases standardize` |
| `[directory]` | 특정 디렉토리 | `/swarm-refactor lib/data/ cleanup` |

## Strategy 옵션
| Strategy | 설명 |
|----------|------|
| `centralize` | 분산된 로직 중앙화 |
| `decompose` | 대형 파일/위젯 분해 |
| `standardize` | 패턴 표준화 적용 |
| `cleanup` | 불필요 코드 정리 |

## 프로세스

### Step 1: 리더 분석
리더 에이전트가 리팩토링 대상과 작업 단위를 결정합니다.

```
1. 대상 파일 스캔
   - scope에 해당하는 파일 수집
   - 각 파일의 현재 상태 분석 (심볼 개요)

2. 독립성 판단
   - 파일 간 import 의존성 분석
   - 독립적으로 수정 가능한 파일 그룹 식별
   - 순서 의존성이 있는 파일 체인 식별

3. 작업 분배 계획
   - 독립 파일: 병렬 Task 생성
   - 의존 파일: blockedBy 체인으로 순차 Task 생성
   - 각 Task에 구체적 리팩토링 지시사항 포함
```

### Step 2: Task 생성
```
예시: /swarm-refactor widgets decompose

Task 1: "Decompose: home_screen.dart"           (독립)
Task 2: "Decompose: diary_detail_screen.dart"    (독립)
Task 3: "Decompose: settings_screen.dart"        (독립)
Task 4: "Decompose: analysis_screen.dart"        (독립)
Task 5: "Update: barrel exports"                 (blockedBy: 1,2,3,4)
Task 6: "Verify: integration test"               (blockedBy: 5)
```

### Step 3: Worker 에이전트 병렬 실행
독립 Task들을 병렬로 실행합니다.

```
각 Worker의 실행 프로세스:
1. Task 내용 확인 (TaskGet)
2. 대상 파일 읽기
3. strategy에 따른 리팩토링 수행
4. 변경 사항 적용
5. 해당 파일 단위 테스트 실행
6. Task 완료 표시 (TaskUpdate)
```

병렬 실행 규칙:
- 독립 Task들은 동시에 Task 도구로 실행 (최대 4개)
- 각 Worker는 자신의 Task 파일만 수정
- 다른 Worker의 파일을 수정하지 않음

### Step 4: 통합 검증
모든 Worker 완료 후:

```
1. barrel export 업데이트 (필요시)
2. flutter analyze 실행
3. flutter test 실행 (전체)
4. 실패 시: 충돌 파일 식별 → 수동 해결 요청
```

### Step 5: 결과 리포트

## 출력 형식

### 진행 상태
```
═══════════════════════════════════════════════════════════
           Swarm Refactor: widgets / decompose
═══════════════════════════════════════════════════════════

Phase: Worker 실행 중 (3/4 완료)

Task Status:
├── [v] Task 1: home_screen.dart          완료 (3 위젯 추출)
├── [v] Task 2: diary_detail_screen.dart  완료 (2 위젯 추출)
├── [v] Task 3: settings_screen.dart      완료 (4 위젯 추출)
├── [>] Task 4: analysis_screen.dart      진행 중...
├── [ ] Task 5: barrel exports            대기
└── [ ] Task 6: integration test          대기
```

### 최종 리포트
```
═══════════════════════════════════════════════════════════
        Swarm Refactor Complete: widgets / decompose
═══════════════════════════════════════════════════════════

결과 요약
├── 리팩토링 파일: 4개
├── 신규 생성 파일: 9개 (추출된 위젯)
├── 삭제 코드: ~320줄
├── 추가 코드: ~180줄 (순감소 140줄)
├── flutter analyze: 통과
└── flutter test: 48/48 통과

파일별 결과
├── home_screen.dart
│   ├── 추출: HomeHeader, HomeStats, HomeDiaryList
│   └── 라인: 280줄 → 95줄
├── diary_detail_screen.dart
│   ├── 추출: DiaryContent, DiaryMoodChart
│   └── 라인: 210줄 → 85줄
├── settings_screen.dart
│   ├── 추출: ThemeSection, NotificationSection, DataSection, AboutSection
│   └── 라인: 350줄 → 90줄
└── analysis_screen.dart
    ├── 추출: EmotionTrendChart, InsightCard
    └── 라인: 190줄 → 75줄

다음 단계
├── 추출된 위젯 Widget 테스트 추가 권장
├── /coverage 실행으로 커버리지 확인
└── git commit 준비 완료
═══════════════════════════════════════════════════════════
```

## 사용 예시

### 위젯 분해
```
> "/swarm-refactor widgets decompose"

AI 응답:
1. 리더 분석: 대형 위젯 4개 식별
2. 독립성 판단: 4개 모두 독립 수정 가능
3. 4개 Worker 병렬 실행
4. 통합 검증: analyze + test 통과
5. 리포트 출력
```

### Provider 중앙화
```
> "/swarm-refactor providers centralize"

AI 응답:
1. 리더 분석: 분산 Provider 5개 식별
2. 의존성 분석: 2개 독립, 3개 순차 필요
3. 독립 2개 병렬 실행 → 순차 3개 실행
4. 통합 검증
5. 리포트 출력
```

## 독립성 판단 기준

파일이 독립적으로 리팩토링 가능한 조건:
1. **다른 대상 파일을 import하지 않음** (core/ 공유 코드는 예외)
2. **수정이 파일 내부에 국한됨** (public API 변경 없음)
3. **테스트가 독립 실행 가능**

순서 의존성이 있는 경우:
1. **파일 A의 export를 파일 B가 사용** → A 먼저
2. **barrel export 파일 변경 필요** → 모든 개별 파일 완료 후
3. **공유 인터페이스 변경** → 인터페이스 먼저, 구현체 후

## 연관 스킬
- `/refactor-plan` - 리팩토링 계획 수립 (사전 분석용)
- `/widget-decompose` - 단일 위젯 분해 (개별 실행용)
- `/provider-centralize` - Provider 분석 (사전 분석용)
- `/arch-check` - 아키텍처 검증 (사후 검증용)
- `/swarm-review` - 병렬 리뷰 (사후 리뷰용)

## 주의사항
- 병렬 Worker 수는 최대 4개 (리소스 제한)
- 각 Worker는 자신의 대상 파일만 수정 (충돌 방지)
- 통합 테스트 실패 시 수동 해결 필요
- SafetyBlockedFailure 관련 파일은 자동 리팩토링 대상에서 제외
- 대규모 리팩토링은 `/refactor-plan`으로 먼저 계획 수립 권장

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P2 |
| Category | quality |
| Dependencies | refactor-plan, widget-decompose, provider-centralize |
| Created | 2026-01-27 |
| Updated | 2026-01-27 |
