---
allowed-tools: Bash(flutter*), Bash(dart*), Read, Grep, Glob
description: 병렬 에이전트 기반 체계적 디버깅
---

## 디버깅 프로세스

대상: $ARGUMENTS

### Phase 1: 병렬 탐색 (3 에이전트 동시 실행)

다음 3개 에이전트를 **병렬**로 실행하세요:

**Agent 1 — 코드 탐색**: 스택트레이스/에러 메시지에서 관련 소스 파일 탐색. 데이터 흐름 추적.
**Agent 2 — 패턴 분석**: 동일 레이어의 정상 동작 코드와 비교. 차이점 발견.
**Agent 3 — 테스트/로그 분석**: 관련 테스트 실행, 실패 패턴 수집, 로그 분석.

### Phase 2: 통합 분석
3개 에이전트 결과를 종합하여:
1. 근본 원인 후보 3개 (우선순위별)
2. 각 후보의 증거와 검증 방법

### Phase 3: 가설 검증 + 수정
.claude/skills/systematic-debugging.md의 Stage 3-4를 따라 실행.

IMPORTANT: 코드 수정 전 반드시 원인 분석 결과를 먼저 보고할 것.
