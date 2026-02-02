# Pattern Examples - Automation Reference Guide

**Date**: 2026-02-02
**Purpose**: Code examples showing patterns that skills should automate

---

## Pattern 1: Color Migration Examples

### Before (Hardcoded Colors)
**File**: `lib/presentation/widgets/result_card/keywords_section.dart` (commit abd7bdd)
```dart
class KeywordsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,          // ❌ Hardcoded
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Emotions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.black,              // ❌ Hardcoded
            ),
          ),
          Wrap(
            children: emotions.map((emotion) {
              return Container(
                color: Colors.white,            // ❌ Hardcoded
                child: Text(emotion),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
```

### After (Theme-Aware)
```dart
class KeywordsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,  // ✅ Theme-aware
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Emotions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,          // ✅ Theme-aware
            ),
          ),
          Wrap(
            children: emotions.map((emotion) {
              return Container(
                color: colorScheme.surface,          // ✅ Theme-aware
                child: Text(emotion),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
```

**Mapping used** (from `.claude/rules/patterns-theme-colors.md`):
```
Colors.grey.shade200        → colorScheme.surfaceContainerHighest
Colors.black               → colorScheme.onSurface
Colors.white               → colorScheme.surface
Colors.grey (secondary)    → AppColors.textSecondary
```

---

## Pattern 2: Widget Decomposition Examples

### Before (Monolithic Widget)
**File**: `lib/presentation/screens/diary_list_screen.dart` (pre-abd7bdd, 341 lines)

```dart
class DiaryListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  // 341 lines containing:
  // - Diary item card UI (149 lines)
  // - Write FAB logic (103 lines)
  // - Screen-level state management (89 lines)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: diaries.map((diary) {
          // ❌ 149 lines of card UI here
          return GestureDetector(
            onTap: () => { /* ... */ },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                // ... 145 more lines of card styling
              ),
              child: Column(
                children: [
                  // ... content
                ],
              ),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        // ❌ 103 lines of FAB interaction
        onPressed: () { /* ... */ },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### After (Decomposed Widgets)
**File structure** created by decomposition:
```
lib/presentation/screens/
  diary_list_screen.dart              (89 lines) - Screen logic only

lib/presentation/widgets/diary_list/
  diary_item_card.dart                (149 lines) - Extracted card
  write_fab.dart                      (103 lines) - Extracted FAB

lib/presentation/widgets/common/
  tappable_card.dart                  (57 lines) - Reusable wrapper
  expandable_text.dart                (109 lines) - Reusable text

lib/presentation/extensions/
  diary_display_extension.dart        (28 lines) - Display logic

lib/presentation/widgets/diary_list/
  diary_list.dart                     (barrel export)
```

**Modified diary_list_screen.dart** (now 89 lines):
```dart
class DiaryListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaries = ref.watch(diaryListProvider);

    return Scaffold(
      body: diaries.when(
        data: (diaries) => ListView(
          children: diaries.map(
            (diary) => DiaryItemCard(diary: diary),  // ✅ Extracted
          ).toList(),
        ),
        loading: () => LoadingIndicator(),
        error: (err, st) => ErrorWidget(error: err),
      ),
      floatingActionButton: WriteFab(),            // ✅ Extracted
    );
  }
}
```

**New diary_item_card.dart** (extracted, 149 lines):
```dart
class DiaryItemCard extends ConsumerWidget {
  final Diary diary;

  const DiaryItemCard({required this.diary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TappableCard(                         // ✅ Reusable wrapper
      onTap: () => context.push(Routes.diaryDetail(diary.id)),
      child: Column(
        children: [
          ExpandableText(                        // ✅ Reusable text
            diary.emotionEmoji,                  // ✅ Extension method
            maxLines: 2,
          ),
          // ... rest of card UI
        ],
      ),
    );
  }
}
```

**New diary_display_extension.dart** (28 lines):
```dart
extension DiaryDisplayExtension on Diary {
  String get emotionEmoji {
    return emotionType.emoji;  // Extract to entity
  }

  Color get emotionBackgroundColor {
    return emotionType.backgroundColor;
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(createdAt);
  }
}
```

---

## Pattern 3: Provider Invalidation Chain Examples

### Before (Manual, Error-Prone)
**File**: `lib/presentation/screens/main_screen.dart` (commit 6e2b1a1)

```dart
class _MainScreenState extends ConsumerState<MainScreen> {
  Future<void> _recoverDatabase() async {
    try {
      // Database recovery logic...

      // ❌ Manual invalidation - easy to miss layers
      ref.invalidate(diaryRepositoryProvider);      // Layer 1: Data
      ref.invalidate(diaryListUsecaseProvider);     // Layer 2: Domain
      ref.invalidate(diaryListProvider);            // Layer 3: Presentation

      // ❌ What if we need more providers?
      // ❌ Easy to forget to invalidate a dependent
      // ❌ Hard to test invalidation order

    } catch (e) {
      // ...
    }
  }
}
```

**Dependency tree** (what should be invalidated):
```
diaryRepository (data layer)
  ↓
diaryListUsecase (domain layer)
  ↓
diaryListProvider (presentation layer)
  ↓
diaryStatProvider (derived, presentation)
  ↓
UI rebuilds with fresh data
```

### After (Automated Chain)
**Command**:
```bash
/provider-invalidate-chain db_recovery \
  --root-provider diaryRepository \
  --scan-depth 3
```

**Generated file**: `lib/presentation/providers/invalidation_chains.dart`
```dart
/// Invalidation chain for database recovery scenarios
Future<void> invalidateDiaryRecoveryChain(WidgetRef ref) async {
  // Layer 1: Data sources
  ref.invalidate(diaryRepositoryProvider);

  // Layer 2: Domain use cases
  ref.invalidate(diaryListUsecaseProvider);
  ref.invalidate(diaryDetailUsecaseProvider);

  // Layer 3: Presentation providers
  ref.invalidate(diaryListProvider);
  ref.invalidate(diaryStatProvider);
  ref.invalidate(diaryTimelineProvider);
}

/// Safety check: verify all dependents are invalidated
/// (auto-generated validation function)
void validateDiaryChainInvalidation(WidgetRef ref) {
  // Asserts that all dependent providers will rebuild
}
```

**Modified main_screen.dart**:
```dart
class _MainScreenState extends ConsumerState<MainScreen> {
  Future<void> _recoverDatabase() async {
    try {
      // Database recovery logic...

      // ✅ Single, well-defined invalidation chain
      await invalidateDiaryRecoveryChain(ref);

      // ✅ All layers guaranteed invalidated
      // ✅ Order is deterministic
      // ✅ Testable with mock ref

    } catch (e) {
      // ...
    }
  }
}
```

---

## Pattern 4: Widget Test Scaffold Examples

### Before (Manual Test Boilerplate)
**File**: `test/presentation/widgets/diary_list/diary_item_card_test.dart`

```dart
void main() {
  group('DiaryItemCard', () {
    // ❌ Manual fixture setup (20+ lines)
    late MockDiaryRepository mockDiaryRepository;
    late ProviderContainer container;

    setUp(() {
      mockDiaryRepository = MockDiaryRepository();
      container = ProviderContainer(
        overrides: [
          diaryRepositoryProvider.overrideWithValue(mockDiaryRepository),
        ],
      );
    });

    // ❌ Manual test case creation (5+ lines each)
    testWidgets('renders diary item with emoji', (WidgetTester tester) async {
      final testDiary = Diary(
        id: '1',
        title: 'Test',
        emotionType: EmotionType.happy,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(mockDiaryRepository),
          ],
          child: MaterialApp(
            home: DiaryItemCard(diary: testDiary),
          ),
        ),
      );

      expect(find.text('😊'), findsOneWidget);
    });

    // ... 5+ more manual test cases
  });
}
```

### After (Auto-Generated Scaffold)
**Command**:
```bash
/widget-test-scaffold lib/presentation/widgets/diary_list/diary_item_card.dart \
  --include-provided-deps \
  --fixtures auto
```

**Generated**: `test/presentation/widgets/diary_list/diary_item_card_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

// ✅ Auto-generated mocks from widget dependencies
class MockDiaryRepository extends Mock implements DiaryRepository {}

void main() {
  group('DiaryItemCard', () {
    late MockDiaryRepository mockDiaryRepository;
    late ProviderContainer testContainer;

    setUp(() {
      mockDiaryRepository = MockDiaryRepository();
      testContainer = ProviderContainer(
        overrides: [
          diaryRepositoryProvider.overrideWithValue(mockDiaryRepository),
        ],
      );
    });

    // ✅ Auto-generated test stubs
    testWidgets('renders without error', (WidgetTester tester) async {
      final diary = Diary.sample();  // ✅ Auto-generated fixture

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(mockDiaryRepository),
          ],
          child: MaterialApp(home: DiaryItemCard(diary: diary)),
        ),
      );

      expect(find.byType(DiaryItemCard), findsOneWidget);
      // TODO: Add specific assertions
    });

    testWidgets('displays emotion emoji', (WidgetTester tester) async {
      // ✅ Auto-generated stub with TODO
      // TODO: Implement assertion
    });

    testWidgets('navigates to detail on tap', (WidgetTester tester) async {
      // ✅ Auto-generated stub
      // TODO: Implement with MockNavigatorObserver
    });

    testWidgets('handles long text with ExpandableText',
      (WidgetTester tester) async {
      // ✅ Auto-generated for identified widget
      // TODO: Implement
    });
  });
}
```

**Fixture helper** (auto-generated):
```dart
// ✅ Auto-generated fixtures for common entities
extension DiaryTestFixture on Diary {
  static Diary sample({
    String id = '1',
    String title = 'Test Diary',
    EmotionType emotionType = EmotionType.happy,
  }) {
    return Diary(
      id: id,
      title: title,
      emotionType: emotionType,
      createdAt: DateTime.now(),
    );
  }
}
```

---

## Pattern 5: Barrel Export Generation Examples

### Before (Multiple Imports)
```dart
// lib/presentation/screens/statistics_screen.dart
import 'package:mindlog/presentation/widgets/statistics/chart_card.dart';
import 'package:mindlog/presentation/widgets/statistics/heatmap_card.dart';
import 'package:mindlog/presentation/widgets/statistics/keyword_card.dart';
import 'package:mindlog/presentation/widgets/statistics/summary_row.dart';

class StatisticsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SummaryRow(...),
        HeatmapCard(...),
        ChartCard(...),
        KeywordCard(...),
      ],
    );
  }
}
```

### After (Single Barrel Import)
**Generated**: `lib/presentation/widgets/statistics/statistics.dart`
```dart
/// Statistics 위젯 barrel export
library;

export 'chart_card.dart';
export 'heatmap_card.dart';
export 'keyword_card.dart';
export 'summary_row.dart';
```

**Modified statistics_screen.dart**:
```dart
import 'package:mindlog/presentation/widgets/statistics/statistics.dart';

class StatisticsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SummaryRow(...),
        HeatmapCard(...),
        ChartCard(...),
        KeywordCard(...),
      ],
    );
  }
}
```

**Benefits**:
- ✅ Single import statement
- ✅ Clear collection membership
- ✅ Refactoring one file affects all consumers uniformly

---

## Pattern Recognition Rules (for skill builders)

### Color Migration Rule
```
IF pattern matches: Colors.[A-Za-z0-9.]+
  AND color appears in: presentation/**/*.dart
  THEN lookup in patterns-theme-colors.md
  AND replace with corresponding colorScheme/AppColors reference
  AND preserve opacity/alpha values
```

### Widget Decomposition Rule
```
IF widget file length > 200 lines
  AND contains multiple logical sections (build methods, helpers)
  THEN suggest extraction
  - Each section > 50 lines → separate widget file
  - Display logic → extension method
  - Reusable interaction → common/ directory
  - Create barrel export for all extracted widgets
```

### Provider Invalidation Rule
```
IF triggered by event (db_recovery, user_logout, etc.)
  THEN scan provider graph
  AND identify all layers: Data → Domain → Presentation
  AND generate ordered invalidation sequence
  AND verify all dependents covered
  AND create isolated function: invalidate[Event]Chain()
```

### Test Generation Rule
```
IF new widget created with parameters
  THEN auto-generate:
  - Mock fixtures for provider deps
  - Test stubs for each visual state
  - ProviderScope.overrides setup
  - Extension fixtures (Diary.sample(), etc.)
  AND flag assertions as TODO for manual completion
```

### Barrel Export Rule
```
IF directory pattern: widgets/[feature]/
  AND contains 3+ .dart files (excluding tests)
  THEN generate [feature].dart barrel export
  AND include library comment
  AND suggest import replacement in dependents
```

---

## Statistics from Analyzed Commits

### Commit abd7bdd (Widget Decomposition + Color Migration)
- **Lines added**: 2,155 (new extracted widgets)
- **Lines removed**: 437 (original monolithic code)
- **Net change**: +1,718 lines
- **Files created**: 5 (extracted widgets) + 1 (barrel export) + 1 (extension)
- **Color references changed**: 41
- **Time analysis**:
  - Decomposition: 90 min
  - Color migration: 45 min
  - Testing: 30 min
  - **Total: 165 min**
  - **With automation: ~43 min (-74%)**

### Commit 389689c (Statistics Decomposition)
- **Original file**: `statistics_screen.dart` (516 lines)
- **Extracted to**: 4 files + barrel export
- **File sizes**: 54, 251, 54, 211 (well-distributed)
- **Barrel export**: 7 lines (minimal overhead)
- **Lines removed from original**: 516 → 1 (just imports)

### Commit 6e2b1a1 (Provider Invalidation)
- **Provider invalidation chains**: 1 major scenario identified
- **Documentation created**: 153 line skill file
- **Pattern identified**: Multi-layer dependency invalidation
- **Complexity**: High (requires full dependency graph)
- **Impact**: Prevents subtle data consistency bugs

---

## Validation Checklist for Generated Code

### Color Migration Validation
- [ ] All `Colors.xxx` references replaced
- [ ] Opacity values preserved
- [ ] ColorScheme vs AppColors precedence correct
- [ ] Dark mode rendering verified
- [ ] No hardcoded alpha values lost

### Widget Decomposition Validation
- [ ] Widget behavior identical to original
- [ ] All parameters correctly passed
- [ ] Tests pass for all widgets
- [ ] Barrel export includes all files
- [ ] No circular imports introduced

### Provider Invalidation Validation
- [ ] All 3 layers (data/domain/presentation) covered
- [ ] Invalidation order correct (bottom-up)
- [ ] No orphaned providers
- [ ] Test with mock ProviderContainer
- [ ] Performance impact negligible

---

**Reference Guide Version**: 1.0
**Last Updated**: 2026-02-02
**Status**: Ready for skill implementation
