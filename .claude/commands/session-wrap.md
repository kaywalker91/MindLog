# /session-wrap - 세션 마무리 자동화

## Purpose
세션 종료 시 학습 내용 추출, CLAUDE.md 업데이트 제안, 자동화 후보 발굴을 수행합니다.

## Usage
```
/session-wrap [--dry-run] [--focus learning|automation|docs]
```

## Arguments
- `--dry-run` - 실제 변경 없이 제안만 출력
- `--focus` - 특정 영역에 집중 (learning: 학습 추출, automation: 자동화 발굴, docs: 문서 업데이트)

## Execution Flow

### Phase 1: 병렬 분석 (5개 에이전트)
1. **doc-updater**: CLAUDE.md 업데이트 제안 생성
2. **automation-scout**: 반복 패턴 → 스킬/커맨드 후보 발굴
3. **learning-extractor**: TIL(Today I Learned) 추출
4. **followup-suggester**: 다음 세션 작업 제안
5. **duplicate-checker**: 기존 스킬과 중복 검사

### Phase 2: 결과 통합
- 각 에이전트 결과를 하나의 리포트로 병합
- 우선순위 정렬 (중요도 순)
- 사용자 확인 후 적용

## Output Format
```markdown
## 📊 Session Wrap Report

### 1. CLAUDE.md 업데이트 제안
[doc-updater 결과]

### 2. 자동화 후보
[automation-scout 결과]

### 3. 오늘의 학습
[learning-extractor 결과]

### 4. 다음 작업 제안
[followup-suggester 결과]

### 5. 중복 검사
[duplicate-checker 결과]
```

## Agent Delegation
이 명령어는 다음 에이전트들을 병렬로 호출합니다:
- `@agents/session-wrap/doc-updater.md`
- `@agents/session-wrap/automation-scout.md`
- `@agents/session-wrap/learning-extractor.md`
- `@agents/session-wrap/followup-suggester.md`
- `@agents/session-wrap/duplicate-checker.md`

## Example
```
/session-wrap --dry-run
/session-wrap --focus automation
/session-wrap
```
