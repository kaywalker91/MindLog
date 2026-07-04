# P1 다음 세션 프롬프트 — 알림 큐 diff + Groq 파싱 Isolate

## 사용법
새 Claude Code 세션을 열고 아래 "📋 프롬프트" 섹션의 코드블록을 그대로 복사 → 붙여넣기 하세요.

---

## 📋 프롬프트

```
P1 성능 개선을 진행해줘. 직전 세션에서 P0 (측정 인프라 + Groq 캐싱 + 목록 낙관적 갱신) 커밋 70c8cfa 완료. 계획 파일은 /Users/kaywalker/.claude/plans/buzzing-gathering-bengio.md 참고.

## 컨텍스트 (직전 세션 결과)
- Claude × Gemini × Codex 3-way 합의로 P0 완료, 1681 테스트 그린
- Firebase Performance 측정 인프라 가동 가능
- Groq 응답은 SQLite v8 groq_analysis_cache 테이블에 sha256 content-hash로 캐싱 (위기응답 제외, LRU 1000건)
- DiaryListController.addOrUpdateDiary로 분석 후 풀스캔 제거됨
- TaskCreate로 작업 추적, TDD RED-GREEN 사이클 준수, mocktail + AAA 패턴

## 이번 세션 목표

### P1-1 알림 큐 diff 알고리즘 (높은 우선순위)
**문제**: lib/core/services/notification_settings_service.dart의 applySettings()는 매 호출마다 7일 Cheer Me 큐 전체를 cancel + reschedule. payload 변경 없을 때도 platform channel 호출 14회 발생.

**해결**:
1. NotificationService.getPendingNotifications() 결과를 파싱해 현재 예약 상태 Map<int, ScheduledPayload> 추출 (id, title, body, scheduledAt 시그니처)
2. 새 plan과 비교:
   - 사라진 알림: cancel
   - 신규 또는 시그니처 변경된 알림만: cancel + reschedule
   - 변경 없음: 호출 0건
3. Codex가 합의안에서 제안한 diff 스케치 사용 (계획 파일 Phase 2 Codex 섹션 참고)

**ID 안정성 (Gemini 지적 반영)**: 일기 ID/날짜 기반 결정적 ID 생성, 재계산마다 변경 금지.

**Acceptance**:
- 동일 plan 두 번 적용 → cancel/schedule 호출 0건 (테스트로 검증)
- payload 일부만 변경 → 변경분만 reschedule (호출 횟수 검증)
- 기존 7일 Cheer Me 동작은 그대로 유지 (회귀 0건)
- Performance trace `notification.applySettings` 추가 (P0-1 인프라 활용)

**예상 변경 파일**:
- lib/core/services/notification_settings_service.dart (applySettings, requiresCheerMeQueueRebuild)
- lib/core/services/notification_service.dart (getPendingNotifications 노출 또는 헬퍼 추가)
- 신규: lib/core/services/notification_diff_planner.dart (순수 함수, 테스트 용이)
- test/core/services/notification_diff_planner_test.dart (RED 선행)
- test/core/services/notification_settings_service_test.dart (회귀 보강)

### P1-2 Groq JSON 파싱 Isolate 오프로드 (Gemini 단독 지적)
**문제**: AnalysisResponseParser.parse()가 메인 isolate에서 실행. Vision 응답(1500토큰, 4KB+) 파싱 시 jank 가능성.

**해결**:
1. lib/data/dto/analysis_response_parser.dart 의 parseString을 isolate-safe하게 분리 (top-level 함수 또는 static)
2. lib/data/datasources/remote/groq_remote_datasource.dart의 _analyzeDiaryOnce, _analyzeDiaryWithImagesOnce에서:
   - 응답 raw string 길이 임계치 (예: 4096 bytes) 초과 시에만 compute() 사용
   - 그 이하는 메인에서 직접 (isolate spawn 비용 회피)
3. compute() 호출은 try/catch로 감싸 실패 시 메인 fallback

**Acceptance**:
- 4KB 이상 응답에서 compute() 사용 검증 (테스트 가능 시)
- 기존 파싱 결과와 동일 (DTO 동등성)
- 파싱 실패 동작 보존 (ApiException 던짐)

**예상 변경 파일**:
- lib/data/dto/analysis_response_parser.dart (top-level _parseAnalysisJson 함수 추출)
- lib/data/datasources/remote/groq_remote_datasource.dart (compute 분기 추가)
- test/data/dto/analysis_response_parser_test.dart (회귀)

## 작업 절차
1. TaskCreate로 P1-1, P1-2 task 생성
2. P1-1부터 시작:
   - lib/core/services/notification_settings_service.dart 와 notification_service.dart 먼저 읽고 현재 cancel/schedule 흐름 파악
   - notification_diff_planner.dart RED 테스트 작성 (동일 plan → 호출 0, 부분 변경 → 변경분만)
   - GREEN 구현
   - applySettings에 통합 + 회귀 테스트
3. P1-2:
   - parser 함수 추출 (top-level)
   - compute 분기 + 임계치 설정
   - 회귀 테스트
4. flutter analyze + flutter test 전체 실행
5. 결과 브리핑 후 커밋 승인 요청 (P0 패턴과 동일)

## 제약·주의사항
- SafetyBlockedFailure 로직 절대 수정 금지
- DB 스키마 변경 없음 (P1은 in-memory + 알고리즘 작업)
- 기존 알림 ID 매핑 (1001 CheerMe, 2001 FCM 마음케어 등) 유지 — MEMORY.md 표 참조
- ID 결정성: 동일 입력은 동일 ID 산출 (재계산 시 ID 변동 → 중복 알림 발생 위험)
- TDD: domain/service 레이어 → RED 선행 필수
- Auto mode 권장 안함 — 알림은 사용자 영향 큼, 단계별 승인 받으며 진행

## 참고 파일
- 계획 전문: /Users/kaywalker/.claude/plans/buzzing-gathering-bengio.md
- P0 커밋: 70c8cfa (`git show 70c8cfa --stat`)
- 알림 ID 표: ~/.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/MEMORY.md
- Codex diff 스케치: 계획 파일 Phase 2 Codex 섹션
```

---

## 옵션
- 미커밋 잔존 파일(`.gitignore`, `.serena/project.yml`)은 P1과 무관 — 시작 전 별도 chore 커밋 또는 stash 처리 권장
- P1 완료 후 P2 (위젯 분해, PNG→WebP, LoadingIndicator 단순화)는 별도 세션 권장 — 성격이 UI 리팩토링이라 분리하는 게 리뷰 효율↑

## 예상 소요
- P1-1: 1.5~2시간 (테스트 포함)
- P1-2: 0.5~1시간
- 총 ~3시간, 단일 세션 가능
