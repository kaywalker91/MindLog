# 일기 작성 날짜 선택 기능 — 정의 및 수정 계획

작성: 2026-07-02 (Claude + Codex + agy 3-way 교차 검토 완료)
상태: **구현 완료 (2026-07-02)** — 권고안(D1 단일 createdAt / D2 현재 시분초 / D3 5년) 채택.
전체 테스트 1,711개 통과. UseCase 테스트 6건 + 위젯 테스트 3건 신규.
미커밋 — 사용자 커밋/푸시 승인 대기.

## 1. 기능 정의 (합의된 요구사항)

- 일기 작성 화면에서 작성 날짜를 선택할 수 있다. **기본값은 오늘.**
- **미래 날짜 금지** — UI(DatePicker lastDate)와 도메인(UseCase 검증) 양쪽에서 차단.
- 과거 하한: DatePicker `firstDate = 오늘 - 5년` (백필 허용, 무제한 금지).
- 기본 날짜는 **작성 화면 진입 시점에 고정** (자정 넘김 시 기본값이 내일로 바뀌는 것 방지).
- 오늘이 아닌 날짜 선택 시 날짜 칩에 시각적 구분 ("어제 (7월 1일)" 상대 표기 + 강조색).
- **작성 후 날짜 수정은 이번 범위 제외** (edit 플로우 자체가 없음 — 별도 기능으로).

## 2. 설계 결정 (Claude 권고 — 사용자 확인 필요)

| # | 쟁점 | Codex | agy | Claude 권고 |
|---|------|-------|-----|------------|
| D1 | entryDate/createdAt 분리 | 분리 (스키마 v+1 마이그레이션) | 단일 createdAt 유지 | **단일 createdAt 유지** — 로컬 단독 앱 + edit 부재 + 소비처 전부 재사용 가능. 분리는 마이그레이션 + 통계/streak/캘린더/오늘감정 전면 재배선 비용이 이득 대비 큼. 추후 서버 동기화 도입 시 재검토 |
| D2 | 과거 날짜의 시각 저장 | 정오 고정 12:00 | 선택날짜 + 현재 시각(시분초) | **선택날짜 + 현재 시분초** — 같은 날 복수 일기의 실제 작성 순서 보존, 정오 고정은 동순위 발생 |
| D3 | DatePicker 하한 | 5~10년 | 1년 | **5년** |

## 3. 구현 계획 (Phase별)

### Phase 0 — 스펙 (SDD)
- `docs/spec.md` REQ-001에 날짜 선택 요구사항 추가 (기본 오늘, 미래 금지, 하한 5년)

### Phase 1 — 도메인/데이터 (날짜 파라미터화)
- `lib/domain/repositories/diary_repository.dart:10` — `createDiary(content, {imagePaths, DateTime? entryDate})`
- `lib/domain/usecases/analyze_diary_usecase.dart:38` — `execute(..., {DateTime? entryDate})`
  - 미래 날짜 → `ValidationFailure` (도메인 레벨 방어)
  - 날짜 확정 로직: null 또는 오늘 → `_clock.now()` / 과거 → `DateTime(y,m,d) + _clock.now()의 시분초` (기존 주입된 Clock 활용)
- `lib/data/repositories/diary_repository_impl.dart:34` — `DateTime.now()` 하드코딩 제거, 파라미터 수신
- `lib/data/datasources/local/sqlite_local_datasource.dart:271` — `getTodayDiaries()`에 `< 내일 0시` 상한 추가 (방어)
- DB 스키마 변경 **없음** (D1 채택 시)

### Phase 2 — Presentation
- `lib/presentation/providers/diary_analysis_controller.dart:59` — `analyzeDiary(..., {DateTime? entryDate})`
- `lib/presentation/screens/diary_screen.dart` — 날짜 칩 위젯 + `showDatePicker` (firstDate: -5y, lastDate: 오늘)
  - 화면 진입 시 `_selectedDate = 오늘` 고정 (State initState)
  - 오늘 아님 → 칩 강조 (텍스트는 `AppColors.primaryDark` — primary 직접 사용 금지 규칙)
  - 다크모드 대응 확인 (`/ui-dark-mode` 체크)

### Phase 3 — 파급 방어 검증
- 작성 완료 후 provider 무효화 체인: statistics / 캘린더 마커 / today_emotion / streak — `/provider-invalidation-audit`
- 알림 큐(감정 트렌드): 과거 백필이 이상 알림을 예약하지 않는지 확인 (트렌드 계산이 최근 기간 한정인지 검증)
- `today_emotion_provider` — 과거 날짜 일기가 오늘 감정에 섞이지 않음 확인 (연/월/일 비교라 자동 배제됨, 테스트로 고정)

### Phase 4 — 테스트/품질
- UseCase 단위 테스트: FixedClock으로 기본값/과거/미래거부/자정경계 4케이스
- DiaryScreen 위젯 테스트: 기본 오늘 표시, DatePicker 열기, 과거 선택 시 칩 변화
- `./scripts/run.sh quality` 통과

## 4. 영향 파일 요약
핵심 5개: diary_repository.dart / analyze_diary_usecase.dart / diary_repository_impl.dart / diary_analysis_controller.dart / diary_screen.dart
방어 2개: sqlite_local_datasource.dart (getTodayDiaries 상한), spec.md
테스트: analyze_diary_usecase_test, diary_screen 위젯 테스트

## 5. 원본 검토 자료
- 공통 브리프: `.claude/tmp/date-picker-feature-brief.md`
- Codex/agy 응답: 세션 로그 (핵심 쟁점은 위 표에 반영됨)
