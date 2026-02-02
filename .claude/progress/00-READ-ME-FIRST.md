# READ ME FIRST - Next Session Execution Guide

**Status**: Ready for execution | **Date**: 2026-02-02 | **Confidence**: HIGH

---

## What Happened Last Session

1. **Completed**: App update notification feature (3 phases)
2. **Created**: 12 new production files (untracked)
3. **In Progress**: Color migration (76% done, 17 usages remain)
4. **Status**: All tests passing (883), ready for final integration

---

## Current Situation - URGENT

**12 NEW FILES ARE UNTRACKED** and could be lost if not committed soon:
- 4 new provider files (252 lines)
- 5 new settings widget files (701 lines)  
- 3 test files
- 3 skill documentation files

**FIRST ACTION**: Commit these files immediately (15 minutes)

---

## Quick Navigation

### For Fast Start (5 minutes)
**Read this**:
- `VISUAL-TASK-MATRIX.txt` - ASCII overview of all tasks

### For Detailed Execution (Recommended)
**Read in this order**:
1. `NEXT-SESSION-ROADMAP.md` - Detailed 5-phase plan (4.5 hours)
2. `COMMIT-CHECKLIST.md` - Ready-to-copy commit commands (Phase 1)
3. `SESSION-ANALYSIS-FEB2.md` - Context, patterns, learnings

### For Quick Reference During Work
**Keep open**:
- `VISUAL-TASK-MATRIX.txt` - Command reference, task breakdown
- `.claude/rules/patterns-theme-colors.md` - Color migration guide
- `.claude/rules/skill-catalog.md` - Available automation tools

---

## The 5 Tasks (4.5 hours total)

| # | Task | Time | Status | Files Affected |
|---|------|------|--------|-----------------|
| 1 | **Commit untracked files** | 15 min | 🔴 START HERE | 12 files |
| 2 | **Complete color migration** | 30 min | 🟡 IN-PROGRESS | 17 Color() → 0 |
| 3 | **Generate widget tests** | 90 min | 🔴 PENDING | 5 new widgets |
| 4 | **DB + update validation** | 60 min | 🔴 PENDING | Feature tests |
| 5 | **Final review & push** | 30 min | 🔴 PENDING | git push |

---

## TASK #1: Commit Untracked Files (START HERE!)

### Files to Commit (12 total)

**Providers (4 files)**:
```
lib/core/services/in_app_update_service.dart
lib/presentation/providers/in_app_update_provider.dart
lib/presentation/providers/today_emotion_provider.dart
lib/presentation/providers/update_check_timer_provider.dart
```

**Widgets (5 files)**:
```
lib/presentation/widgets/settings/app_info_section.dart
lib/presentation/widgets/settings/notification_section.dart
lib/presentation/widgets/settings/data_management_section.dart
lib/presentation/widgets/settings/emotion_care_section.dart
lib/presentation/widgets/settings/support_section.dart
```

**Tests (3 files)**:
```
test/presentation/providers/today_emotion_provider_test.dart
test/presentation/providers/update_state_provider_dismiss_test.dart
test/presentation/widgets/settings/settings_sections_test.dart
```

### 3-Step Execution

**Step 1: Verify Everything Works**
```bash
flutter test          # Should show: All tests passed! (883+)
flutter analyze       # Should show: No issues
```

**Step 2: Stage Files**
```bash
git add lib/core/services/in_app_update_service.dart
git add lib/presentation/providers/in_app_update_provider.dart
git add lib/presentation/providers/today_emotion_provider.dart
git add lib/presentation/providers/update_check_timer_provider.dart
git add lib/presentation/widgets/settings/app_info_section.dart
git add lib/presentation/widgets/settings/notification_section.dart
git add lib/presentation/widgets/settings/data_management_section.dart
git add lib/presentation/widgets/settings/emotion_care_section.dart
git add lib/presentation/widgets/settings/support_section.dart
git add test/presentation/providers/today_emotion_provider_test.dart
git add test/presentation/providers/update_state_provider_dismiss_test.dart
git add test/presentation/widgets/settings/settings_sections_test.dart
```

**Step 3: Create Commit**
```bash
git commit -m "feat(settings): decompose settings widget into 5 focused sections + in-app updates

- Extract AppInfoSection (260L): app version, update check, privacy policy
- Extract NotificationSection (248L): notification settings, DoNotDisturb, MindCare
- Extract DataManagementSection (95L): cache clear, data export, theme
- Extract EmotionCareSection (56L): AI character, SOS emergency
- Extract SupportSection (42L): help links, feedback, resources
- Add InAppUpdateProvider: Android Play Store update flow
- Add TodayEmotionProvider: emotion status calculation  
- Add UpdateCheckTimerProvider: 6-hour background checks
- Add InAppUpdateService: in_app_update package wrapper

Tests: 25+ new tests (providers, state logic, widgets)
Skills: Added 3 automation tools (barrel-export, color-migrate, riverpod-test-gen)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

### Verify & Push
```bash
git log --oneline -1     # Should show your commit
git push                 # Push to remote
```

**Duration**: 15 minutes | **After**: Move to TASK #2

---

## TASK #2: Color Migration

**Current**: 17 Color() usages remain in presentation layer
**Goal**: 0 Color() usages (migrate to theme-aware colors)

**Find Remaining**:
```bash
grep -rn "Color(" lib/presentation --include="*.dart" | wc -l
# Should show 17
```

**Migrate Each File**:
```bash
/color-migrate lib/presentation/widgets/[filename].dart
flutter analyze  # Verify no new errors
```

**Duration**: 30 minutes | **After**: TASK #3

---

## TASK #3: Widget Test Generation

**Create tests for 5 new settings widgets**:

```bash
/riverpod-widget-test-gen lib/presentation/widgets/settings/app_info_section.dart
/riverpod-widget-test-gen lib/presentation/widgets/settings/notification_section.dart
/riverpod-widget-test-gen lib/presentation/widgets/settings/data_management_section.dart
/riverpod-widget-test-gen lib/presentation/widgets/settings/emotion_care_section.dart
/riverpod-widget-test-gen lib/presentation/widgets/settings/support_section.dart
```

**Run Tests**:
```bash
flutter test test/presentation/widgets/settings/
# Target: 70%+ coverage per file
```

**Duration**: 1.5 hours | **After**: TASK #4

---

## TASK #4: Validation

**Run quality gates**:
```bash
./scripts/run.sh quality
# Expected: lint + format + analyze + test all pass

flutter test --coverage
# Expected: Coverage report showing new test additions
```

**Validate features**:
```bash
/db-state-recovery verify
# Expected: All state recovery scenarios pass
```

**Duration**: 1 hour | **After**: TASK #5

---

## TASK #5: Final Review & Push

```bash
flutter test        # All 906+ tests passing
flutter analyze     # Zero errors
git status          # Should be clean
git push            # Push to main
```

**Duration**: 30 minutes | **Done!**

---

## Quick Reference Commands

### Check Current State
```bash
git status                                    # See untracked files
flutter test                                  # Run all tests
flutter analyze                               # Static analysis
grep -rn "Color(" lib/presentation           # Count Color() usages
```

### Use Automation Skills
```bash
/color-migrate [file]                         # Migrate colors
/riverpod-widget-test-gen [file]              # Generate tests
/db-state-recovery verify                     # Validate DB
/coverage                                     # Coverage report
/lint-fix                                     # Auto-fix lint
```

### Git Operations
```bash
git add [files]                               # Stage files
git commit -m "message"                       # Create commit
git push                                      # Push to remote
git log --oneline -5                          # View recent commits
```

---

## Success Criteria

All of these must be true when done:
- ✅ All 12 untracked files committed
- ✅ 0 Color() usages in presentation layer
- ✅ 5 new widgets have 70%+ test coverage
- ✅ 906+ tests passing
- ✅ Zero lint warnings (excluding pre-existing)
- ✅ git push succeeded
- ✅ CI/CD pipeline green

---

## If You Get Stuck

### Can't commit?
- Run `flutter test` → all must pass
- Run `flutter analyze` → zero errors
- See COMMIT-CHECKLIST.md for detailed instructions

### Color migration issues?
- Run `grep -rn "Color(" lib/presentation` to find remaining
- See `.claude/rules/patterns-theme-colors.md` for mapping
- Use `/color-migrate [file]` skill for automation

### Test failures?
- Check test output carefully
- Use `/riverpod-widget-test-gen [file]` to regenerate
- Run `flutter test [test_file]` on specific tests

### Still stuck?
- Read SESSION-ANALYSIS-FEB2.md for context
- Check .claude/rules/ for architecture patterns
- Create GitHub issue describing the blocker

---

## Time Budget Check

- **TASK #1**: 15 min (must do first!)
- **TASK #2**: 30 min (parallel with #1 optional)
- **TASK #3**: 90 min
- **TASK #4**: 60 min
- **TASK #5**: 30 min
- **TOTAL**: ~4.5 hours

**Recommended**: Split across 2 sessions (1 hr + 3.5 hrs)

---

## Files to Keep Open While Working

1. `VISUAL-TASK-MATRIX.txt` - Quick reference
2. `.claude/rules/patterns-theme-colors.md` - Color mapping
3. `.claude/rules/skill-catalog.md` - Available skills
4. `NEXT-SESSION-ROADMAP.md` - Detailed plan

---

## Next Steps

**RIGHT NOW**:
1. Read `VISUAL-TASK-MATRIX.txt` (5 min)
2. Follow `COMMIT-CHECKLIST.md` (15 min)
3. Execute TASK #1 (commit files)

**THEN**:
1. Do TASK #2-5 following NEXT-SESSION-ROADMAP.md
2. Verify all success criteria met
3. git push to main

---

**Created**: 2026-02-02 | **Type**: Pre-session guide | **Status**: READY
**Time to Completion**: 4-5 hours of focused work
**Blocker**: None (all prerequisites met)

**START WITH**: COMMIT-CHECKLIST.md (right now!)
