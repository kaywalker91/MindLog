# "전체보기" Bottom Sheet Feature Restoration

**Date:** 2026-02-11
**Status:** ✅ Complete
**Test Results:** All 1473 tests passed

## Summary

Restored the "전체보기" (View All) bottom sheet feature that was removed in v1.4.35 (commit `bd99fed`, 2026-02-05). Users can now tap the `EmotionInsightCard` to view full analysis details in a modal bottom sheet.

## Investigation Findings

### When Removed
- **Date:** February 5, 2026 (v1.4.35)
- **Commit:** `bd99fedb67a28572edfdb1f330addce2f3266f4e`
- **Commit Message:** "feat(v1.4.35): Cheer Me 응원 메시지 기능 및 UI 개선"

### What Was Removed
- Bottom sheet expansion pattern with `onTapExpand` callbacks
- `EmotionInsightCard` tap interaction
- Calls to `AnalysisDetailSheet.show()`

### Why Removed
- UX simplification (inline expansion instead of modal)
- Performance optimization (avoid modal overhead)
- Better visual feedback with AnimatedCrossFade

### What Survived
- `AnalysisDetailSheet` widget remained fully implemented (but unused)
- `EmpathyMessage` retained inline expansion pattern
- Bottom sheet infrastructure intact with:
  - DraggableScrollableSheet
  - Snap positions [0.5, 0.75, 0.95]
  - 40x4px drag handle
  - Haptic feedback

## Implementation

### Changes Made

#### 1. `emotion_insight_card.dart`
**Added:**
- `onTap` callback parameter (optional)
- Visual hint: "자세히 보기" text + chevron icon (shown when onTap provided)
- `InkWell` wrapper with ripple effect (when onTap provided)

**Pattern:** Following MEMORY.md "더보기 패턴"
- ✅ InkWell ripple
- ✅ "자세히 보기" hint
- ✅ Chevron icon
- ✅ Bottom sheet snap positions [0.5, 0.75, 0.95]
- ✅ Haptic feedback (in AnalysisDetailSheet.show())
- ✅ 40x4px drag handle (in AnalysisDetailSheet)

#### 2. `result_card.dart`
**Modified:**
- Connected `EmotionInsightCard` to `AnalysisDetailSheet.show()`
- Added onTap callback: `() => AnalysisDetailSheet.show(context, analysisResult)`
- Import via barrel file (clean architecture)

### Files Modified
```
lib/presentation/widgets/result_card/emotion_insight_card.dart
lib/presentation/widgets/result_card.dart
```

### Files Referenced (No Changes)
```
lib/presentation/widgets/result_card/analysis_detail_sheet.dart  # Already implemented
lib/presentation/widgets/result_card/result_card.dart            # Barrel export file
```

## User Experience Flow

### Before (v1.4.35 - v1.4.41)
1. User sees `EmotionInsightCard` with emotion category + trigger
2. **No interaction possible** - information display only
3. Lengthy content truncated with no way to expand

### After (v1.4.42+)
1. User sees `EmotionInsightCard` with visual hint: "자세히 보기 >"
2. User taps card → InkWell ripple effect
3. Bottom sheet slides up with haptic feedback
4. Full analysis shown with:
   - Emotion category (primary + secondary)
   - Emotion trigger (category + description)
   - Empathy message (full text, no truncation)
   - Cognitive pattern (if present)
5. User can drag sheet to snap positions or dismiss

## Testing

### Static Analysis
```bash
flutter analyze lib/presentation/widgets/result_card/emotion_insight_card.dart lib/presentation/widgets/result_card.dart
# ✅ No issues found!
```

### Test Suite
```bash
flutter test --no-pub
# ✅ All 1473 tests passed!
```

### No Breaking Changes
- Backward compatible: `onTap` parameter is optional
- If no `onTap` provided, card behaves as before (no visual hint, no interaction)
- All existing tests pass without modification

## Design Decisions

### Why Restore Bottom Sheet (vs. Keep Inline)?
1. **User request** - Feature was missed after removal
2. **Better for lengthy content** - Analysis details can be long
3. **Non-intrusive** - Modal doesn't disrupt result card layout
4. **Reusable infrastructure** - `AnalysisDetailSheet` already implemented

### Why Optional onTap?
- **Flexibility** - Component can work with or without tap interaction
- **Backward compatibility** - Existing usage unaffected
- **Clean separation** - Display vs. behavior

### Why Visual Hint?
- **Discoverability** - Users need to know card is tappable
- **Consistency** - Follows MEMORY.md "더보기 패턴"
- **Accessibility** - Clear affordance for interaction

## Future Considerations

### Potential Enhancements
1. **Analytics tracking** - Log bottom sheet opens for usage metrics
2. **Emoji tap expansion** - Add detail view for `SentimentDashboard` emoji tap
3. **Animation polish** - Add subtle scale/elevation feedback on card hover
4. **Accessibility** - Add semantic labels for screen readers

### Alternative Approaches (Considered but Not Implemented)
1. **Inline expansion** - Rejected: disrupts layout, less clean for lengthy content
2. **Navigation to detail screen** - Rejected: overkill for modal content
3. **External link button** - Rejected: less discoverable than card tap

## Git Commit Message Template

```
feat(ui): 전체보기 바텀 시트 복원 — EmotionInsightCard 탭 인터랙션

v1.4.35에서 제거된 "전체보기" 기능 복원.
EmotionInsightCard 탭 시 AnalysisDetailSheet 모달 표시.

Changes:
- emotion_insight_card.dart: onTap 파라미터 추가, InkWell 래핑, 시각적 힌트
- result_card.dart: AnalysisDetailSheet.show() 연결

UX:
- "자세히 보기" 힌트 + chevron 아이콘
- InkWell ripple 피드백
- Draggable bottom sheet (snap: 0.5, 0.75, 0.95)
- Haptic feedback

Test: All 1473 tests passed
Ref: bd99fedb67a28572edfdb1f330addce2f3266f4e (v1.4.35 removal commit)
```

## References

- **Git Investigation Commit:** bd99fedb67a28572edfdb1f330addce2f3266f4e
- **MEMORY.md Pattern:** "UI/UX 더보기 패턴"
- **Pattern File:** `.claude/rules/patterns-navigation.md` (go_router context.pop() for overlays)
- **Testing Pattern:** `.claude/rules/testing.md` (AAA pattern, manual mocks)

---

**Implementation Time:** ~15 minutes
**Complexity:** Low (infrastructure already existed)
**Risk:** Minimal (optional parameter, all tests pass)
**User Impact:** High (restored requested feature)
