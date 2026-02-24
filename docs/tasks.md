# MindLog 태스크 추적 (tasks.md)

**최종 업데이트**: 2026-02-24
**현재 버전**: v1.4.46

> SDD 워크플로우 포맷: `TASK-XXX (REQ-YYY): 설명`
> 새 태스크는 이 파일에 추가 후 코드 작성 시작.

---

## 진행 중 (In Progress)

_현재 없음_

---

## 백로그 (Pending)

### 버그 수정

- [ ] **TASK-001** (REQ-070): `cancelFollowup` 테스트 `LateInitializationError` 수정
  - 파일: `test/presentation/screens/diary_creation_flow_test.dart`
  - 원인: Static service 모킹 패턴 미적용 (`@visibleForTesting static Function? override`)
  - 참조: `docs/plan.md` 섹션 7 "Static Service 모킹" 패턴

### 품질 개선

- [ ] **TASK-002** (REQ-020~023): StatisticsScreen 위젯 테스트 추가
  - 현재 커버리지: 추정 < 70%
  - 목표: 주요 차트 렌더링 + 기간 선택 인터랙션 테스트

- [ ] **TASK-003** (REQ-064): EmotionAware UseCase 통합 테스트
  - 현재: 단위 테스트 완료 (`get_next_self_encouragement_message_usecase_test.dart`)
  - 추가: 알림 스케줄러와 연계된 end-to-end 테스트

---

## 완료 (Completed)

- [x] **TASK-P01** (REQ-064): `GetNextSelfEncouragementMessageUseCase` EmotionAware 구현
  - 완료: v1.4.46 (2026-02-24)
  - 버킷: score≤3→low, ≤6→medium, >6→high; 폴백: 전체 랜덤

- [x] **TASK-P02** (REQ-040, REQ-041): 중복 알림 방지 (CheerMe + FCM Mindcare)
  - 완료: v1.4.45 (2026-02-11)
  - 고정 ID: 2001(FCM), 덮어쓰기로 중복 방지

- [x] **TASK-P03** (REQ-044): NotificationScheduler 아키텍처 리팩토링
  - 완료: v1.4.46
  - Port/Adapter 패턴 적용: domain interface → core 구현

- [x] **TASK-P04** (REQ-045): 자기격려 메시지 순차 로테이션 lastDisplayedIndex 보정
  - 완료: v1.4.x
  - 삭제 후 index wrap-around 처리

---

## 향후 기능 (Future, REQ 미부여)

새 기능 개발 시 `docs/spec.md`에 REQ ID를 먼저 추가한 뒤 이 목록에서 TASK로 격상.

- [ ] 감정 일기 내보내기 (PDF/텍스트)
- [ ] 클라우드 백업 / 멀티 디바이스 동기화
- [ ] 다국어 지원 (한국어 외)
- [ ] 홈 화면 위젯 (감정 상태 표시)
- [ ] iOS 배포 (현재 Android 전용)

---

## 태스크 추가 가이드

```
1. docs/spec.md 에서 해당 REQ ID 확인 (없으면 먼저 추가)
2. docs/tasks.md 백로그에 TASK-XXX 추가
3. 코드 작성 시작
4. 완료 후 [x] 처리 + 버전/날짜 기록
```
