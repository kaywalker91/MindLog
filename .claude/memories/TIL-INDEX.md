# TIL Memory Index

Central index for all learning documents organized by topic and session.

---

## Session: February 2, 2026 - Statistics Restoration Bug Fix

**Bug**: App reinstallation → DB restore → Statistics not displaying (Diary list displays correctly)
**Root Cause**: Provider dependency tracking failure (ref.read vs ref.watch)
**Fix**: Convert 10 ref.read() to ref.watch() in infra_providers.dart

### Key Documents (This Session)

1. **SESSION-TIL-SUMMARY-FEB2.md** ⭐ START HERE
   - Executive summary of all learnings
   - Links to related documents
   - Code review checklist template
   - Session impact summary

2. **til-refread-refwatch-dependency-tracking.md**
   - Core insight: ref.read() breaks dependency tracking
   - When to use ref.read() vs ref.watch()
   - Practical patterns and anti-patterns
   - Debugging guide for "invalidate not working"

3. **til-defensive-programming-timing-races.md**
   - Timing race conditions in Provider initialization
   - forceReconnect() pattern for critical data
   - warm-up + timeout + error handling
   - Graceful degradation strategies

4. **til-indexedstack-immediate-build.md**
   - IndexedStack builds ALL children immediately (not lazy)
   - Difference from TabBarView
   - Impact on autoDispose Provider behavior
   - Memory and performance considerations

5. **til-provider-invalidation-chain-pattern.md**
   - Complete reference for systematic invalidation
   - 5-layer architecture pattern
   - Bottom-up watch pattern
   - Validation checklist and test strategies

---

## Related Documents (Previous Sessions)

### Provider State Management
- **til-riverpod-multilayer-invalidation.md** (Feb 2, earlier session)
  - Provider layer dependencies and invalidation
  - Composition Root pattern
  - Cross-layer invalidation strategy
  - Complements this session's ref.read/watch analysis

### Navigation
- **mindlog-til-gorouter-popscope.md**
  - go_router migration patterns
  - PopScope vs Navigator.pop()

### Firebase Integration
- **til-firebase-timezone-handling.md**
  - Firebase-specific timezone handling
  - Notification scheduling patterns

### In-App Updates
- **til-in-app-update-riverpod.md**
  - In-app update flow with Riverpod state management
  - async/await patterns for update checks

### Code Quality
- **til-code-quality-refactoring.md**
  - Refactoring patterns and principles
  - Widget decomposition strategies

---

## Knowledge Application Guide

### When You Encounter...

| Situation | Reference Document | Key Action |
|-----------|------------------|-----------|
| Provider not updating after invalidate | til-refread-refwatch-dependency-tracking.md | Check for ref.read() in definitions |
| Data empty after app startup | til-defensive-programming-timing-races.md | Add warm-up for critical Providers |
| Unclear which Providers affected by change | til-provider-invalidation-chain-pattern.md | Map 5-layer architecture |
| IndexedStack with multiple tabs | til-indexedstack-immediate-build.md | Remember eager build + keep-alive |
| Need to understand Provider design | SESSION-TIL-SUMMARY-FEB2.md | Review code review checklist |

---

## Architecture Overview

```
[Presentation - UI Layer]
  ↑ watch
[Presentation - FutureProvider.autoDispose]
  ↑ watch
[Domain - UseCase Provider]
  ↑ watch (CRITICAL: NOT ref.read())
[Data - Repository Provider]
  ↑ watch
[Data - DataSource Provider]
  ↑
[External: Database, API, SharedPrefs]
```

**Critical Rule**: Every level must use `ref.watch()` to ensure dependency tracking.

---

## Quick Reference: ref.read() vs ref.watch()

### Use ref.watch() when:
- Defining a Provider (any type)
- Provider depends on another Provider
- Need automatic invalidation propagation

### Use ref.read() when:
- Inside UI event handler (onPressed, onChanged)
- Inside StateNotifier action method
- One-time value retrieval in callback

### Rule of Thumb:
**Provider definitions = ref.watch() always**
**Event handlers = ref.read() OK**

---

## Code Patterns by Use Case

### Pattern: Data Layer Change Detection (DB recovery, logout)
See: **til-provider-invalidation-chain-pattern.md**
```dart
container.invalidate(sqliteLocalDataSourceProvider);
// Automatic propagation via watch chain
// + explicit invalidate for autoDispose Providers
```

### Pattern: Async Provider Warm-up
See: **til-defensive-programming-timing-races.md**
```dart
await container.read(criticalProvider.future).timeout(5s);
```

### Pattern: Widget Build Optimization
See: **til-indexedstack-immediate-build.md**
```dart
// Use TabBarView instead of IndexedStack for memory efficiency
// Or understand eager build implications if using IndexedStack
```

---

## Testing Strategies

### Verify Invalidation Chain Works
1. Check all Provider definitions use ref.watch()
2. invalidate() root DataSource
3. Verify all dependent Providers rebuild (use debugPrint logs)
4. For autoDispose: explicitly invalidate in main.dart

### Test Timing Races
1. Rapid screen transitions (use Flutter hot restart)
2. Invalidate + immediate screen push
3. Monitor for "provider still loading old data"

### Verify IndexedStack Behavior
1. All tabs build immediately on startup
2. All subscribe to Providers simultaneously
3. Invalidation affects all (not just visible)

---

## Session Statistics

| Metric | Value |
|--------|-------|
| TIL documents created | 4 new + 1 summary |
| Files modified | 1 (infra_providers.dart) |
| ref.read() → ref.watch() conversions | 10 |
| Root cause identified | Yes |
| Bug fixed | Yes |
| Test coverage status | Action item |

---

## Next Steps (Recommended)

1. **Test Coverage** (Priority: High)
   - Add unit test for Provider invalidation chain
   - Add integration test for DB recovery scenario

2. **Code Documentation** (Priority: Medium)
   - Add comment to infra_providers.dart explaining ref.watch requirement
   - Update provider definition template with ref.watch rule

3. **Linting** (Priority: Medium)
   - Consider custom lint rule: warn on ref.read() in Provider definitions
   - Add to analysis_options.yaml

4. **Monitoring** (Priority: Low)
   - Track Provider rebuild counts
   - Detect excessive invalidation patterns
   - Performance impact analysis

---

## File Locations

All TIL files located in:
```
/Users/kaywalker/AndroidStudioProjects/mindlog/.claude/memories/
```

Related project files:
```
lib/presentation/providers/infra_providers.dart          (modified)
lib/presentation/providers/statistics_providers.dart     (uses Providers)
lib/core/services/db_recovery_service.dart              (invalidation trigger)
lib/main.dart                                            (invalidation coordination)
```

---

## Glossary

**Provider**: Riverpod's state container (like GetIt + state management combined)
**ref.watch()**: Dependency tracking + value retrieval
**ref.read()**: Value retrieval without tracking (problematic in Provider definitions)
**invalidate()**: Clear cached value, force recomputation on next read
**autoDispose**: Automatic cleanup when unsubscribed (but needs explicit invalidate if keep-alive)
**Watch chain**: Series of Provider→Provider dependencies via ref.watch()

---

**Last Updated**: February 2, 2026
**Session**: statistics-restoration-bugfix
**Status**: Complete
