# til-index-sync

TIL 파일 ↔ INDEX.md 동기화 검증 스킬 (`/til-index-sync`)

## 목표
- `docs/til/` 디렉토리의 실제 파일과 `INDEX.md` 목록이 일치하는지 검증
- INDEX.md에 누락된 TIL 항목 자동 감지 및 추가 제안
- 고아(orphan) 파일 감지 (파일은 있으나 INDEX.md에 없는 경우)

## 트리거 조건
- `/til-index-sync` 명령어
- 새 TIL 파일 생성 후
- `/session-wrap` Step 5에서 TIL 생성 발생 시

## 프로세스

### Step 1: 파일 목록 수집
```bash
# 실제 TIL 파일 목록 (INDEX.md 제외)
ls docs/til/*.md | grep -v INDEX.md | sort

# INDEX.md에 등록된 파일 목록 추출
grep -oE '[A-Z_]+_TIL\.md|[A-Z_]+\.md' docs/til/INDEX.md | sort -u
```

### Step 2: 비교 분석
```
실제 파일 목록 vs INDEX.md 등록 목록 diff

→ INDEX에 없는 파일: "누락 파일" (추가 필요)
→ 파일이 없는 INDEX 항목: "고아 링크" (제거 또는 파일 생성 필요)
→ 버전 히스토리 카운트 불일치: "통계 오류" (숫자 갱신 필요)
```

### Step 3: 보고서 출력

```markdown
## TIL Index Sync Report

### 현황
- 실제 파일: N개
- INDEX 등록: M개

### 누락 파일 (INDEX에 없음)
- [ ] FILENAME_TIL.md → 추가 필요

### 고아 링크 (파일 없음)
- [ ] ORPHAN_TIL.md → 파일 생성 또는 링크 제거

### 통계 불일치
- 총 단어 수, 버전 히스토리 카운트 갱신 필요

### 추천 액션
1. [액션 1]
2. [액션 2]
```

### Step 4: 자동 수정 (--fix 플래그 시)

**누락 파일 → INDEX.md 추가** 시 최소 항목 삽입:
```markdown
## N️⃣ FILENAME_TIL.md

**길이**: 미확인 (직접 확인 필요)
**난이도**: 중급
**소요 시간**: 미확인

### 주요 내용
- (파일 내용 확인 후 채우기)

### 대상 독자
- (작성 필요)
```

**버전 히스토리 갱신**: 마지막 버전 번호 증가 + 날짜 추가.

## 사용 예시

```bash
# 검증만 (변경 없음)
/til-index-sync

# 자동 수정 포함
/til-index-sync --fix
```

## 시나리오별 라우팅 갱신

새 TIL 추가 시 `## 🎯 사용 시나리오별 가이드` 섹션에 시나리오 추가:
```markdown
### 시나리오 N: "[사용자가 물어볼 법한 질문]"
**추천**: FILENAME_TIL.md
**소요시간**: X분
**내용**: [핵심 내용 요약]
```

## 연관 스킬
- `/til-save` - 새 TIL 파일 저장
- `/session-wrap` - 세션 마무리 시 TIL 생성

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P3 |
| Category | knowledge-management |
| Dependencies | docs/til/INDEX.md |
| Created | 2026-02-27 |
| Updated | 2026-02-27 |
