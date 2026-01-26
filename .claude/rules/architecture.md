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
