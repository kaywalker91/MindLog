# Commit Checklist - TASK #1 Priority

**Status**: Ready to execute
**Created**: 2026-02-02

---

## Quick Summary

**12 new production files** (4 providers + 5 widget sections + 3 tests) have been created but are not yet committed to git.

**Risk**: These files could be lost if not committed soon.

**Time to Commit**: 5-10 minutes

---

## Files to Stage & Commit

### Production Code (9 files)

#### Core Services & Providers (4 files - 252 lines)
```
lib/core/services/in_app_update_service.dart              (87L)
lib/presentation/providers/in_app_update_provider.dart    (45L)
lib/presentation/providers/update_check_timer_provider.dart (25L)
lib/presentation/providers/today_emotion_provider.dart    (95L)
```

#### Settings Widget Decomposition (5 files - 701 lines)
```
lib/presentation/widgets/settings/app_info_section.dart           (260L)
lib/presentation/widgets/settings/notification_section.dart       (248L)
lib/presentation/widgets/settings/data_management_section.dart    (95L)
lib/presentation/widgets/settings/emotion_care_section.dart       (56L)
lib/presentation/widgets/settings/support_section.dart            (42L)
```

### Test Files (3 files)
```
test/presentation/providers/today_emotion_provider_test.dart
test/presentation/providers/update_state_provider_dismiss_test.dart
test/presentation/widgets/settings/settings_sections_test.dart
```

### Documentation (3 skill files - optional but recommended)
```
docs/skills/barrel-export-gen.md
docs/skills/color-migrate.md
docs/skills/riverpod-widget-test-gen.md
```

---

## Pre-Commit Verification

### Run Tests
```bash
flutter test
# Expected: ✓ 883+ tests passing
```

### Run Analysis
```bash
flutter analyze
# Expected: ✓ No errors/warnings (excluding pre-existing)
```

### Verify Format
```bash
flutter format --set-exit-if-changed lib/
# Expected: ✓ All files properly formatted
```

---

## Commit Command

### Option 1: Stage All Files at Once (Recommended)
```bash
git add \
  lib/core/services/in_app_update_service.dart \
  lib/presentation/providers/in_app_update_provider.dart \
  lib/presentation/providers/today_emotion_provider.dart \
  lib/presentation/providers/update_check_timer_provider.dart \
  lib/presentation/widgets/settings/app_info_section.dart \
  lib/presentation/widgets/settings/notification_section.dart \
  lib/presentation/widgets/settings/data_management_section.dart \
  lib/presentation/widgets/settings/emotion_care_section.dart \
  lib/presentation/widgets/settings/support_section.dart \
  test/presentation/providers/today_emotion_provider_test.dart \
  test/presentation/providers/update_state_provider_dismiss_test.dart \
  test/presentation/widgets/settings/settings_sections_test.dart \
  docs/skills/barrel-export-gen.md \
  docs/skills/color-migrate.md \
  docs/skills/riverpod-widget-test-gen.md
```

### Option 2: Stage by Category
```bash
# Providers
git add lib/presentation/providers/in_app_update_provider.dart
git add lib/presentation/providers/today_emotion_provider.dart
git add lib/presentation/providers/update_check_timer_provider.dart
git add lib/core/services/in_app_update_service.dart

# Widget sections
git add lib/presentation/widgets/settings/app_info_section.dart
git add lib/presentation/widgets/settings/notification_section.dart
git add lib/presentation/widgets/settings/data_management_section.dart
git add lib/presentation/widgets/settings/emotion_care_section.dart
git add lib/presentation/widgets/settings/support_section.dart

# Tests
git add test/presentation/providers/today_emotion_provider_test.dart
git add test/presentation/providers/update_state_provider_dismiss_test.dart
git add test/presentation/widgets/settings/settings_sections_test.dart

# Skills
git add docs/skills/barrel-export-gen.md
git add docs/skills/color-migrate.md
git add docs/skills/riverpod-widget-test-gen.md
```

### Create Commit (Copy-paste ready)

```bash
git commit -m "feat(settings): decompose settings widget into 5 focused sections + in-app updates

- Extract AppInfoSection (260L): app version, update check, privacy policy
- Extract NotificationSection (248L): notification settings, DoNotDisturb, MindCare
- Extract DataManagementSection (95L): cache clear, data export, theme toggle
- Extract EmotionCareSection (56L): AI character selection, SOS emergency
- Extract SupportSection (42L): help links, feedback, emergency resources
- Add InAppUpdateProvider: Android Play Store in-app update flow
- Add TodayEmotionProvider: calculation of today's emotion status (latest diary)
- Add UpdateCheckTimerProvider: 6-hour background update check timer
- Add InAppUpdateService: wrapper for in_app_update package

New Tests:
- TodayEmotionProvider state calculation tests
- UpdateStateProvider 24-hour dismissal suppress logic
- AppInfoSection widget interaction tests

File Decomposition Summary:
- Removed 593 lines from settings_sections.dart
- Added 701 lines across 5 new widget files
- Net: +108 lines (code cleanliness improvement)

Skills Documentation:
- Added barrel-export-gen.md (automated export index generation)
- Added color-migrate.md (hardcoded Color() migration automation)
- Added riverpod-widget-test-gen.md (Riverpod widget test generation)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Post-Commit Steps

### Verify Commit Succeeded
```bash
git log --oneline -1
# Expected: feat(settings): decompose settings widget into 5 focused sections...
```

### Push to Remote
```bash
git pull --rebase origin main
git push origin main
```

### Verify CI/CD Triggered
- Check GitHub Actions: https://github.com/YOUR_REPO/actions
- Expected: All checks passing (lint, test, build)

---

## Rollback Plan (if needed)

```bash
# Undo commit (keep files)
git reset --soft HEAD~1

# Undo commit (delete files)
git reset --hard HEAD~1

# Check git log
git log --oneline -5
```

---

## Completion Checklist

- [ ] All tests passing (flutter test)
- [ ] All analysis passing (flutter analyze)
- [ ] Files staged (git add)
- [ ] Commit created with message
- [ ] Commit pushed to remote
- [ ] GitHub Actions passing
- [ ] Next session: Start with TASK #2 (Color Migration)

---

**Estimated Time**: 10 minutes
**Priority**: 🔴 CRITICAL (untracked code at risk)
**Next**: TASK #2 - Complete color migration (22→0 Color() usages)
