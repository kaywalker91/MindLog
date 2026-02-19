import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mindlog/core/theme/app_colors.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/presentation/widgets/diary_list/diary_item_card.dart';

import '../../../fixtures/diary_fixtures.dart';

Widget _buildHarness({required Diary diary, required ThemeMode themeMode}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: DiaryItemCard(diary: diary),
        ),
      ),
    ),
  );
}

BoxDecoration _cardDecoration(WidgetTester tester) {
  final finder = find.byWidgetPredicate((widget) {
    if (widget is! Container || widget.decoration is! BoxDecoration) {
      return false;
    }

    final decoration = widget.decoration! as BoxDecoration;
    return decoration.borderRadius == BorderRadius.circular(16) &&
        decoration.boxShadow != null &&
        decoration.color != null;
  });

  expect(finder, findsWidgets);
  final container = tester.widget<Container>(finder.first);
  return container.decoration! as BoxDecoration;
}

BoxDecoration _keywordChipDecoration(WidgetTester tester, String label) {
  final finder = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((widget) {
      if (widget is! Container || widget.decoration is! BoxDecoration) {
        return false;
      }
      final decoration = widget.decoration! as BoxDecoration;
      return decoration.borderRadius == BorderRadius.circular(4);
    }),
  );

  expect(finder, findsWidgets);
  final container = tester.widget<Container>(finder.first);
  return container.decoration! as BoxDecoration;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
    Animate.restartOnHotReload = false;
  });

  group('DiaryItemCard dark mode separation', () {
    testWidgets(
      'dark mode uses container surface, border and semantic inner colors',
      (tester) async {
        final diary = DiaryFixtures.analyzed(
          keywords: ['자제', '생활습관'],
          isPinned: false,
        );

        await tester.pumpWidget(
          _buildHarness(diary: diary, themeMode: ThemeMode.dark),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DiaryItemCard));
        final colorScheme = Theme.of(context).colorScheme;

        final cardDecoration = _cardDecoration(tester);
        final cardBorder = cardDecoration.border! as Border;
        expect(cardDecoration.color, colorScheme.surfaceContainerLow);
        expect(
          cardBorder.top.color,
          colorScheme.outlineVariant.withValues(alpha: 0.60),
        );
        expect(cardBorder.top.width, 1);
        expect(
          cardDecoration.boxShadow!.first.color,
          colorScheme.shadow.withValues(alpha: 0.12),
        );

        final chevron = tester.widget<Icon>(find.byIcon(Icons.chevron_right));
        expect(
          chevron.color,
          colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
        );

        final pinIcon = tester.widget<Icon>(
          find.byIcon(Icons.push_pin_outlined),
        );
        expect(
          pinIcon.color,
          colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
        );

        final keywordText = tester.widget<Text>(find.text('#자제'));
        expect(keywordText.style?.color, colorScheme.onSurfaceVariant);

        final keywordChip = _keywordChipDecoration(tester, '#자제');
        expect(keywordChip.color, colorScheme.surfaceContainerHighest);
      },
    );

    testWidgets(
      'light mode keeps surface tone and legacy keyword chip background',
      (tester) async {
        final diary = DiaryFixtures.analyzed(
          keywords: ['자제', '생활습관'],
          isPinned: true,
        );

        await tester.pumpWidget(
          _buildHarness(diary: diary, themeMode: ThemeMode.light),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(DiaryItemCard));
        final colorScheme = Theme.of(context).colorScheme;

        final cardDecoration = _cardDecoration(tester);
        final cardBorder = cardDecoration.border! as Border;
        expect(cardDecoration.color, colorScheme.surface);
        expect(cardBorder.top, BorderSide.none);
        expect(
          cardDecoration.boxShadow!.first.color,
          colorScheme.shadow.withValues(alpha: 0.05),
        );

        final pinIcon = tester.widget<Icon>(find.byIcon(Icons.push_pin));
        expect(pinIcon.color, colorScheme.primary);

        final keywordChip = _keywordChipDecoration(tester, '#자제');
        expect(keywordChip.color, AppColors.textHint.withValues(alpha: 0.1));
      },
    );

    testWidgets('renders normally when diary has no keywords', (tester) async {
      final diary = DiaryFixtures.analyzed(keywords: const []);

      await tester.pumpWidget(
        _buildHarness(diary: diary, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DiaryItemCard), findsOneWidget);
      expect(find.textContaining('#'), findsNothing);
    });
  });

  group('DiaryItemCard long press menu', () {
    testWidgets('isSecret=false 일기 롱프레스 시 "비밀일기로 설정" 메뉴 표시', (tester) async {
      final diary = DiaryFixtures.analyzed(isPinned: false);

      await tester.pumpWidget(
        _buildHarness(diary: diary, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(DiaryItemCard));
      await tester.pumpAndSettle();

      expect(find.text('비밀일기로 설정'), findsOneWidget);
      expect(find.text('상단 고정'), findsOneWidget);
      expect(find.text('비밀 해제'), findsNothing);
    });

    testWidgets('isSecret=true 일기 롱프레스 시 "비밀 해제" 메뉴 표시 + 고정 메뉴 숨김', (
      tester,
    ) async {
      final diary = DiaryFixtures.analyzed().copyWith(isSecret: true);

      await tester.pumpWidget(
        _buildHarness(diary: diary, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(DiaryItemCard));
      await tester.pumpAndSettle();

      expect(find.text('비밀 해제'), findsOneWidget);
      expect(find.text('비밀일기로 설정'), findsNothing);
      expect(find.text('상단 고정'), findsNothing);
      expect(find.text('고정 해제'), findsNothing);
    });
  });
}
