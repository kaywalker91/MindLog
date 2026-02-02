# Session TIL Summary - February 2, 2026

**Session**: statistics-restoration-bugfix
**Duration**: Single deep-dive session
**Root Cause**: Provider dependency tracking failure (ref.read vs ref.watch)
**Solution Applied**: Converted 10 ref.read() to ref.watch() in infra_providers.dart

---

## Created TIL Documents

This session produced 4 interconnected TIL documents:

### 1. **til-refread-refwatch-dependency-tracking.md**
**Topic**: Riverpod dependency tracking mechanism
- ref.read() returns current value WITHOUT recording dependency
- ref.watch() returns current value AND records dependency metadata
- 10 UseCase Providers converted from read→watch
- Invalidation chain breaks when upstream uses ref.read()

**Key Formula**:
```
ref.watch() = Riverpod automatic invalidation chain ✓
ref.read()  = Manual invalidation only (❌ not recommended)
```

### 2. **til-defensive-programming-timing-races.md**
**Topic**: Handling async Provider initialization timing issues
- Invalidate alone insufficient for autoDispose Providers
- Race condition: rapid invalidation + resubscription
- forceReconnect() pattern: invalidate + warm-up + timeout
- Graceful degradation when async operations timeout

**Key Pattern**:
```
invalidate() → warm-up (read.future + timeout) → error handling
```

### 3. **til-indexedstack-immediate-build.md**
**Topic**: IndexedStack eager widget building
- IndexedStack builds ALL children immediately (not lazy)
- All children subscribe to Providers simultaneously
- autoDispose Providers don't auto-dispose while keep-alive
- Difference from TabBarView (lazy building)

**Key Insight**:
```
IndexedStack = eager build + keep-alive + all providers active
TabBarView   = lazy build + dispose when not visible
```

### 4. **til-provider-invalidation-chain-pattern.md**
**Topic**: Complete reference for systematic provider invalidation
- 5-layer provider architecture (DataSource → Repository → UseCase → Presentation → UI)
- Bottom-up watch pattern: each layer watches the one below
- Invalidation starts at root (DataSource)
- Propagates automatically via watch chain
- autoDispose Providers require explicit invalidation

**Key Architecture**:
```
[5. UI Layer - StateNotifier/computed]
         ↑ watch
[4. Presentation - FutureProvider.autoDispose]
         ↑ watch
[3. UseCase - Provider]
         ↑ watch
[2. Repository - Provider]
         ↑ watch
[1. DataSource - Provider]
```

---

## Bug Fix Summary

### Problem
App reinstallation → DB restore → Diary list visible ✓, Statistics empty ✗

### Root Cause
1. `infra_providers.dart` used `ref.read()` for 10 UseCase Providers
2. ref.read() doesn't track dependencies
3. invalidate() doesn't auto-propagate to these UseCases
4. Downstream statisticsProvider uses old repository instance
5. autoDispose Provider keeps cache while tab not visible (IndexedStack)

### Fix Applied
```dart
// Before (broken)
final getStatisticsUseCaseProvider = Provider((ref) {
  final repo = ref.read(statisticsRepositoryProvider);  // ❌
  return GetStatisticsUseCase(repo);
});

// After (fixed)
final getStatisticsUseCaseProvider = Provider((ref) {
  final repo = ref.watch(statisticsRepositoryProvider);  // ✅
  return GetStatisticsUseCase(repo);
});
```

### Files Changed
- `lib/presentation/providers/infra_providers.dart` (10 ref.read() → ref.watch())
- Downstream Provider chain automatically fixed

---

## Knowledge Reusability

### Pattern 1: Any time ref.read() appears in Provider definition
→ Suspect dependency tracking issue
→ Convert to ref.watch()

### Pattern 2: Data invalidation (DB recovery, logout, account switch)
→ Apply 5-layer architecture
→ Invalidate at root layer
→ Watch chain ensures auto-propagation
→ Explicit invalidate for autoDispose Providers

### Pattern 3: Timing race conditions
→ Use forceReconnect() pattern
→ Warm-up critical Providers
→ Add timeout + error handling

### Pattern 4: IndexedStack usage
→ Understand eager build + keep-alive behavior
→ Ensure all children use ref.watch()
→ Be careful with autoDispose (won't auto-dispose)

---

## Validation Points for Future Sessions

When implementing similar features:

1. **ref.read() audit**: Grep codebase for `ref.read(` in Provider definitions
2. **Invalidation chain**: Trace from DataSource down to UI via watch
3. **autoDispose handling**: Remember explicit invalidate needed
4. **Timing tests**: Rapid screen transitions, network delays
5. **IndexedStack awareness**: All children build immediately

---

## Related Existing Memory

- `til-riverpod-multilayer-invalidation.md` - Previous session's provider invalidation findings (provider-level, not ref.read-specific)
- `mindlog-til-gorouter-popscope.md` - Navigation patterns
- `til-firebase-timezone-handling.md` - Firebase-specific patterns

**This session adds**: Deep analysis of ref.read vs ref.watch, forcing a layer deeper into why the previous session's solution was incomplete.

---

## Code Review Template for Next Session

```markdown
## Riverpod Provider Definition Checklist

- [ ] All Provider definitions use only ref.watch() for dependencies
  - [ ] No ref.read() (except in event handlers)
  - [ ] No direct imports of objects (always via Provider)

- [ ] 5-layer architecture followed
  - [ ] DataSource → Repository → UseCase → Presentation → UI
  - [ ] Each layer watches the one below

- [ ] Invalidation strategy clear
  - [ ] What triggers invalidation?
  - [ ] Which Providers affected?
  - [ ] Are autoDispose Providers explicitly invalidated?

- [ ] Timing race conditions considered
  - [ ] warm-up needed for critical data?
  - [ ] timeout set for async operations?
  - [ ] graceful degradation if warm-up fails?

- [ ] IndexedStack usage (if applicable)
  - [ ] All children building simultaneously?
  - [ ] autoDispose behavior understood?
  - [ ] Any memory concerns?
```

---

## Commit Messages (for reference)

Session applied this commit:
```
feat(v1.4.30): statistics restoration with ref.watch conversion

- Convert 10 ref.read() calls to ref.watch() in infra_providers.dart
- Fixes dependency tracking for GetStatisticsUseCase & related
- Add forceReconnect() defensive programming for timing races
- Explicit invalidation of autoDispose Providers in main.dart
- Root cause: ref.read() doesn't trigger auto-invalidation
```

---

## Next Session Recommendations

1. **Test coverage**: Add unit test for Provider invalidation chain
2. **Documentation**: Add comment to infra_providers.dart explaining ref.watch requirement
3. **Linting**: Consider custom lint rule detecting ref.read in Provider definitions
4. **Monitoring**: Track Provider rebuild counts to detect excessive invalidation
5. **Performance**: Measure impact of watch vs read (should be negligible)

---

## Session Impact Summary

| Category | Impact |
|----------|--------|
| Bug fixed | Yes - Statistics now restore after reinstall |
| Architecture improved | Yes - ref.watch pattern now consistent |
| Code quality | Improved (no hidden dependencies) |
| Test coverage | Action item (recommend unit test) |
| Documentation | Action item (recommend code comments) |
| Performance | Negligible impact (watch vs read) |
| Maintainability | Significant improvement (explicit dependencies) |

