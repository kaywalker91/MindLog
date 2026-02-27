# 멀티 문서 동기화 파이프라인 갭 분석 방법론

**분류**: Claude Code / Workflow / Process Design
**난이도**: 중급
**예상 소요**: 15분
**최종 업데이트**: 2026-02-27
**사례**: session-wrap G-1~G-7 갭 분석

---

## 배경

`/session-wrap`은 세션 종료 시 지식을 보존하는 핵심 파이프라인이다.
하지만 7개의 구조적 결함(G-1~G-7)이 발견되어 체계적 갭 분석 후 수정했다.
이 TIL은 멀티 문서 동기화 파이프라인의 갭을 찾고 수정하는 방법론을 기록한다.

---

## 갭 분류 프레임워크

### 3차원 평가
| 차원 | 기준 | 등급 |
|------|------|------|
| 심각도 | 파이프라인 실패 여부 | HIGH / MEDIUM / LOW |
| 구현 비용 | 수정에 필요한 작업량 | 낮음 / 중간 / 높음 |
| ROI | (심각도 x 빈도) / 비용 | HIGH / MEDIUM / LOW |

### 우선순위 매트릭스
```
ROI HIGH + 비용 낮음  → P0 (즉시)
ROI HIGH + 비용 중간  → P1 (이번 세션)
ROI MEDIUM           → P2 (다음 세션)
ROI LOW              → P3 (백로그)
```

---

## session-wrap 갭 분석 결과

| Gap | 내용 | 심각도 | 비용 | 우선순위 | 상태 |
|-----|------|--------|------|----------|------|
| G-1 | commands vs skills 파일 불일치 | HIGH | 낮음 | P0 | 수정 완료 |
| G-2 | MEMORY.md 자동 업데이트 없음 | HIGH | 중간 | P1 | 수정 완료 |
| G-3 | progress/current.md 미동기화 | MEDIUM | 낮음 | P1 | 수정 완료 |
| G-4 | TIL INDEX 동기화 누락 | MEDIUM | 낮음 | P2 | 수정 완료 |
| G-5 | CHANGELOG 미연동 | LOW | 낮음 | P3 | 백로그 |
| G-6 | 에이전트 데이터 중복 | LOW | 높음 | P4 | 백로그 |
| G-7 | 메모리 파일 폭증 방지 없음 | LOW | 중간 | P3 | 수정 완료 |

---

## 핵심 발견: G-1이 가장 위험했던 이유

G-1 (commands vs skills 불일치)는 심각도 HIGH이지만 구현 비용은 2줄 수정이다.
이 갭이 위험한 이유:

```
사용자: "/session-wrap" 입력
Claude: commands/session-wrap.md 읽음
        → "Read @agents/session-wrap/*.md" ← 존재하지 않는 경로!
        → 파이프라인 전체 실패
```

**핵심 교훈**: 라이트웨이트 래퍼(commands)와 실제 로직(skills)이 분리된 구조에서는
래퍼 파일 동기화가 가장 먼저 깨진다.

---

## 멀티 문서 동기화 패턴

### "Last-Mile 파일" 갱신 누락 안티패턴

자동화 파이프라인에서 가장 흔히 누락되는 것:
```
작업 수행 → 주 파일 업데이트
                           └─ 인덱스/레지스트리 업데이트 (Last-Mile 파일) ← 누락!
```

MindLog 사례:
- TIL 파일 생성 → `docs/til/INDEX.md` 업데이트 누락 (G-4)
- lessons.md 기록 → `MEMORY.md` 전파 누락 (G-2)
- 세션 작업 완료 → `progress/current.md` 업데이트 누락 (G-3)

### 해결 패턴: 단계별 동기화 체크포인트

각 주요 작업 완료 시 연관 인덱스/레지스트리도 함께 업데이트하는 체크포인트 삽입:

```
session-wrap Step 5: lessons.md 업데이트
session-wrap Step 5.5: → MEMORY.md 전파 체크 ← 체크포인트
session-wrap Step 6: tasks.md 동기화
session-wrap Step 6.5: → progress/current.md 갱신 ← 체크포인트
session-wrap Step 7: 다음 액션 제안
session-wrap Step 7.5: → TIL INDEX 동기화 ← 체크포인트
```

---

## 갭 발견 방법론 (재사용 가능)

1. **파이프라인 맵 작성**: "데이터가 A → B → C로 흐르는가?" 시각화
2. **수동 의존 지점 식별**: "이 전환이 사람이 수동으로 해야 하는가?"
3. **실패 시나리오 작성**: 각 스텝에서 실패하면 어떤 파일이 stale 상태가 되는가?
4. **심각도 평가**: stale 파일이 다음 세션에 얼마나 피해를 주는가?

---

## 교훈

1. **파이프라인 설계 시 "last-mile 파일"을 명시적으로 나열하라** — 자동화 시 가장 먼저 누락됨
2. **commands 파일은 skills 파일의 단순 래퍼여야 한다** — 로직을 commands에 두면 분기 발생
3. **갭 발견은 실제 사용 중 증상에서 시작된다** — G-2는 "lessons에 기록했는데 다음 세션에 없었다"는 사용자 경험에서 발견

---

## 참조

- `.claude/skills/session-wrap.md` — 7+3 Step 구현 (G-1~G-7 수정 포함)
- `.claude/commands/session-wrap.md` — 단순 래퍼 (G-1 수정 결과)
- `memory/archiving-policy.md` — G-7 결과물
