import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindlog/core/theme/app_theme.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
import 'package:mindlog/presentation/providers/self_encouragement_controller.dart';
import 'package:mindlog/presentation/providers/user_name_controller.dart';
import 'package:mindlog/presentation/screens/self_encouragement_screen.dart';
import 'package:mindlog/presentation/screens/secret_pin_setup_screen.dart';
import 'package:mindlog/presentation/screens/secret_diary_unlock_screen.dart';
import 'package:mindlog/presentation/widgets/fullscreen_image_viewer.dart';
import 'package:mindlog/presentation/widgets/self_encouragement/message_input_dialog.dart';

// Device-only harness: provider data is isolated; window/IME/system-bar metrics
// come from Android. Does not initialize Firebase or change persisted app data.
class _Messages extends SelfEncouragementController {
  _Messages(this.count);
  final int count;
  List<SelfEncouragementMessage> get items => state.requireValue;
  final edits = <String>[];
  final deletes = <String>[];
  final moves = <(int, int)>[];
  @override
  Future<List<SelfEncouragementMessage>> build() async => List.generate(
    count,
    (i) => SelfEncouragementMessage(
      id: '$i',
      content: '응원 $i',
      createdAt: DateTime(2026, 9, 8),
      displayOrder: i,
    ),
  );
  @override
  Future<bool> addMessage(String content, {String? timeCategory}) async {
    state = AsyncData([
      ...state.requireValue,
      SelfEncouragementMessage(
        id: 'new',
        content: content,
        createdAt: DateTime(2026, 9, 8),
        displayOrder: state.requireValue.length,
      ),
    ]);
    return true;
  }

  @override
  Future<bool> updateMessage(
    String id,
    String content, {
    String? timeCategory,
  }) async {
    edits.add(id);
    state = AsyncData([
      for (final m in state.requireValue)
        m.id == id ? m.copyWith(content: content) : m,
    ]);
    return true;
  }

  @override
  Future<void> deleteMessage(String id) async {
    deletes.add(id);
    final remaining = state.requireValue.where((m) => m.id != id).toList();
    state = AsyncData([
      for (var i = 0; i < remaining.length; i++)
        remaining[i].copyWith(displayOrder: i),
    ]);
  }

  @override
  Future<void> reorder(int oldIndex, int newIndex) async {
    moves.add((oldIndex, newIndex));
    final items = [...state.requireValue];
    items.insert(newIndex, items.removeAt(oldIndex));
    state = AsyncData([
      for (var i = 0; i < items.length; i++) items[i].copyWith(displayOrder: i),
    ]);
  }
}

class _Name extends UserNameController {
  @override
  Future<String?> build() async => null;
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void _metrics(String label, WidgetTester tester) {
  final view = tester.view;
  debugPrint(
    'ANDROID_UI $label dpr=${view.devicePixelRatio} size=${view.physicalSize} padding=${view.padding} viewPadding=${view.viewPadding} viewInsets=${view.viewInsets}',
  );
}

Future<GoRouter> _host(
  WidgetTester tester,
  Widget screen, {
  int count = 9,
}) async {
  SharedPreferences.setMockInitialValues({
    'self_encouragement_hint_shown': true,
  });
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => screen)],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        selfEncouragementProvider.overrideWith(() => _Messages(count)),
        cheerMePreviewProvider.overrideWith((ref) async => null),
        userNameProvider.overrideWith(() => _Name()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    ),
  );
  await _frames(tester);
  return router;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android 실측 인셋으로 목록·시트·PIN·사진 복귀를 검증한다', (tester) async {
    final routers = <GoRouter>[];
    for (final count in [9, 10]) {
      routers.add(
        await _host(tester, const SelfEncouragementScreen(), count: count),
      );
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(ReorderableListView),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      for (var i = 0; i < 4; i++) {
        position.jumpTo(position.maxScrollExtent);
        await _frames(tester);
      }
      final card = tester.getRect(find.byKey(ValueKey('${count - 1}')));
      final bottom =
          (tester.view.physicalSize.height - tester.view.padding.bottom) /
          tester.view.devicePixelRatio;
      debugPrint('ANDROID_UI list$count card=$card safeBottom=$bottom');
      expect(card.bottom, lessThanOrEqualTo(bottom - 16));
      if (count == 9) {
        expect(
          card.bottom,
          lessThanOrEqualTo(
            tester.getRect(find.byType(FloatingActionButton)).top - 8,
          ),
        );
        await tester.tap(find.byType(FloatingActionButton));
        await _frames(tester);
        _metrics('sheet-open', tester);
        final dialog = tester.element(find.byType(MessageInputDialog));
        final mq = MediaQuery.of(dialog);
        final scroll = find
            .descendant(
              of: find.byType(MessageInputDialog),
              matching: find.byType(SingleChildScrollView),
            )
            .first;
        expect(
          tester.getRect(scroll).top,
          greaterThanOrEqualTo(
            tester.view.viewPadding.top / tester.view.devicePixelRatio,
          ),
        );
        final cancel = find.widgetWithText(OutlinedButton, '취소');
        final keyboardTop = mq.size.height - mq.viewInsets.bottom;
        expect(tester.getRect(cancel).bottom, lessThanOrEqualTo(keyboardTop));
        debugPrint(
          'ANDROID_UI sheet cancel=${tester.getRect(cancel)} keyboardTop=$keyboardTop',
        );
        await tester.tap(cancel);
        await _frames(tester);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester);
    }
    for (final screen in [
      const SecretPinSetupScreen(),
      const SecretDiaryUnlockScreen(),
    ]) {
      routers.add(await _host(tester, screen));
      _metrics('PIN ${screen.runtimeType}', tester);
      final scroll = find.byType(SingleChildScrollView).first;
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first,
          )
          .position;
      debugPrint(
        'ANDROID_UI PIN ${screen.runtimeType} maxScroll=${position.maxScrollExtent}',
      );
      final zero = find.text('0');
      await tester.ensureVisible(zero);
      await tester.tap(zero);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await _frames(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester);
    }
    final directory = await Directory.systemTemp.createTemp(
      'mindlog-system-ui-',
    );
    final photo = File('${directory.path}/pixel.png');
    await photo.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      ),
    );
    routers.add(
      await _host(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => FullscreenImageViewer.show(
                  context,
                  imagePaths: [photo.path],
                ),
                child: const Text('Photo'),
              ),
            ),
          ),
        ),
      ),
    );
    // Let Android finish the keyboard close policy window before observation.
    await tester.pump(const Duration(seconds: 2));
    _metrics('viewer-before', tester);
    final before = tester.view.padding;
    for (final exit in ['close', 'back', 'drag']) {
      await tester.tap(find.text('Photo'));
      await _frames(tester);
      _metrics('viewer-open-$exit', tester);
      final close = find.byIcon(Icons.close);
      expect(
        tester.getRect(close).top,
        greaterThanOrEqualTo(
          tester.view.padding.top / tester.view.devicePixelRatio,
        ),
      );
      if (exit == 'close') {
        await tester.tap(close);
      }
      if (exit == 'back') {
        await tester.binding.handlePopRoute();
      }
      if (exit == 'drag') {
        await tester.fling(find.byType(PageView), const Offset(0, 300), 1000);
      }
      await _frames(tester);
      _metrics('viewer-return-$exit', tester);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.byType(FullscreenImageViewer), findsNothing);
      expect(tester.view.padding.top, before.top);
      expect(tester.view.padding.bottom, before.bottom);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    for (final router in routers) {
      router.dispose();
    }
    await directory.delete(recursive: true);
  });
}
