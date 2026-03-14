# TIL: Phase 2 Notification Differentiation — Architecture & Testing (2026-02-06)

**Split from**: til-2026-02-06-phase2-notification-patterns.md (Part 2/2)

## Pattern 8: Lint Issue Resolution at Scale

**Problem**: After adding 119 tests with quoted strings, 22 `prefer_single_quotes` violations appeared.

**Solution**: Centralized fix with `dart fix`
```bash
dart fix --apply --code=prefer_single_quotes
```

**Learning**:
- Don't fix lint issues manually across 50+ files
- Use `dart fix --apply` for mechanical transformations
- Verify with `flutter analyze` before committing

---

## Pattern 9: Test Grouping by Concern

**Problem**: 33 tests for `EmotionTrendService` could be chaotic. Need structure.

**Solution**: Group by feature + edge case
```dart
group('EmotionTrendService - 빈 데이터 및 부족한 데이터', () {
  test('빈 리스트를 전달하면 null을 반환한다', () { ... });
  test('1개 엔트리만 있으면 null을 반환한다', () { ... });
  test('2개 엔트리만 있으면 null을 반환한다 (recovering/declining 최소 3개 필요)', () { ... });
});

group('EmotionTrendService - Gap 감지', () {
  test('마지막 기록이 정확히 3일 전이면 gap을 감지한다', () { ... });
  // ...
});

group('EmotionTrendService - Steady 감지', () { ... });
group('EmotionTrendService - Recovering 감지', () { ... });
group('EmotionTrendService - Declining 감지', () { ... });
group('EmotionTrendService - 우선순위', () { ... });
```

**Benefit**: Easy to navigate 100+ tests. Failure in one group doesn't hide others. Each group tests one concern.

---

## Pattern 10: Enum Categorization for Message Pools

**Problem**: Phase 2 added 8 emotion categories (behavioral activation, mindfulness, etc.) + 4 trend types + randomization modes. Could grow to 50+ message variants.

**Decision**: Keep as `static final List<String>` with comments instead of separate enum per category.

```dart
// lib/core/constants/notification_messages.dart
class NotificationMessages {
  // MindCare CBT Messages
  static final behavioralActivationMessages = [
    'Start with small steps today...',
    'What one action would help...',
    // ...
  ];

  static final mindfulnessMessages = [ /* ... */ ];
  static final groundingMessages = [ /* ... */ ];
  // ...

  // Backward compatible unified getter
  static List<String> getAllMindcareMessages() => [
    ...behavioralActivationMessages,
    ...mindfulnessMessages,
    ...groundingMessages,
    // ...
  ];
}
```

**Why Not Enum?**
- Lists grow organically (8 categories × 5-6 messages = 48 strings, hard to fit in single enum)
- Subset access by category (for UI chips) easier with separate lists
- Backward compatibility maintained for legacy consumers

---

## Architecture Insight: Notification Tier Separation

**MindLog notification stack has 3 tiers**:

1. **Local Scheduled** (timezone-aware, client-controlled):
   - CheerMe (Cheer Me daily 응원, Cheer Me Preset templates)
   - Reminders (recovery reminders)
   - Weekly Insight (Sunday 20:00)
   - **Behavior**: Full personalization possible (`{name}` substitution works)

2. **FCM Foreground** (client receives JSON, can customize):
   - MindCare notifications
   - Safety followup
   - **Behavior**: Custom messages via `buildPersonalizedMessage()`

3. **FCM Background/Killed** (OS displays `notification` payload):
   - MindCare notifications
   - Safety followup
   - **Constraint**: Android OS renders directly, client code never runs
   - **Cannot personalize** — no client context available

**Decision Made for Phase 2**: Remove `{name}` from MindCare FCM template (24 items) because 90% of real-world opens happen in background where personalization fails. Keep `{name}` in local scheduled + Cheer Me (client controls timing).

---

## Testing Lesson: False Positives in Parallel Testing

**Discovery**: When 3 test suites run simultaneously, order of `setUp`/`tearDown` matters.

**Safeguard Used**:
```dart
setUp(() {
  EmotionTrendService.resetForTesting();
  SafetyFollowupService.resetForTesting();
  // ... explicitly reset all static overrides
});

tearDown(() {
  EmotionTrendService.resetForTesting();
  SafetyFollowupService.resetForTesting();
});
```

**Without tearDown**: Test 1 sets `nowOverride`, Test 2 reads it unintentionally → flaky tests in parallel.

---

## Files to Reference for Future Work

| Pattern | File |
|---------|------|
| Trend detection | `lib/core/services/emotion_trend_service.dart` (70 lines) |
| Weighted message selection | `lib/core/services/notification_settings_service.dart` (lines 484-519) |
| Safety followup scheduling | `lib/core/services/safety_followup_service.dart` |
| Emotion-linked UI card | `lib/presentation/widgets/result_card/emotion_linked_prompt_card.dart` |
| Test structure example | `test/core/services/emotion_trend_service_test.dart` (200+ lines, 33 tests) |

---

## Next Phase (Phase 3) Preparation

**Patterns we'll likely reuse**:
- Static service testing pattern ✅ (ready for AI dialog generation)
- Weighted selection for prompt variation ✅ (extend to response ranking)
- Metadata dictionary ✅ (store AI quality scores)
- Pre-computed categorization ✅ (message/prompt pools)

**Known gaps to address**:
- AI generation + emotion linking (Phase 3-1 feature)
- Weekly insight data aggregation → monthly trend
- Crisis intervention followup (SafetyFollowup Phase 3 extension)

---

## Session Metrics

| Metric | Value |
|--------|-------|
| New tests added | 119 (Wave 1+2) |
| Test pass rate | 1375/1375 (100% new) |
| Code coverage delta | +8.4% |
| Lint issues | 0 (after `dart fix`) |
| Commits | 1 (Phase 2 integration) |
| Architecture violations | 0 |

**Quality gates passed**: ✅ lint → ✅ analyze → ✅ test → ✅ coverage
