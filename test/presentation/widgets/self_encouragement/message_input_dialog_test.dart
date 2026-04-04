import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/core/theme/cheer_me_section_palette.dart';
import 'package:mindlog/presentation/widgets/self_encouragement/message_input_dialog.dart';

Widget _buildHarness({
  double textScale = 1.0,
  ThemeMode themeMode = ThemeMode.light,
  void Function(MessageInputResult?)? onResult,
  String? initialValue,
  String? initialTimeCategory,
  bool isEditing = false,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Builder(
          builder: (context) {
            final data = MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale));

            return MediaQuery(
              data: data,
              child: Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () async {
                      final result = await MessageInputDialog.show(
                        context,
                        initialValue: initialValue,
                        initialTimeCategory: initialTimeCategory,
                        isEditing: isEditing,
                      );
                      onResult?.call(result);
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    themeMode: themeMode,
    darkTheme: ThemeData.dark(useMaterial3: true),
  );
}

Future<void> _openDialog(
  WidgetTester tester, {
  required Size viewport,
  double textScale = 1.0,
  ThemeMode themeMode = ThemeMode.light,
  void Function(MessageInputResult?)? onResult,
  String? initialValue,
  String? initialTimeCategory,
  bool isEditing = false,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    _buildHarness(
      textScale: textScale,
      themeMode: themeMode,
      onResult: onResult,
      initialValue: initialValue,
      initialTimeCategory: initialTimeCategory,
      isEditing: isEditing,
    ),
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

    group('timeCategory 선택', () {
      testWidgets('기본값은 전체(all)로 선택되어야 한다', (tester) async {
        await _openDialog(tester, viewport: const Size(360, 800));

        // '전체' 칩이 selected 스타일
        final allChip = tester.widget<AnimatedContainer>(
          _timeCategoryChipByLabel('전체'),
        );
        final decoration = allChip.decoration! as BoxDecoration;
        final border = decoration.border! as Border;

        final context = tester.element(find.byType(MessageInputDialog));
        final colorScheme = Theme.of(context).colorScheme;

        expect(decoration.color, colorScheme.primaryContainer);
        expect(border.top.color, colorScheme.primary);
      });

      testWidgets('시간대 칩 탭 시 선택 상태가 변경되어야 한다', (tester) async {
        await _openDialog(tester, viewport: const Size(360, 800));

        final context = tester.element(find.byType(MessageInputDialog));
        final colorScheme = Theme.of(context).colorScheme;

        // '아침' 탭
        await tester.tap(find.text('아침'));
        await tester.pump(const Duration(milliseconds: 200));

        final morningChip = tester.widget<AnimatedContainer>(
          _timeCategoryChipByLabel('아침'),
        );
        final morningDecoration = morningChip.decoration! as BoxDecoration;
        expect(morningDecoration.color, colorScheme.primaryContainer);

        // '전체'는 unselected로 변경
        final allChip = tester.widget<AnimatedContainer>(
          _timeCategoryChipByLabel('전체'),
        );
        final allDecoration = allChip.decoration! as BoxDecoration;
        final allBorder = allDecoration.border! as Border;
        expect(allBorder.top.color, Colors.transparent);
      });

      testWidgets('모든 시간대 칩이 표시되어야 한다', (tester) async {
        await _openDialog(tester, viewport: const Size(360, 800));

        expect(find.text('전체'), findsOneWidget);
        expect(find.text('아침'), findsOneWidget);
        expect(find.text('오후'), findsOneWidget);
        expect(find.text('저녁'), findsOneWidget);
        expect(find.text('알림 시간대'), findsOneWidget);
      });

      testWidgets('다른 칩 선택 후 다시 전체로 돌아올 수 있어야 한다', (tester) async {
        await _openDialog(tester, viewport: const Size(360, 800));

        final context = tester.element(find.byType(MessageInputDialog));
        final colorScheme = Theme.of(context).colorScheme;

        // 저녁 → 전체 순서로 탭
        await tester.tap(find.text('저녁'));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.text('전체'));
        await tester.pump(const Duration(milliseconds: 200));

        final allChip = tester.widget<AnimatedContainer>(
          _timeCategoryChipByLabel('전체'),
        );
        final decoration = allChip.decoration! as BoxDecoration;
        expect(decoration.color, colorScheme.primaryContainer);
      });
    });

    group('수정 모드', () {
      testWidgets('initialTimeCategory가 복원되어야 한다', (tester) async {
        await _openDialog(
          tester,
          viewport: const Size(360, 800),
          initialValue: '기존 메시지',
          initialTimeCategory: 'evening',
          isEditing: true,
        );

        final context = tester.element(find.byType(MessageInputDialog));
        final colorScheme = Theme.of(context).colorScheme;

        // '저녁' 칩이 selected
        final eveningChip = tester.widget<AnimatedContainer>(
          _timeCategoryChipByLabel('저녁'),
        );
        final decoration = eveningChip.decoration! as BoxDecoration;
        expect(decoration.color, colorScheme.primaryContainer);

        // '전체'는 unselected
        final allChip = tester.widget<AnimatedContainer>(
          _timeCategoryChipByLabel('전체'),
        );
        final allDecoration = allChip.decoration! as BoxDecoration;
        final allBorder = allDecoration.border! as Border;
        expect(allBorder.top.color, Colors.transparent);
      });

      testWidgets('수정 모드에서 타이틀이 메시지 수정이어야 한다', (tester) async {
        await _openDialog(
          tester,
          viewport: const Size(360, 800),
          initialValue: '기존 메시지',
          isEditing: true,
        );

        expect(find.text('메시지 수정'), findsOneWidget);
      });

      testWidgets('수정 모드에서 버튼 텍스트가 수정이어야 한다', (tester) async {
        await _openDialog(
          tester,
          viewport: const Size(360, 800),
          initialValue: '기존 메시지',
          isEditing: true,
        );

        expect(find.widgetWithText(FilledButton, '수정'), findsOneWidget);
      });

      testWidgets('수정 모드에서 프리셋 템플릿이 숨겨져야 한다', (tester) async {
        await _openDialog(
          tester,
          viewport: const Size(360, 800),
          initialValue: '기존 메시지',
          isEditing: true,
        );

        // 프리셋 카테고리 칩이 없어야 함
        expect(find.text('아침 다짐'), findsNothing);
        expect(find.text('자기 위로'), findsNothing);
      });
    });

    group('반환값 (MessageInputResult)', () {
      testWidgets('저장 시 content와 null timeCategory 반환해야 한다', (
        tester,
      ) async {
        MessageInputResult? capturedResult;

        await _openDialog(
          tester,
          viewport: const Size(360, 800),
          onResult: (result) => capturedResult = result,
        );

        await tester.enterText(find.byType(TextField), '오늘도 화이팅');
        await tester.pump();

        await tester.tap(find.widgetWithText(FilledButton, '저장'));
        await tester.pumpAndSettle();

        expect(capturedResult, isNotNull);
        expect(capturedResult!.content, '오늘도 화이팅');
        expect(capturedResult!.timeCategory, isNull); // 전체 = null
      });

      testWidgets('아침 선택 후 저장 시 morning timeCategory 반환해야 한다', (
        tester,
      ) async {
        MessageInputResult? capturedResult;

        await _openDialog(
          tester,
          viewport: const Size(360, 800),
          onResult: (result) => capturedResult = result,
        );

        await tester.enterText(find.byType(TextField), '좋은 아침');
        await tester.pump();

        await tester.tap(find.text('아침'));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.widgetWithText(FilledButton, '저장'));
        await tester.pumpAndSettle();

        expect(capturedResult, isNotNull);
        expect(capturedResult!.content, '좋은 아침');
        expect(capturedResult!.timeCategory, 'morning');
      });

      testWidgets('오후 선택 후 저장 시 afternoon timeCategory 반환해야 한다', (
        tester,
      ) async {
        MessageInputResult? capturedResult;

        await _openDialog(
          tester,
          viewport: const Size(360, 800),
          onResult: (result) => capturedResult = result,
        );

        await tester.enterText(find.byType(TextField), '오후도 힘내자');
        await tester.pump();

        await tester.tap(find.text('오후'));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.widgetWithText(FilledButton, '저장'));
        await tester.pumpAndSettle();

        expect(capturedResult, isNotNull);
        expect(capturedResult!.content, '오후도 힘내자');
        expect(capturedResult!.timeCategory, 'afternoon');
      });

      testWidgets('저녁 선택 후 저장 시 evening timeCategory 반환해야 한다', (
        tester,
      ) async {
        MessageInputResult? capturedResult;

        await _openDialog(
          tester,
          viewport: const Size(360, 800),
          onResult: (result) => capturedResult = result,
        );

        await tester.enterText(find.byType(TextField), '오늘 하루 수고했어');
        await tester.pump();

        await tester.tap(find.text('저녁'));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.widgetWithText(FilledButton, '저장'));
        await tester.pumpAndSettle();

        expect(capturedResult, isNotNull);
        expect(capturedResult!.content, '오늘 하루 수고했어');
        expect(capturedResult!.timeCategory, 'evening');
      });

      testWidgets('취소 시 null을 반환해야 한다', (tester) async {
        MessageInputResult? capturedResult;
        var resultCalled = false;

        await _openDialog(
          tester,
          viewport: const Size(360, 800),
          onResult: (result) {
            capturedResult = result;
            resultCalled = true;
          },
        );

        await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
        await tester.pumpAndSettle();

        expect(resultCalled, isTrue);
        expect(capturedResult, isNull);
      });

      testWidgets('수정 모드에서 시간대 변경 후 저장 시 새 값 반환해야 한다', (
        tester,
      ) async {
        MessageInputResult? capturedResult;

        await _openDialog(
          tester,
          viewport: const Size(360, 800),
          initialValue: '기존 메시지',
          initialTimeCategory: 'morning',
          isEditing: true,
          onResult: (result) => capturedResult = result,
        );

        // 시간대를 아침 → 오후로 변경
        await tester.tap(find.text('오후'));
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.widgetWithText(FilledButton, '수정'));
        await tester.pumpAndSettle();

        expect(capturedResult, isNotNull);
        expect(capturedResult!.content, '기존 메시지');
        expect(capturedResult!.timeCategory, 'afternoon');
      });

      testWidgets('content 앞뒤 공백이 trim되어 반환되어야 한다', (tester) async {
        MessageInputResult? capturedResult;

        await _openDialog(
          tester,
          viewport: const Size(360, 800),
          onResult: (result) => capturedResult = result,
        );

        await tester.enterText(find.byType(TextField), '  공백 포함  ');
        await tester.pump();

        await tester.tap(find.widgetWithText(FilledButton, '저장'));
        await tester.pumpAndSettle();

        expect(capturedResult!.content, '공백 포함');
      });

      testWidgets('빈 입력 시 저장 버튼이 비활성화되어야 한다', (tester) async {
        await _openDialog(tester, viewport: const Size(360, 800));

        final saveButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, '저장'),
        );
        expect(saveButton.onPressed, isNull);
      });

      testWidgets('공백만 입력 시 저장 버튼이 비활성화되어야 한다', (tester) async {
        await _openDialog(tester, viewport: const Size(360, 800));

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();

        final saveButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, '저장'),
        );
        expect(saveButton.onPressed, isNull);
      });
    });
  });
}

/// 시간대 카테고리 칩의 AnimatedContainer 탐색
Finder _timeCategoryChipByLabel(String label) {
  // 시간대 칩은 Row > Expanded > Padding > GestureDetector > AnimatedContainer 구조
  return find
      .ancestor(of: find.text(label), matching: find.byType(AnimatedContainer))
      .first;
}
