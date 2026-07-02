# 현재 작업: 일기 날짜 선택 기능 — 구현 완료, 커밋 대기

## 현재 작업
없음 (세션 종료 — 구현 완료, 커밋/푸시 승인 대기)

## 완료된 항목

### 이번 세션 (2026-07-02)

**일기 작성 날짜 선택 기능 구현 완료** (미커밋)
- 정의: Codex + agy 3-way 교차 검토 → 계획: `.claude/progress/diary-date-picker-plan.md`
- 설계 결정: 단일 `createdAt` 유지(스키마 변경 없음) / 과거 날짜 + 현재 시분초 / DatePicker 하한 5년 / 미래 금지(UI+도메인 이중 차단) / 기본 날짜 화면 진입 시 고정
- 변경: usecase `_resolveCreatedAt()`(Clock 기반) / repository `createdAt` 파라미터화 / `getTodayDiaries()` 상한 방어 / diary_screen 날짜 칩 + showDatePicker / spec.md REQ-001 갱신
- 테스트: 신규 9건 (UseCase 6 + 위젯 3), mocktail stub 23곳 matcher 갱신, 전체 1,711개 통과
- 잠복 버그 수정: `_CountingMock` stub 미매칭인데 우연히 통과하던 문제 (lessons.md 기록)

### 이전 세션 (2026-03-31)
- A11y Sprint 3 L1 완료 (커밋 `743b1e1`, push 완료)

## 다음 단계

1. **[HIGH] 커밋 + 푸시**: 이번 기능 14개 파일 미커밋. 기존 로컬 커밋 2개(c8471d8, a3dde2c)도 푸시 대기
2. **[MED] quality 게이트 기존 블로커 2건**: ① main.dart:4 marionette_flutter import (dev_dependency → --fatal-infos 실패) ② design-audit 기존 위반 38건
3. **[LOW] TIL 후보**: mocktail 시그니처 확장 함정 (lessons.md → TIL 승격 여부)
4. **[LOW] A11y L2/L3**: 실기기 검증 (이월)

## 주의사항

- 날짜 선택은 **생성 시에만** 가능 — 작성 후 날짜 수정은 의도적으로 범위 제외 (edit 플로우 부재)
- `getTodayDiaries()`에 상한(`< 내일 0시`) 추가됨 — 오늘 판정 로직 변경 시 참고
- mock 메서드에 named param 추가 시 모든 when/verify 전수 갱신 필수 (MEMORY.md Testing Patterns)

## 마지막 업데이트: 2026-07-02 / 일기 날짜 선택 구현 완료 (미커밋, HEAD c8471d8)
