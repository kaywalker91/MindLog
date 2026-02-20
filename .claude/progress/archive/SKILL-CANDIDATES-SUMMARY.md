# Skill Candidates Summary - 5 Automation Opportunities

**Prepared**: 2026-02-02
**Session Analysis Period**: Jan 27 - Feb 2, 2026 (commits abd7bdd → 6e2b1a1)
**Combined Time Savings Potential**: **73% reduction** (200 min → 53 min per cycle)

---

## The 5 Candidates (At a Glance)

### 🔴 P1: `/provider-invalidate-chain` - **Prevents Subtle Bugs**
- **What it does**: Traces Riverpod provider dependency graph and generates multi-layer invalidation sequences
- **Problem solved**: Missing invalidation at one layer causes stale data
- **Example**: DB recovery needs `Repository → UseCase → Provider` chain
- **Time saved**: 25 min → 7 min per scenario (**72%**)
- **Frequency**: Quarterly (4x/year)
- **Complexity**: High (requires provider graph analysis)
- **Status**: Skill file already exists (`provider-invalidate-chain.md`), needs implementation

---

### 🟡 P2-Top: `/color-migrate` - **Quick Win**
- **What it does**: Bulk-replace hardcoded `Colors.xxx` with theme-aware `colorScheme.*` refs
- **Problem solved**: 41+ color references scattered across UI → hard to theme/dark mode
- **Example**: `Colors.white` → `colorScheme.surface`
- **Time saved**: 45 min → 8 min per migration pass (**82%**)
- **Frequency**: Monthly (dark theme updates)
- **Complexity**: Low (regex + mapping table from rules)
- **Dependency**: `.claude/rules/patterns-theme-colors.md` (already exists with mapping table)

---

### 🟡 P2-Mid: `/widget-decompose-audit` - **Improves Maintainability**
- **What it does**: Scans large widgets, suggests decomposition boundaries (200+ line threshold)
- **Problem solved**: Monolithic 300-500 line widgets hard to test/reuse
- **Example**: `DiaryListScreen` (341 lines) → 5 focused files
- **Time saved**: 90 min → 20 min per decomposition (**78%**)
- **Frequency**: Monthly (1-2 large screens)
- **Complexity**: Medium (AST parsing + structure generation)
- **Outputs**: Widget stubs + barrel export + test skeleton

---

### 🟡 P2-Low: Enhance `/widget-test-scaffold` - **Better Coverage**
- **What it does**: Generate widget test boilerplate + fixtures from widget parameters
- **Problem solved**: Test skeleton generation is repetitive (30+ min per widget)
- **Example**: Auto-create `MockDiaryRepository`, `ProviderScope.overrides`
- **Time saved**: 30 min → 8 min per widget test (**73%**)
- **Frequency**: Per new widget (3-4 widgets/month)
- **Complexity**: Medium (widget introspection + Riverpod fixture patterns)
- **Note**: `/widget-test` skill exists; this is enhancement

---

### 🟢 P3: `/barrel-export-gen` - **Quality of Life**
- **What it does**: Auto-generate barrel export files for widget collections
- **Problem solved**: Manual `library/export` boilerplate
- **Example**: Create `statistics.dart` with 4 export statements
- **Time saved**: 5 min → 1 min per widget group (**80%**)
- **Frequency**: Weekly (with new widgets)
- **Complexity**: Low (file scanning + templating)
- **Bonus**: Can auto-update dependent imports

---

## Implementation Roadmap

### Week of Feb 2-8 (Phase 1: Foundation)
**Target**: 2 skills addressing correctness + quick wins

- [ ] **Implement `/provider-invalidate-chain`** (P1)
  - Effort: ~4 hours
  - Requires: AST provider graph analysis
  - Payoff: Prevents silent stale-data bugs

- [ ] **Implement `/color-migrate`** (P2)
  - Effort: ~2 hours
  - Requires: Mapping table from rules (already done!)
  - Payoff: Immediate productivity boost

### Week of Feb 9-15 (Phase 2: Decomposition)
**Target**: Widget quality improvements

- [ ] **Implement `/widget-decompose-audit`** (P2)
  - Effort: ~3 hours
  - Requires: Dart AST parsing, file generation
  - Payoff: Structural improvements + easier testing

- [ ] **Enhance `/widget-test-scaffold`** (existing skill)
  - Effort: ~2 hours
  - Requires: Widget parameter introspection, Riverpod patterns
  - Payoff: Faster test creation

### Week of Feb 16+ (Phase 3: Polish)
**Target**: Developer convenience

- [ ] **Implement `/barrel-export-gen`** (P3)
  - Effort: ~1.5 hours
  - Payoff: Less boilerplate

---

## Expected ROI (3-Month Horizon)

### Time Investment
- 5 skills × avg 2.4 hours = **12 total development hours**

### Time Recovery (Per month, assume 2-3 decomposition cycles)

**Before**:
- 2 decomposition cycles/month × 200 min = 400 min/month
- Or ~6.7 hours/month

**After**:
- 2 decomposition cycles/month × 53 min = 106 min/month
- Or ~1.8 hours/month
- **Monthly savings: 4.9 hours**

**3-Month ROI**:
- 12 hours invested
- 14.7 hours recovered (3 × 4.9)
- **Net payoff: 2.7 hours** (positive after month 3)
- **Annual projection: ~58 hours** (7.25 work days)

---

## Skill Interaction Matrix

```
┌─────────────────────────────────────────────────────────────┐
│                    Provider Invalidation                     │
│                                                             │
│  provider-invalidate-chain ──┐                             │
│  (generates sequences)        │                             │
│                               ↓                             │
│                   provider-invalidation-audit                │
│                   (static verification)                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Widget Decomposition                      │
│                                                             │
│  widget-decompose-audit ──┐                                │
│  (identifies boundaries)   ├──→ widget-test-scaffold       │
│                           └──→ barrel-export-gen           │
│                                                             │
│  color-migrate (independent)                               │
└─────────────────────────────────────────────────────────────┘
```

**Dependency order**:
1. `provider-invalidate-chain` (independent)
2. `color-migrate` (independent)
3. `widget-decompose-audit` + enhance `widget-test-scaffold` (dependent on #1-2 for context)
4. `barrel-export-gen` (can run after #3)

---

## Existing Infrastructure Used

### Rules Files (Already Created)
✅ `.claude/rules/patterns-theme-colors.md` - Color mapping table
✅ `.claude/rules/patterns-navigation.md` - Navigation patterns
✅ `.claude/rules/patterns-soft-delete.md` - Soft delete pattern
✅ `.claude/rules/workflow.md` - Build/test commands

### Memory Files (Already Created)
✅ `.claude/memories/firebase-functions-patterns.md` - Backend patterns
✅ `.claude/memories/mindlog-til-gorouter-popscope.md` - Recent discoveries
✅ `.claude/memories/til-riverpod-multilayer-invalidation.md` - Invalidation strategy

### Existing Skills Referenced
✅ `/test-unit-gen` (enhance with widget test patterns)
✅ `/widget-decompose` (may already exist informally)
✅ `/swarm-review` (for code review aspect)

---

## Notes for Implementation

### `/provider-invalidate-chain` Critical Requirements
- Must scan across `domain/`, `data/`, `presentation/` layers
- Generate ordered invalidation sequence (layers matter)
- Include safety check: validate all deps invalidated
- Provide `invalidateDiaryChain()` helper auto-generation
- Test with `ProviderScope.overrides` mock setup

### `/color-migrate` Critical Requirements
- Preserve opacity/alpha values during replacement
- Respect precedence: `colorScheme` > `AppColors` > hardcoded
- Generate diff preview (no auto-apply without `--apply` flag)
- Handle edge cases: conditional colors, computed colors

### `/widget-decompose-audit` Critical Requirements
- Suggest extraction boundaries (not auto-apply)
- Generate widget stubs preserving functionality
- Create barrel export with library comment
- Identify private vs public methods for reusability
- Flag extension-worthy display logic

---

## Risk Mitigation

### Code Safety
- All skills run in `--preview` mode by default
- Require explicit `--apply` to modify files
- Generate git-compatible output for manual review
- Provide rollback instructions

### Testing Safety
- Generated code must pass existing tests
- New test skeletons need manual assertion completion
- Provider invalidation needs mock isolation

### Documentation
- Each skill ships with inline help (`--help` flag)
- Examples for common use cases in skill files
- Links to pattern files in `.claude/rules/`

---

## Decision Matrix for Prioritization

| Skill | Effort | Impact | Frequency | Risk | P-Value |
|-------|--------|--------|-----------|------|---------|
| `/provider-invalidate-chain` | 4h | 🔴 High (correctness) | Quarterly | Low | **P1** |
| `/color-migrate` | 2h | 🟡 Medium (quality) | Monthly | Very Low | **P2** |
| `/widget-decompose-audit` | 3h | 🟡 Medium (maintainability) | Monthly | Medium | **P2** |
| `/widget-test-scaffold` enhance | 2h | 🟡 Medium (coverage) | Monthly | Low | **P2** |
| `/barrel-export-gen` | 1.5h | 🟢 Low (convenience) | Weekly | Very Low | **P3** |

**Recommendation**: Implement P1 + top 2 of P2 in Feb, defer P3 to March.

---

## Progress Tracking

- [x] Session analysis complete
- [x] Pattern identification complete
- [x] ROI calculation complete
- [ ] P1 implementation kickoff
- [ ] P2 implementation (Feb 9+)
- [ ] P3 implementation (Feb 23+)
- [ ] Team communication

---

**Document**: Skill Candidates Summary
**Version**: 1.0
**Status**: Ready for Implementation Planning
**Next Review**: 2026-02-09
