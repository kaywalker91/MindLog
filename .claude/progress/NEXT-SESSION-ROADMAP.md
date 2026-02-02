# Next Session Roadmap

**Generated**: 2026-02-02 | **Status**: Ready for execution

---

## Executive Summary

**Current State**: Feature-complete code awaiting integration and QA validation
- 883 tests passing ✓
- Color migration 76% complete (17 Color() usages remain)
- Settings decomposition complete but untracked (701 new lines across 5 files)
- Ready for multi-phase completion

**Session Goal**: Consolidate features, complete migrations, and prepare for release

---

## Priority Task Matrix

| # | Task | Type | Effort | Impact | Blocker | Status |
|---|------|------|--------|--------|---------|--------|
| 1 | **Commit & integrate untracked files** | Integration | LOW | HIGH | NONE | 🔴 BLOCKING |
| 2 | **Complete color migration (17 remaining)** | Refactor | LOW | MEDIUM | None | 🟡 IN-PROGRESS |
| 3 | **Generate tests for 5 new widget sections** | QA | MEDIUM | HIGH | #1 | 🔴 PENDING |
| 4 | **DB recovery + update feature validation** | QA | MEDIUM | MEDIUM | #3 | 🔴 PENDING |
| 5 | **Review & verify all changes** | QA | LOW | HIGH | #4 | 🔴 PENDING |

---

## Detailed Task Analysis

### TASK #1: Commit & Integrate Untracked Files ⚠️ CRITICAL

**Status**: BLOCKING all other tasks

**Untracked Files** (19 items):

#### Core Features (Production Code)
```
lib/core/services/in_app_update_service.dart              (87 lines) - Android Play Store updates
lib/presentation/providers/in_app_update_provider.dart    (45 lines) - State mgmt for in-app updates
lib/presentation/providers/update_check_timer_provider.dart (25 lines) - 6-hour check timer
lib/presentation/providers/today_emotion_provider.dart    (95 lines) - Today's emotion status
```

#### Settings Decomposition (Widget Layer)
```
lib/presentation/widgets/settings/app_info_section.dart           (260 lines) - App version + update UI
lib/presentation/widgets/settings/notification_section.dart       (248 lines) - Notification settings
lib/presentation/widgets/settings/data_management_section.dart    (95 lines) - Data/cache management
lib/presentation/widgets/settings/emotion_care_section.dart       (56 lines) - Emotion care features
lib/presentation/widgets/settings/support_section.dart            (42 lines) - Support + emergency
Total: 701 lines across 5 new widget files
```

#### Tests
```
test/presentation/providers/today_emotion_provider_test.dart     (Riverpod state tests)
test/presentation/providers/update_state_provider_dismiss_test.dart (24h suppress logic)
test/presentation/widgets/settings/settings_sections_test.dart    (Widget tests)
test/presentation/widgets/settings/                                (Settings widget test dir)
```

#### Documentation & Skills
```
docs/skills/barrel-export-gen.md                 (Automation: barrel export generation)
docs/skills/color-migrate.md                     (Automation: color migration)
docs/skills/riverpod-widget-test-gen.md         (Automation: Riverpod widget tests)
.claude/memories/til-code-quality-refactoring.md (Session learning)
.claude/progress/INDEX.md & others               (Analysis artifacts)
```

**Action Items**:
1. Stage core production files (4 provider/service files + 5 widget files)
2. Stage test files (3 test files)
3. Stage skill documentation (3 skill files)
4. Create commit message following Conventional Commits
5. Run `flutter test && flutter analyze` before commit
6. Verify `git push` succeeds

**Estimated Time**: 15 minutes

**Risk**: HIGH - 12 new production files, missing tests for new widgets

---

### TASK #2: Complete Color Migration (22 → 0 remaining)

**Status**: IN-PROGRESS (17 usages remain)

**Current Progress**: 13 files already converted
- Modified files: help_dialog, home_header_title, mindlog_app_bar, network_status_overlay, result_card* (4 files), settings_sections, sos_card, update_prompt_dialog

**Remaining Hardcoded Colors**: 17 usages

**Files with Remaining Color():**
```bash
grep -rn "Color(" lib/presentation --include="*.dart" 2>/dev/null | head -20
```

**Strategy**:
1. Identify remaining 17 Color() usages
2. Map each to theme-aware replacement (see: `.claude/rules/patterns-theme-colors.md`)
3. Use skill: `/color-migrate [file]` for batch conversion
4. Run lint after each file: `flutter analyze`
5. Verify dark/light theme consistency

**Color Mapping Reference**:
```dart
Colors.white       → colorScheme.surface
Colors.black       → colorScheme.onSurface
Colors.grey        → AppColors.textSecondary
Colors.red         → AppColors.error
Colors.opacity(0.1) → colorScheme.shadow.withValues(alpha: 0.05)
```

**Estimated Time**: 30 minutes

**Tests Required**: None (pure refactoring)

---

### TASK #3: Generate Tests for New Widget Sections

**Status**: BLOCKED (requires #1 complete)

**New Widgets Needing Tests** (5 files):
```
- app_info_section.dart (260 lines) - Riverpod + navigation
- notification_section.dart (248 lines) - Notification settings + dialogs
- emotion_care_section.dart (56 lines) - State display
- data_management_section.dart (95 lines) - Action buttons
- support_section.dart (42 lines) - External links
```

**Total Lines**: 701 → Requires ~350-400 lines of widget tests

**Test Pattern** (from `/riverpod-widget-test-gen`):
```dart
group('AppInfoSection', () {
  testWidgets('should display app version', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appInfoProvider.overrideWithValue(AsyncValue.data(mockAppInfo))],
        child: MaterialApp(home: Scaffold(body: AppInfoSection())),
      ),
    );
    expect(find.text('앱 버전'), findsOneWidget);
  });

  testWidgets('should trigger update check on tap', (tester) async {
    // ... test _checkForUpdates
  });
});
```

**Workflow**:
1. Use skill: `/riverpod-widget-test-gen lib/presentation/widgets/settings/app_info_section.dart`
2. Repeat for remaining 4 files
3. Run: `flutter test test/presentation/widgets/settings/`
4. Target coverage: >= 70% per file

**Estimated Time**: 1-1.5 hours

**Coverage Impact**: +60-80 test cases

---

### TASK #4: DB Recovery + Update Feature Validation

**Status**: PENDING (after Task #3)

**Scope**:
1. **DB State Recovery Testing**
   - Verify update_state_provider dismiss functionality (24h suppress)
   - Test schema compatibility (no breaking migrations)
   - Validate timestamp persistence

2. **In-App Update Integration**
   - Android Play Store flow (requires Play Store build)
   - Fallback to web URL on non-Play Store builds
   - iOS URL-based flow unchanged

3. **Provider Invalidation Chain**
   - Ensure update_state_provider invalidates correctly when:
     - User dismisses notification (24h suppress)
     - App checks for updates (6h timer)
     - New version is available (UI refresh)

**Test Commands**:
```bash
flutter test test/presentation/providers/update_state_provider_dismiss_test.dart
flutter test test/presentation/providers/today_emotion_provider_test.dart
./scripts/run.sh quality  # Full gate: lint + format + analyze + test
```

**Skill to Use**: `/db-state-recovery verify && /db-state-recovery test-gen`

**Estimated Time**: 1 hour

---

### TASK #5: Final Review & Verification

**Status**: PENDING (after all tasks)

**Checklist**:
- [ ] All 883+ tests passing
- [ ] Zero lint warnings (excluding pre-existing)
- [ ] Flutter analyze green
- [ ] Color migration complete (0 Color() usages in presentation layer)
- [ ] New widget tests at 70%+ coverage
- [ ] Commit messages follow Conventional Commits
- [ ] git push succeeds
- [ ] CI/CD green (GitHub Actions)

**Review Commands**:
```bash
flutter test --coverage
flutter analyze
flutter format --set-exit-if-changed lib/
git diff --stat
```

**Estimated Time**: 30 minutes

---

## Session Execution Plan

### Phase 1: Foundation (30 mins) 🔴 BLOCKING
1. **Commit untracked files**
   ```bash
   git add lib/core/services/in_app_update_service.dart
   git add lib/presentation/providers/{in_app_update,today_emotion,update_check_timer}_provider.dart
   git add lib/presentation/widgets/settings/{app_info,notification,data_management,emotion_care,support}_section.dart
   git add test/presentation/providers/today_emotion_provider_test.dart
   git add test/presentation/providers/update_state_provider_dismiss_test.dart
   git add test/presentation/widgets/settings/settings_sections_test.dart
   git add docs/skills/{barrel-export-gen,color-migrate,riverpod-widget-test-gen}.md

   git commit -m "feat(settings): decompose settings into 5 focused widget sections + in-app update providers

   - Extract AppInfoSection (260L): app version, update check, privacy policy
   - Extract NotificationSection (248L): notification timing, DoNotDisturb, MindCare
   - Extract DataManagementSection (95L): cache clear, data export, theme
   - Extract EmotionCareSection (56L): AI character, SOS emergency contact
   - Extract SupportSection (42L): Support, feedback, emergency resources
   - Add InAppUpdateProvider: Android Play Store update flow
   - Add TodayEmotionProvider: Today's emotion status calculation
   - Add UpdateCheckTimerProvider: 6-hour background update checks
   - Total: 701 new lines, 3 new providers

   Tests: update_state_provider_dismiss (24h suppress), settings_sections widget tests

   Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
   ```

2. Verify: `flutter test && flutter analyze`

### Phase 2: Color Migration (30 mins)
1. Find remaining 17 usages:
   ```bash
   grep -rn "Color(" lib/presentation --include="*.dart"
   ```

2. Batch migrate with `/color-migrate` skill

3. Verify: `flutter analyze` passes

### Phase 3: Widget Test Generation (1.5 hours)
1. Use `/riverpod-widget-test-gen` for each new section file
2. Run: `flutter test test/presentation/widgets/settings/`
3. Target: 70%+ coverage per file

### Phase 4: QA & Validation (1.5 hours)
1. DB recovery tests: `/db-state-recovery verify && test-gen`
2. Provider chain validation
3. Full quality gates: `./scripts/run.sh quality`
4. Review final diffs: `git diff main --stat`

### Phase 5: Final Review (30 mins)
1. Lint/format/analyze/test all passing
2. Coverage report: `/coverage`
3. Push to remote: `git push`
4. Verify CI/CD passing

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Untracked files at risk | HIGH | Commit immediately (Phase 1) |
| Missing widget tests | HIGH | Generate tests (Phase 3) |
| Incomplete color migration | MEDIUM | Batch migrate remaining 17 (Phase 2) |
| Provider invalidation issues | MEDIUM | Use `/provider-invalidation-audit` (Phase 4) |
| CI/CD failures | LOW | Run full quality gates before push |

---

## Time Budget

| Phase | Duration | Total |
|-------|----------|-------|
| 1. Commit untracked files | 30 min | 30 min |
| 2. Color migration | 30 min | 1 hr |
| 3. Widget test generation | 1.5 hrs | 2.5 hrs |
| 4. QA & validation | 1.5 hrs | 4 hrs |
| 5. Final review | 30 min | 4.5 hrs |
| **Total** | | **~4.5 hours** |

**Recommended Split**:
- Session 1: Phases 1-2 (1 hour) → commit before context limit
- Session 2: Phases 3-5 (3.5 hours) → complete with full context

---

## Commands Ready to Use

### Quick Reference
```bash
# Verify all tests pass
flutter test

# Static analysis
flutter analyze

# Format check
flutter format --set-exit-if-changed lib/

# View remaining Color() usages
grep -rn "Color(" lib/presentation --include="*.dart"

# Run quality gates
./scripts/run.sh quality

# Coverage report
flutter test --coverage

# Commit untracked (Phase 1)
git add -A && git commit -m "feat: ..."

# Push to remote
git pull --rebase && git push
```

### Skill Commands
```bash
/color-migrate lib/presentation/widgets/result_card/sos_card.dart
/riverpod-widget-test-gen lib/presentation/widgets/settings/app_info_section.dart
/db-state-recovery verify
/coverage
/review lib/presentation/widgets/settings/app_info_section.dart
```

---

## Files Ready for Action

### Must Commit (Phase 1)
- [x] lib/core/services/in_app_update_service.dart
- [x] lib/presentation/providers/in_app_update_provider.dart
- [x] lib/presentation/providers/today_emotion_provider.dart
- [x] lib/presentation/providers/update_check_timer_provider.dart
- [x] lib/presentation/widgets/settings/{app_info,notification,data_management,emotion_care,support}_section.dart
- [x] test/presentation/providers/today_emotion_provider_test.dart
- [x] test/presentation/providers/update_state_provider_dismiss_test.dart

### To Migrate (Phase 2)
- [ ] lib/presentation/widgets/* (17 Color() remaining)

### To Test (Phase 3)
- [ ] lib/presentation/widgets/settings/app_info_section.dart
- [ ] lib/presentation/widgets/settings/notification_section.dart
- [ ] lib/presentation/widgets/settings/emotion_care_section.dart
- [ ] lib/presentation/widgets/settings/data_management_section.dart
- [ ] lib/presentation/widgets/settings/support_section.dart

---

## Success Criteria

✅ All 883+ tests passing
✅ Zero hardcoded Color() in presentation layer
✅ 5 new widget files with 70%+ test coverage
✅ All changes committed and pushed
✅ CI/CD pipeline green
✅ No lint warnings (excluding pre-existing)

---

## Next Session Starts Here

If context limit reached during this session:
1. **Immediate Actions**:
   - Save this file (DONE ✓)
   - Commit progress file: `git add .claude/progress/current.md && git commit`
   - Push current work: `git push`

2. **Resume from Phase [X]**:
   - Read this file first
   - Start from last completed phase
   - Verify: `flutter test && flutter analyze`

3. **Rollback Point**:
   - All production tests passing (883 tests)
   - Clean git status before Phase 1
   - No breaking changes to main branch

---

**Last Updated**: 2026-02-02 | **Session ID**: analysis-session-feb2
**Next Session Target**: Complete all 5 phases + push to remote
