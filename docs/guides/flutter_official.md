# Flutter Official Documentation Context Integration

MindLog 프로젝트에서 Flutter/Riverpod 공식 문서를 효율적으로 활용하는 가이드.

## Context Hierarchy

```
[1] .claude/memories/  -> 프로젝트 특화 학습 (MindLog 버그/패턴)
[2] .claude/rules/     -> 아키텍처 제약 (레이어 규칙)
[3] .claude/skills/       -> 자동화 도구 (/c7-flutter)
[4] Context7 MCP       -> 공식 문서 (동적 조회)
```

## When to Use What

| Situation | Source | Command |
|-----------|--------|---------|
| MindLog에서 이전에 해결한 문제 | memories | (자동 참조) |
| 아키텍처 제약 확인 | rules | (자동 적용) |
| 공식 API 사용법 확인 | Context7 | `/c7-flutter [topic]` |
| 새로운 패턴 학습 후 저장 | memories | `/til-save [topic]` |

## Quick Reference

### 공식 문서 조회

```bash
# Riverpod 패턴 조회
/c7-flutter "AsyncValue error handling"

# Flutter 위젯 최적화
/c7-flutter "ListView.builder optimization"

# 네비게이션 패턴
/c7-flutter "go_router redirect patterns"
```

### 학습 내용 저장

```bash
# 새로 배운 패턴 저장
/til-save "AsyncValue skipLoadingOnRefresh"
```

## Available Context7 Libraries

| Library | ID | Snippets | Best For |
|---------|-----|----------|----------|
| Riverpod | `/rrousselgit/riverpod` | 421 | 상태관리, Provider 패턴 |
| Flutter | `/llmstxt/flutter_dev_llms_txt` | 2083 | 위젯, 성능, 네비게이션 |

## Workflow Examples

### 새로운 기능 구현 시

```
1. memories 확인 (유사 구현 있는지)
2. /c7-flutter [topic] (공식 패턴 확인)
3. 구현
4. /til-save [topic] (유용한 학습 저장)
```

### 버그 해결 시

```
1. memories 확인 (이전에 해결한 적 있는지)
2. /c7-flutter [topic] (공식 해결책 확인)
3. 수정
4. /til-save [topic] (재발 방지용 기록)
```

## Related Files

- **Skill**: `.claude/skills/c7-flutter.md`
- **Memories Index**: `.claude/memories/TIL-INDEX.md`
- **Flutter Advanced Skill**: `.claude/skills/flutter-advanced.md`

## Why This Approach?

| Approach | Pros | Cons |
|----------|------|------|
| Static cheatsheet | 즉시 접근 | 버전 outdated 위험 |
| Context7 동적 조회 | 항상 최신 | 조회 비용 |
| **하이브리드 (현재)** | 최신 + 프로젝트 특화 | - |

**결론**: Context7로 공식 문서를 조회하고, 유용한 학습은 memories에 저장하여 재사용.
