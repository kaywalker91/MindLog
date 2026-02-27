# MindLog 태스크 추적 (tasks.md)

**최종 업데이트**: 2026-02-27 (아카이브 정책 적용 — 완료 태스크 → history.md)
**현재 버전**: v1.4.48

> SDD 워크플로우 포맷: `TASK-XXX (REQ-YYY): 설명`
> 새 태스크는 이 파일에 추가 후 코드 작성 시작.
> 완료된 태스크 이력 → `docs/tasks/history.md`

---

## 진행 중 (In Progress)

_현재 없음_

---

## 백로그 (Pending)

_현재 없음_

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
5. /session-wrap 또는 릴리스 시 → docs/tasks/history.md로 이동 (150줄 상한)
```
