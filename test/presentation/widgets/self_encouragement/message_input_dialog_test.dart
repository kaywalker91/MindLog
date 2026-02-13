import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/core/theme/cheer_me_section_palette.dart';
import 'package:mindlog/presentation/widgets/self_encouragement/message_input_dialog.dart';

Widget _buildHarness({
  double textScale = 1.0,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    themeMode: themeMode,
    darkTheme: ThemeData.dark(useMaterial3: true),
    home: Builder(
      builder: (context) {
        final data = MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale));

        return MediaQuery(
          data: data,
          child: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => MessageInputDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _openDialog(
  WidgetTester tester, {
  required Size viewport,
  double textScale = 1.0,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    _buildHarness(textScale: textScale, themeMode: themeMode),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Finder _chipContainerByLabel(String label) {
  return find
      .ancestor(of: find.text(label), matching: find.byType(AnimatedContainer))
      .first;
}

Finder _suggestionContainerByText(String suggestion) {
  return find
      .ancestor(
        of: find.text('"$suggestion"'),
        matching: find.byType(AnimatedContainer),
      )
      .first;
}

void main() {
  group('MessageInputDialog', () {
    testWidgets('renders without overflow at 320x800', (tester) async {
      await _openDialog(tester, viewport: const Size(320, 800));

      expect(tester.takeException(), isNull);
      expect(find.byType(MessageInputDialog), findsOneWidget);
    });

    testWidgets('renders without overflow at 360x800', (tester) async {
      await _openDialog(tester, viewport: const Size(360, 800));

      expect(tester.takeException(), isNull);
      expect(find.byType(MessageInputDialog), findsOneWidget);
    });

    testWidgets('renders without overflow at 412x900', (tester) async {
      await _openDialog(tester, viewport: const Size(412, 900));

      expect(tester.takeException(), isNull);
      expect(find.byType(MessageInputDialog), findsOneWidget);
    });

    testWidgets('applies healing color scheme mapping in modal scope', (
      tester,
    ) async {
      await _openDialog(tester, viewport: const Size(360, 800));

      final scheme = AppTheme.healingColorScheme();
      final context = tester.element(find.byType(MessageInputDialog));
      final appliedScheme = Theme.of(context).colorScheme;

      expect(appliedScheme.primary, scheme.primary);
      expect(appliedScheme.secondaryContainer, scheme.secondaryContainer);
      expect(appliedScheme.outline, scheme.outline);
    });

    testWidgets('styles cancel/save buttons with required contrast rules', (
      tester,
    ) async {
      await _openDialog(tester, viewport: const Size(360, 800));

      final scheme = AppTheme.healingColorScheme();
      final cancelButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, '취소'),
      );
      final saveButtonFinder = find.widgetWithText(FilledButton, '저장');
      final saveButton = tester.widget<FilledButton>(saveButtonFinder);

      expect(cancelButton.style, isNotNull);
      expect(cancelButton.style!.backgroundColor?.resolve({}), scheme.surface);
      expect(cancelButton.style!.foregroundColor?.resolve({}), scheme.primary);
      expect(cancelButton.style!.side?.resolve({})?.color, scheme.outline);

      expect(saveButton.onPressed, isNull);
      expect(saveButton.style, isNotNull);
      expect(
        saveButton.style!.backgroundColor?.resolve({WidgetState.disabled}),
        scheme.surfaceContainerHighest,
      );
      expect(
        saveButton.style!.foregroundColor?.resolve({WidgetState.disabled}),
        scheme.onSurfaceVariant.withValues(alpha: 0.6),
      );

      await tester.enterText(find.byType(TextField), '오늘도 충분히 잘하고 있어');
      await tester.pump();

      final enabledSaveButton = tester.widget<FilledButton>(saveButtonFinder);
      expect(enabledSaveButton.onPressed, isNotNull);
      expect(
        enabledSaveButton.style!.backgroundColor?.resolve({}),
        scheme.primary,
      );
      expect(
        enabledSaveButton.style!.foregroundColor?.resolve({}),
        scheme.onPrimary,
      );
    });

    testWidgets('uses clear selected/unselected chip colors', (tester) async {
      await _openDialog(tester, viewport: const Size(360, 800));

      final palette = CheerMeSectionPalette.light();
      final selectedChip = tester.widget<AnimatedContainer>(
        _chipContainerByLabel('아침 다짐'),
      );
      final unselectedChip = tester.widget<AnimatedContainer>(
        _chipContainerByLabel('자기 위로'),
      );

      final selectedDecoration = selectedChip.decoration! as BoxDecoration;
      final unselectedDecoration = unselectedChip.decoration! as BoxDecoration;
      final selectedBorder = selectedDecoration.border! as Border;
      final unselectedBorder = unselectedDecoration.border! as Border;

      expect(selectedDecoration.color, palette.selectedChipBackground);
      expect(selectedBorder.top.color, palette.selectedChipBorder);
      expect(selectedBorder.top.width, 1);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.wb_sunny_outlined)).color,
        palette.selectedChipText,
      );
      expect(selectedDecoration.boxShadow, isNotNull);
      expect(selectedDecoration.boxShadow!.length, 1);
      expect(selectedDecoration.boxShadow!.first.blurRadius, 6);

      expect(unselectedDecoration.color, palette.unselectedChipBackground);
      expect(unselectedBorder.top.color, Colors.transparent);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.favorite_outline)).color,
        palette.unselectedChipText,
      );
      expect(unselectedDecoration.boxShadow, isNull);
    });

    testWidgets('uses clear selected/unselected suggestion colors', (
      tester,
    ) async {
      await _openDialog(tester, viewport: const Size(360, 800));

      final palette = CheerMeSectionPalette.light();
      const selectedText = '오늘 하루도 내 속도로 괜찮아';
      const unselectedText = '작은 것부터 시작해보자';

      await tester.tap(find.text('"$selectedText"'));
      await tester.pump();

      final selectedSuggestion = tester.widget<AnimatedContainer>(
        _suggestionContainerByText(selectedText),
      );
      final unselectedSuggestion = tester.widget<AnimatedContainer>(
        _suggestionContainerByText(unselectedText),
      );
      final selectedDecoration =
          selectedSuggestion.decoration! as BoxDecoration;
      final unselectedDecoration =
          unselectedSuggestion.decoration! as BoxDecoration;
      final selectedBorder = selectedDecoration.border! as Border;
      final unselectedBorder = unselectedDecoration.border! as Border;

      expect(selectedDecoration.color, palette.selectedSuggestionBackground);
      expect(selectedBorder.top.color, palette.selectedSuggestionBorder);
      expect(selectedDecoration.boxShadow, isNotNull);
      expect(selectedDecoration.boxShadow!.first.blurRadius, 6);

      expect(
        unselectedDecoration.color,
        palette.unselectedSuggestionBackground,
      );
      expect(unselectedBorder.top.color, Colors.transparent);
      expect(unselectedDecoration.boxShadow, isNull);
    });

    testWidgets('uses footer hint color from cheer-me section palette', (
      tester,
    ) async {
      await _openDialog(tester, viewport: const Size(360, 800));

      final palette = CheerMeSectionPalette.light();
      final footerText = tester.widget<Text>(
        find.textContaining('최대 10개까지 등록 가능'),
      );
      expect(footerText.style?.color, palette.footerHintText);
    });

    testWidgets('uses dark fallback palette in dark mode', (tester) async {
      await _openDialog(
        tester,
        viewport: const Size(360, 800),
        themeMode: ThemeMode.dark,
      );

      final context = tester.element(find.byType(MessageInputDialog));
      final darkPalette = CheerMeSectionPalette.darkFallback(
        Theme.of(context).colorScheme,
      );
      final selectedChip = tester.widget<AnimatedContainer>(
        _chipContainerByLabel('아침 다짐'),
      );
      final selectedDecoration = selectedChip.decoration! as BoxDecoration;
      final selectedBorder = selectedDecoration.border! as Border;

      expect(selectedDecoration.color, darkPalette.selectedChipBackground);
      expect(selectedBorder.top.color, darkPalette.selectedChipBorder);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.wb_sunny_outlined)).color,
        darkPalette.selectedChipText,
      );
    });

    testWidgets('remains readable at 1.3x text scale', (tester) async {
      await _openDialog(tester, viewport: const Size(360, 800), textScale: 1.3);

      expect(tester.takeException(), isNull);
      expect(find.text('응원 메시지 작성'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);
      expect(find.text('아침 다짐'), findsOneWidget);
    });
  });
}
