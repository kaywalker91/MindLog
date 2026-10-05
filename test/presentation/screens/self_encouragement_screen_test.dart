import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
import 'package:mindlog/presentation/providers/self_encouragement_controller.dart';
import 'package:mindlog/presentation/providers/user_name_controller.dart';
import 'package:mindlog/presentation/screens/self_encouragement_screen.dart';
import 'package:mindlog/presentation/widgets/self_encouragement/message_card.dart';

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

Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<_Messages> _open(
  WidgetTester tester,
  int count,
  double inset, {
  double scale = 1,
  double width = 412,
  double height = 915,
  double left = 0,
  bool pushed = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'self_encouragement_hint_shown': true,
  });
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(left: left, top: 32, bottom: inset);
  tester.view.viewPadding = FakeViewPadding(left: left, top: 32, bottom: inset);
  addTearDown(tester.view.reset);
  final messages = _Messages(count);
  // pushed: mirror Settings -> Cheer Me, leaving another root Scaffold mounted.
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => pushed
            ? const Scaffold(body: Text('base'))
            : const SelfEncouragementScreen(),
      ),
      GoRoute(
        path: '/cheer',
        builder: (_, _) => const SelfEncouragementScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        selfEncouragementProvider.overrideWith(() => messages),
        cheerMePreviewProvider.overrideWith((ref) async => null),
        userNameProvider.overrideWith(() => _Name()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await _pump(tester);
  if (pushed) {
    unawaited(router.push('/cheer'));
    await _pump(tester);
  }
  return messages;
}

class _Name extends UserNameController {
  @override
  Future<String?> build() async => null;
}

Future<void> _bottom(WidgetTester tester) async {
  final scroll = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byType(ReorderableListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  // Lazy items refine the extent as they become visible.
  for (var i = 0; i < 4; i++) {
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  for (final inset in [0.0, 24.0, 48.0]) {
    for (final count in [9, 10]) {
      testWidgets('$count 개 마지막 카드가 시스템 바와 FAB를 피해야 한다 ($inset)', (
        tester,
      ) async {
        await _open(tester, count, inset);
        await _bottom(tester);
        final rect = tester.getRect(find.byKey(ValueKey('${count - 1}')));
        expect(rect.bottom, lessThanOrEqualTo(915 - inset - 16));
        if (count == 9) {
          final fab = tester.getRect(find.byType(FloatingActionButton));
          expect(rect.bottom, lessThanOrEqualTo(fab.top - 8));
        } else {
          expect(find.byType(FloatingActionButton), findsNothing);
          expect(rect.bottom, closeTo(915 - inset - 16, 0.5));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('마지막 카드 수정 스와이프와 저장을 실행해야 한다', (tester) async {
    final messages = await _open(tester, 9, 48);
    await _bottom(tester);
    final target = find.byKey(const ValueKey('dismissible_8'));
    final start = tester.getCenter(target) + const Offset(70, 0);
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(start + const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(start + const Offset(300, 0));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await _pump(tester);
    await _pump(tester);
    expect(find.text('메시지 수정'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '수정한 응원');
    await tester.tap(find.widgetWithText(FilledButton, '수정'));
    await _pump(tester);
    expect(messages.edits, ['8']);
    await _bottom(tester);
    expect(find.byType(SnackBar), findsOneWidget);
    final rect = tester.getRect(find.byKey(const ValueKey('8')));
    expect(
      rect.bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(SnackBar)).top - 8),
    );
    expect(
      rect.bottom,
      lessThanOrEqualTo(
        tester.getRect(find.byType(FloatingActionButton)).top - 8,
      ),
    );
  });
  testWidgets('마지막 카드 핸들로 재정렬해야 한다', (tester) async {
    final messages = await _open(tester, 9, 48);
    await _bottom(tester);
    final handle = find
        .descendant(
          of: find.byKey(const ValueKey('8')),
          matching: find.byType(ReorderableDragStartListener),
        )
        .first;
    final start = tester.getCenter(handle);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(start - const Offset(0, 170));
    await _pump(tester);
    await gesture.up();
    await _pump(tester);
    expect(messages.moves, isNotEmpty);
    expect(messages.moves.single.$1, 8);
    expect(messages.moves.single.$2, lessThan(8));
  });

  testWidgets('9→10→9 추가와 마지막 카드 삭제 중에도 조작 영역을 확보해야 한다', (tester) async {
    final messages = await _open(tester, 9, 48);
    await tester.tap(find.byType(FloatingActionButton));
    await _pump(tester);
    await tester.enterText(find.byType(TextField), '열 번째 응원');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await _pump(tester);
    expect(messages.items, hasLength(10));
    expect(find.byType(FloatingActionButton), findsNothing);
    await _bottom(tester);
    expect(
      tester.getRect(find.byKey(const ValueKey('new'))).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(SnackBar)).top - 8),
    );
    final target = find.byKey(const ValueKey('dismissible_new'));
    await tester.drag(target, const Offset(-350, 0));
    await _pump(tester);
    expect(find.text('메시지 삭제'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await _pump(tester);
    expect(messages.deletes, ['new']);
    expect(messages.items, hasLength(9));
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await _bottom(tester);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('8'))).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(SnackBar)).top - 8),
    );
    await tester.pump(const Duration(seconds: 5));
    await _pump(tester);
    await _bottom(tester);
    expect(find.byType(SnackBar), findsNothing);
    expect(
      tester.getRect(find.byKey(const ValueKey('8'))).bottom,
      closeTo(915 - 48 - 80, 0.5),
    );
  });
  for (final count in [0, 1, 9]) {
    testWidgets('320dp 큰 글씨에서 $count 개 추가 버튼에 접근해야 한다', (tester) async {
      await _open(tester, count, 48, scale: 2, width: 320);
      if (count == 0) {
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.byType(MessageCard), findsNothing);
        final button = find
            .byWidgetPredicate((widget) => widget is FilledButton)
            .first;
        await tester.ensureVisible(button);
        await _pump(tester);
        expect(button.hitTestable(), findsOneWidget);
        expect(tester.getRect(button).bottom, lessThanOrEqualTo(915 - 48));
      } else {
        final fab = find.byType(FloatingActionButton);
        expect(fab.hitTestable(), findsOneWidget);
        expect(tester.getRect(fab).left, greaterThanOrEqualTo(0));
        expect(tester.getRect(fab).right, lessThanOrEqualTo(320));
        await _bottom(tester);
        expect(
          tester.getRect(find.byKey(ValueKey('${count - 1}'))).bottom,
          lessThanOrEqualTo(tester.getRect(fab).top - 8),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('다른 Scaffold 위로 push된 상태에서 피드백 후 뒤로 가도 예외가 없어야 한다', (
    tester,
  ) async {
    final messages = await _open(tester, 9, 48, pushed: true);
    await _bottom(tester);
    await tester.drag(
      find.byKey(const ValueKey('dismissible_8')),
      const Offset(-350, 0),
    );
    await _pump(tester);
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await _pump(tester);
    expect(messages.deletes, ['8']);
    expect(tester.takeException(), isNull);
    expect(find.text('메시지가 삭제되었습니다'), findsWidgets);
    await tester.binding.handlePopRoute();
    await _pump(tester);
    expect(find.text('base'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('가로 화면 측면 컷아웃에서 카드와 FAB가 컷아웃·하단을 피해야 한다', (tester) async {
    await _open(tester, 9, 24, width: 915, height: 412, left: 48);
    final fab = find.byType(FloatingActionButton);
    expect(fab.hitTestable(), findsOneWidget);
    expect(tester.getRect(fab).right, lessThanOrEqualTo(915));
    expect(tester.getRect(fab).bottom, lessThanOrEqualTo(412 - 24));
    expect(
      tester.getRect(find.byType(MessageCard).first).left,
      greaterThanOrEqualTo(48),
    );
    await _bottom(tester);
    expect(
      tester.getRect(find.byKey(const ValueKey('8'))).bottom,
      lessThanOrEqualTo(tester.getRect(fab).top - 8),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('SnackBar 표시 중 마지막 카드 재정렬과 여백 복원', (tester) async {
    final messages = await _open(tester, 9, 48);
    await _bottom(tester);
    await tester.drag(
      find.byKey(const ValueKey('dismissible_7')),
      const Offset(-350, 0),
    );
    await _pump(tester);
    await tester.tap(find.widgetWithText(TextButton, '삭제'));
    await _pump(tester);
    expect(find.byType(SnackBar), findsOneWidget);
    await _bottom(tester);
    final last = find.byKey(const ValueKey('8'));
    final snackTop = tester.getRect(find.byType(SnackBar)).top;
    expect(tester.getRect(last).bottom, lessThanOrEqualTo(snackTop - 8));
    final handle = find
        .descendant(
          of: last,
          matching: find.byType(ReorderableDragStartListener),
        )
        .first;
    expect(handle.hitTestable(), findsOneWidget);
    final start = tester.getCenter(handle);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(start - const Offset(0, 170));
    await _pump(tester);
    await gesture.up();
    await _pump(tester);
    expect(messages.moves.single.$1, 7);
    expect(messages.moves.single.$2, lessThan(7));
    await tester.pump(const Duration(seconds: 5));
    await _pump(tester);
    expect(find.byType(SnackBar), findsNothing);
    await _bottom(tester);
    final lastCard = find.byType(MessageCard).last;
    expect(tester.getRect(lastCard).bottom, closeTo(915 - 48 - 80, 0.5));
    expect(tester.takeException(), isNull);
  });
}
