# TIL: Phase 2 Notification Differentiation — Patterns 1-7 (2026-02-06)

**Split from**: til-2026-02-06-phase2-notification-patterns.md (Part 1/2)

## Session Summary
Completed Phase 2 notification differentiation (8 sub-features, 117 new tests, 0 lint violations).
Key insights from implementing emotion-aware messaging, trend detection, and safety followup systems.

## Pattern 1: Weighted Message Selection Algorithm ⭐

**Problem**: Random message selection ignores user emotional context. Need to bias towards emotionally similar messages while maintaining randomness.

**Solution**: Weighted random selection based on emotion score distance
```dart
// Distance-based weights (writtenEmotionScore vs recentEmotionScore)
distance ≤ 1.0 → weight 3x (very similar emotion)
distance ≤ 3.0 → weight 2x (somewhat similar)
distance > 3.0 → weight 1x (default)
no writtenEmotionScore → weight 1x
```

**Implementation**:
```dart
final weights = <int>[];
for (final msg in messages) {
  if (msg.writtenEmotionScore == null) {
    weights.add(1);
  } else {
    final distance = (msg.writtenEmotionScore! - recentEmotionScore).abs();
    weights.add(distance <= 1.0 ? 3 : distance <= 3.0 ? 2 : 1);
  }
}

// Cumulative weight random selection (O(n) per pick)
final totalWeight = weights.fold(0, (sum, w) => sum + w);
var pick = Random().nextInt(totalWeight);
for (var i = 0; i < messages.length; i++) {
  pick -= weights[i];
  if (pick < 0) return messages[i];
}
```

**Key Insight**: This cumulative weight selection is simple but fair—each message gets exact probability of `weight[i]/totalWeight`.

**Gotcha**: Fallback to random when `recentEmotionScore == null` (not available yet). Test both paths.

---

## Pattern 2: Trend Detection with Priority Hierarchy

**Problem**: Multiple emotion trends (gap, steady, recovering, declining) can apply. Need deterministic priority.

**Solution**: Priority order ensures consistent behavior
```
gap > steady > recovering > declining
```

**Minimum data requirements**:
- `gap`: 1+ entry (3+ days old)
- `steady`: 2+ entries
- `recovering`/`declining`: 3+ entries (trend needs 2 deltas)

**Gotcha Found & Fixed**:
- 2 entries weren't enough for recovering/declining (only 1 delta)
- Must validate entry count **before** calculating trend deltas
- Test boundary: exactly N entries, N-1 entries, N+1 entries

**Architecture Decision**:
- Trend detection returns **optional** `EmotionTrendResult?`
- Null means insufficient data (not an error)
- Caller decides whether to trigger notification or skip

---

## Pattern 3: Static Service Testing with Dependency Injection

**Problem**: `EmotionTrendService` is static (no instantiation), but needs testable time dependency.

**Solution**: Static method with injectable override + explicit reset
```dart
@visibleForTesting
static DateTime Function()? nowOverride;

@visibleForTesting
static void resetForTesting() {
  nowOverride = null;
}

static DateTime _now() => nowOverride?.call() ?? DateTime.now();

// In setUp/tearDown
setUp(() => EmotionTrendService.resetForTesting());
tearDown(() => EmotionTrendService.resetForTesting());
```

**Why This Matters**: Avoids need for mocking library. Manual static method override = more controlled than reflection-based mocks.

**Test Pattern**: Date calculations become deterministic
```dart
final now = DateTime(2026, 2, 6);
EmotionTrendService.nowOverride = () => now;
// Now tests can set exact dates without relying on real time
```

---

## Pattern 4: Metadata Dictionary for Rich Context

**Problem**: Trend detection needs to communicate extra info (e.g., "last entry was 5 days ago") without proliferating typed fields.

**Solution**: `Map<String, dynamic> metadata` in result object
```dart
class EmotionTrendResult {
  final EmotionTrend trend;
  final Map<String, dynamic> metadata; // flexible key-value storage
}

// Usage
metadata['daysSinceLastEntry']
metadata['lastEntryDate']
metadata['averageScore']
metadata['recoveryDelta']
```

**Benefit**: Easy to extend without schema changes. Notification service picks what it needs.

**Gotcha**: No type safety on metadata keys. Document expected keys clearly (comment + test coverage).

---

## Pattern 5: Parallel Service Testing with Wave Coordination

**Problem**: Phase 2 had 3 independent service implementations (EmotionTrendService, SafetyFollowupService, EmotionTrendNotificationService) plus 36 integration tests.

**Solution Used**: Parallel test agents (Wave 1: independent, Wave 2: dependent on Wave 1)

**Results**:
- Wave 1 (33 + 22 tests) ran in parallel
- Wave 2 (28 tests) integrated Wave 1 results
- Total: 119 new tests in 1 session
- Zero flakes, all passing on first run

**Key Insight**: Test suite designed with clear layer boundaries enables parallelization. Each service had isolated concerns (trend detection, followup scheduling, message dispatch).

**Testing Lesson**: If you can describe test dependencies clearly, humans + AI can parallelize effectively. This unlocked 3x throughput.

---

## Pattern 6: Pre-Sorting Controller Pattern

**Problem**: `NotificationSettingsService.selectMessage()` needed messages in `displayOrder` sequence for sequential mode. Sorting in service = performance hit every call.

**Solution**: Sort once in Controller, pass pre-sorted list to Service
```dart
// In SelfEncouragementController
final sortedMessages = messages.toList()
  ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

// Pass to Service
final selected = NotificationSettingsService.selectMessage(
  settings,
  sortedMessages, // already sorted
  recentEmotionScore: recentEmotionScore,
);
```

**Benefit**: Removed redundant list copy + sort inside `selectMessage()`. Caller owns sort responsibility.

**Comment in Code**: Explicitly document that messages must be pre-sorted (prevents future regressions).

---

## Pattern 7: Emotion Aware Field Storage with nullable Semantics

**Problem**: `SelfEncouragementMessage` needs optional emotion metadata for weighted selection, but `copyWith` needs to support clearing these fields.

**Solution**: Nullable fields + `clear*` flags in copyWith
```dart
class SelfEncouragementMessage {
  final double? writtenEmotionScore; // nullable
  final String? category;             // nullable

  SelfEncouragementMessage copyWith({
    double? writtenEmotionScore,
    bool clearWrittenEmotionScore = false, // explicit clear flag
    String? category,
    bool clearCategory = false,
  }) {
    return SelfEncouragementMessage(
      writtenEmotionScore: clearWrittenEmotionScore
        ? null
        : (writtenEmotionScore ?? this.writtenEmotionScore),
      // ...
    );
  }
}
```

**Why**: `copyWith(writtenEmotionScore: null)` is ambiguous—does it clear or use existing? Explicit flag removes ambiguity.
