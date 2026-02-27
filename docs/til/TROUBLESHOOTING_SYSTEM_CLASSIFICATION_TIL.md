# 트러블슈팅 지식 시스템 분류 프레임워크 TIL

> **생성일**: 2026-02-27
> **카테고리**: knowledge-management, process
> **적용 범위**: MindLog 모든 개발 세션

---

## 문제 상황

프로젝트에 버그 수정 및 패턴 발견 내역을 기록하는 세 가지 시스템이 존재했으나,
각 시스템의 **역할 경계가 불명확**하여 정보가 한 곳에만 기록되고 나머지는 누락되는 드리프트 현상 발생.

**증상**:
- FCM body 공백 버그 → `lessons.md`에만 기록, `troubleshooting.json`은 2개월 stale
- 신규 개발자가 기존 이슈 해결책을 찾지 못해 중복 디버깅
- `/debug` 스킬이 기존 해결책을 자동 참조하지 않음

---

## 핵심 학습: 3-System 분류 원칙

### 시스템 역할 정의

| 시스템 | 파일 | 대상 독자 | 목적 |
|--------|------|----------|------|
| **troubleshooting.json + /{id}.md** | `docs/troubleshooting/` | 외부 개발자, 사용자 | 프로덕션 버그 검색 가이드 |
| **docs/til/** | `INDEX.md` + 개별 파일 | 내부 개발자 | 재현 가능 기술 HOW-TO |
| **tasks/lessons.md** | 단일 파일 | Claude (AI) | 자기 수정 교훈 |

### 판단 트리 (Decision Tree)

```
버그/패턴 발생
    ↓
프로덕션 앱 동작에 영향?
    ├─ YES → troubleshooting.json + /{id}.md 생성
    │        + tasks/lessons.md 기록
    └─ NO (dev-time only)
         ↓
       재현 가능 기술 패턴?
         ├─ YES → docs/til/{TOPIC}_TIL.md 생성
         │        + tasks/lessons.md 기록
         └─ NO (Claude 내부 실수) → tasks/lessons.md 기록 only
```

**중복 허용**: 프로덕션 버그 → troubleshooting.json AND lessons.md 모두 기록.
**교차 허용**: 동일 주제가 TIL + lessons.md에 모두 있어도 무방 (독자 대상이 다름).

---

## 실제 적용 예시

### 프로덕션 영향 버그 → troubleshooting.json

| 항목 | 분류 | troubleshooting.json | docs/til/ | lessons.md |
|------|------|---------------------|-----------|------------|
| FCM body 빈 문자열 | 프로덕션 영향 | ✅ | ❌ | ✅ |
| R8 난독화 알림 미작동 | 프로덕션 영향 | ✅ | ❌ | ✅ |
| flutter_animate pumpAndSettle | dev/테스트 패턴 | ❌ | ✅ | ✅ |
| 정적 서비스 오버라이드 패턴 | dev/테스트 패턴 | ❌ | ✅ | ✅ |
| session-wrap lessons.md 누락 | Claude 내부 | ❌ | ❌ | ✅ |

---

## 자동화 연결 포인트

### 1. `/debug` Pre-check
새 버그 디버깅 전 `troubleshooting.json`에서 동일 증상 검색:
```bash
python3 -c "
import json, sys
data = json.load(open('docs/troubleshooting.json'))
keyword = sys.argv[1].lower()
for issue in data['issues']:
    if keyword in json.dumps(issue, ensure_ascii=False).lower():
        print(f\"[{issue['id']}] {issue['title']}\")
        print(f\"  → {issue.get('solution', 'N/A')}\")
" "[keyword]"
```

### 2. `continuous-improvement.md` 트리거
`tasks/lessons.md` 기록 후 프로덕션 영향도 판단 → YES 시 `/troubleshoot-save` 실행.

### 3. `/session-wrap` Step 5 체크포인트
세션 마무리 시 lessons.md 업데이트 및 troubleshoot-save 여부 확인.

---

## 검증 체크리스트

새 버그 기록 시:
- [ ] 프로덕션 영향? → troubleshooting.json 엔트리 생성
- [ ] 재현 가능 패턴? → docs/til/ TIL 파일 생성
- [ ] tasks/lessons.md 업데이트 (항상)
- [ ] `/til-index-sync` 실행 (TIL 추가 시)

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| `docs/troubleshooting.json` | 프로덕션 이슈 인덱스 |
| `docs/troubleshooting/README.md` | 이슈 목차 |
| `tasks/lessons.md` | AI 자기 수정 교훈 |
| `.claude/skills/troubleshoot-save.md` | 저장 자동화 (Step 0 분류 포함) |
| `.claude/skills/til-index-sync.md` | TIL↔INDEX 동기화 검증 |
