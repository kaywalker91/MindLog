# c7-flutter

Context7 MCP를 활용한 Flutter/Riverpod 공식 문서 조회 스킬 (`/c7-flutter [topic]`)

## 목표
- Flutter/Riverpod 공식 문서를 동적으로 조회
- 최신 버전의 정확한 패턴 참조
- 프로젝트 memories와 역할 분리

## 트리거 조건
- `/c7-flutter [topic]` 명령어
- 공식 문서 패턴 확인이 필요할 때
- 최신 API 사용법 검증 시

## Context Hierarchy (역할 분리)

```
[1] .claude/memories/  -> 프로젝트 특화 학습 (MindLog 버그/패턴)
[2] .claude/rules/     -> 아키텍처 제약 (레이어 규칙)
[3] docs/skills/       -> 자동화 도구 (/c7-flutter)
[4] Context7 MCP       -> 공식 문서 (동적 조회)
```

**원칙**: Context7은 공식 문서, Memories는 프로젝트 경험

## Available Library IDs

| Topic | Library ID | Snippets | Use Case |
|-------|-----------|----------|----------|
| Riverpod | `/rrousselgit/riverpod` | 421 | 상태관리 패턴, Provider 타입 |
| Flutter | `/llmstxt/flutter_dev_llms_txt` | 2083 | 위젯, 성능, 네비게이션 |

## 실행 절차

### Step 1: Library ID 확인 (필요 시)

```
mcp__context7__resolve-library-id
├── libraryName: "riverpod" 또는 "flutter"
└── query: [사용자 쿼리]
```

### Step 2: 문서 조회

```
mcp__context7__query-docs
├── libraryId: "/rrousselgit/riverpod" 또는 "/llmstxt/flutter_dev_llms_txt"
└── query: [사용자 쿼리]
```

### Step 3: 결과 정리

조회된 공식 패턴을 현재 프로젝트 컨텍스트에 맞게 정리하여 제시

## 사용 예시

### Riverpod 패턴 조회

```bash
> /c7-flutter "AsyncValue error handling"

# 실행:
mcp__context7__query-docs
├── libraryId: "/rrousselgit/riverpod"
└── query: "AsyncValue error handling patterns"
```

### Flutter 성능 가이드 조회

```bash
> /c7-flutter "ListView.builder optimization"

# 실행:
mcp__context7__query-docs
├── libraryId: "/llmstxt/flutter_dev_llms_txt"
└── query: "ListView.builder optimization performance"
```

### 복합 조회 (양쪽 모두)

```bash
> /c7-flutter "state management best practices"

# 실행 1: Riverpod 문서 조회
# 실행 2: Flutter 문서 조회 (필요 시)
```

## 자주 사용하는 쿼리 예시

| Category | Example Query |
|----------|---------------|
| State | "AsyncValue patterns", "StateNotifier vs Notifier" |
| Performance | "ListView optimization", "const widgets" |
| Navigation | "go_router redirect", "deep linking" |
| Testing | "widget testing with providers", "mock providers" |
| Lifecycle | "dispose patterns", "ref.onDispose" |

## 출력 형식

```
Context7 조회 결과: [topic]
==============================

📚 Source: [Library Name]

📖 공식 패턴:
[조회된 코드/설명]

🔗 적용 예시 (MindLog):
[프로젝트에 적용하는 방법]

📝 관련 memories:
└── [관련 있는 경우 memory 파일 참조]

다음 단계:
└── /til-save [topic] (학습 내용 저장)
```

## Memories와의 연계

### 새로운 패턴 학습 시

```bash
# 1. 공식 문서 조회
> /c7-flutter "AsyncValue skipLoadingOnRefresh"

# 2. 프로젝트에 적용

# 3. 학습 내용 저장
> /til-save "AsyncValue skipLoadingOnRefresh"
```

### 기존 패턴 검증 시

```bash
# 1. memories 확인 (자동)
# 2. 공식 문서로 검증
> /c7-flutter [topic]
```

## 주의사항

- Context7 호출은 세션당 3회 제한 권장
- 이미 알고 있는 패턴은 memories 우선 참조
- 조회 결과가 유용하면 `/til-save`로 저장

## 연관 스킬

- `/flutter-advanced` - Riverpod 심화 패턴 (프로젝트 특화)
- `/til-save` - 학습 내용 저장
- `/session-wrap` - 세션 마무리

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P2 |
| Category | development / documentation |
| Dependencies | Context7 MCP |
| Created | 2026-02-05 |
| Updated | 2026-02-05 |
