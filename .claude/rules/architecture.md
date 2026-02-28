# Architecture Rules

## Layer Dependencies
- `presentation -> domain` (O)
- `data -> domain` (O)
- `domain -> data/presentation` (X - forbidden)

## Core Patterns
- **Entity**: immutable, `copyWith`, `fromJson`/`toJson`
- **Repository**: abstract interface in `domain/`, impl in `data/`
- **UseCase**: single `execute()` method, catches Exception, rethrows Failure
- **Failure**: sealed class (`failures.dart`) — exhaustive switch required

## Critical Constraints
- `SafetyBlockedFailure` must NEVER be modified or removed (emergency detection)
- `is_emergency` field in AI response must always be preserved
- Korean language constraints in prompts must be maintained

## Database
- SQLite schema version: 3
- Migration: increment `_currentVersion` by 1, add ALTER in `_onUpgrade`
- `_onCreate` and `_onUpgrade` must stay synchronized
- DROP operations forbidden (backward compatibility)

## Debugging Rules
- IMPORTANT: 에러 수정 전 반드시 근본 원인(root cause)을 먼저 분석하고 설명할 것
- YOU MUST: 수정 전에 관련 테스트를 먼저 실행하여 현재 상태 확인
- YOU MUST: 에러 로그의 스택트레이스를 끝까지 추적 (표면 증상이 아닌 원인 파악)
- 추측 기반 수정 금지 — 증거 없으면 "/debug analyze" 사용

## Error Handling Pattern
- Failure: sealed class (`lib/core/errors/failures.dart`)
  - NetworkFailure, ApiFailure, CacheFailure, ServerFailure
  - DataNotFoundFailure, ValidationFailure, ImageProcessingFailure
  - SafetyBlockedFailure (절대 수정 금지 — 위기 감지)
  - UnknownFailure (catch-all)
- UseCase: try { repo } on Failure { rethrow } catch { UnknownFailure }
