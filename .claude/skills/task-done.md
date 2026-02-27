# task-done

태스크 완료 후 `docs/tasks.md`를 자동으로 업데이트하는 스킬 (`/task-done`)

## 목표
태스크 구현 완료 시 `docs/tasks.md`의 체크박스 마킹과 완료 메타데이터(버전, 날짜, 파일, 요약)를
자동으로 삽입해 수동 업데이트 누락을 방지한다.

## 트리거 조건
- `/task-done [TASK-ID] [summary]` 명령어 실행 시
- 태스크 구현 직후 즉시 호출 권장

## 입력 형식

```
/task-done TASK-A11Y-001 "tappable_card.dart Semantics(button:true) 래핑"
/task-done TASK-UI-003 "다이얼로그 색상 theme-aware 마이그레이션" lib/presentation/widgets/dialog.dart
```

- **인수 1** (필수): TASK-ID (예: `TASK-A11Y-001`)
- **인수 2** (필수): 완료 요약 (한 줄, 한글 또는 영문)
- **인수 3+** (선택): 수정된 주요 파일 경로 (없으면 git diff로 자동 추출)

## 7-Step 실행 흐름

### Step 1: 현재 버전 읽기
```bash
grep "^version:" pubspec.yaml
```
→ `version: 1.4.48+56` → 버전 태그: `v1.4.48`

### Step 2: 날짜 확인
현재 날짜를 `YYYY-MM-DD` 형식으로 사용 (시스템 날짜 참조).

### Step 3: tasks.md에서 TASK-ID 위치 확인
```bash
grep -n "TASK-ID" docs/tasks.md
```
→ 해당 줄 번호와 현재 상태(`[ ]` 또는 `[x]`) 확인.

**엣지 케이스**:
- TASK-ID 미발견 → `❌ TASK-ID '...'를 docs/tasks.md에서 찾을 수 없습니다.` 출력 후 중단
- 이미 `[x]` → `⚠️ TASK-ID '...'는 이미 완료 처리되어 있습니다. 재실행하면 중복 메타데이터가 삽입됩니다. 계속할까요?` 확인 후 진행

### Step 4: 수정 파일 목록 결정
- 인수에 파일 경로가 있으면 해당 파일 사용
- 없으면: `git diff --stat HEAD` 또는 `git diff --name-only HEAD~1 HEAD`로 최근 수정 파일 추출
- 파일이 너무 많으면 핵심 파일 3~5개만 표시

### Step 5: tasks.md 업데이트 (Edit tool)

**변경 전:**
```markdown
- [ ] **TASK-A11Y-001** (REQ-093): `tappable_card.dart` — GestureDetector Semantics 래핑
```

**변경 후:**
```markdown
- [x] **TASK-A11Y-001** (REQ-093): `tappable_card.dart` — GestureDetector Semantics 래핑
  - 완료: v1.4.48 (2026-02-27)
  - 파일: `lib/presentation/widgets/common/tappable_card.dart`
  - 추가: tappable_card.dart Semantics(button:true) 래핑
```

Edit tool로 `- [ ] **TASK-ID**` → `- [x] **TASK-ID**` 교체 후 메타데이터 3줄 삽입.

### Step 6: 헤더 최종 업데이트 갱신
tasks.md 상단의 `**최종 업데이트**` 줄을 오늘 날짜와 TASK-ID로 갱신:
```markdown
**최종 업데이트**: 2026-02-27 (TASK-A11Y-001 완료)
```

### Step 7: 결과 확인 출력

```
✅ TASK-A11Y-001 완료 처리됨
   └─ docs/tasks.md line 93: [ ] → [x]
   └─ 완료: v1.4.48 (2026-02-27)
   └─ 파일: lib/presentation/widgets/common/tappable_card.dart
```

## 출력 형식

**성공:**
```
✅ [TASK-ID] 완료 처리됨
   └─ docs/tasks.md 업데이트
   └─ 완료: v[VERSION] ([DATE])
   └─ 파일: [FILES]
```

**TASK-ID 미발견:**
```
❌ '[TASK-ID]'를 docs/tasks.md에서 찾을 수 없습니다.
   사용 가능한 TASK-ID 확인: grep -n "TASK-" docs/tasks.md
```

**이미 완료:**
```
⚠️ '[TASK-ID]'는 이미 [x] 상태입니다.
   중복 메타데이터 삽입을 원하면 명시적으로 확인해주세요.
```

## 배치 실행 예시

Sprint 완료 후 여러 태스크를 순차 실행:
```
/task-done TASK-A11Y-001 "tappable_card.dart Semantics(button:true) 래핑"
/task-done TASK-A11Y-002 "day_cell.dart 날짜 버튼 semantics + 이모지 excludeSemantics"
/task-done TASK-A11Y-003 "sentiment_dashboard.dart 에너지 레벨 Semantics"
/task-done TASK-A11Y-004 "이미지 위젯 5개 semanticLabel 추가"
/task-done TASK-A11Y-005 "calendar_header.dart prev/next 달 tooltip 추가"
```

## 연관 스킬
- `/session-wrap` — 세션 종료 시 미완료 TASK 자동 감지 (Phase 6)
- `/version-bump` — 버전 번호 업데이트
- `/til-save` — 기술 학습 내용 문서화

## 주의사항
- `docs/tasks.md`가 없는 프로젝트에서는 실행 불가 (안내 후 중단)
- 메타데이터 들여쓰기: 2스페이스 + `- ` (기존 completed 태스크 포맷 준수)
- TASK-ID는 대소문자 구분 없이 검색하되 저장 시 원본 형식 유지

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | workflow |
| Dependencies | docs/tasks.md |
| Created | 2026-02-27 |
| Updated | 2026-02-27 |
