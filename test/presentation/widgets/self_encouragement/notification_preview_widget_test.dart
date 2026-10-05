import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/self_encouragement/notification_preview_widget.dart';

Future<void> _pump(WidgetTester tester, double width, double scale) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(scale),
        ),
        child: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: NotificationPreviewWidget(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('헤더 시각은 카드 오른쪽 끝에 정렬되어야 한다', (tester) async {
    await _pump(tester, 412, 1);
    final name = tester.getRect(find.text('MindLog'));
    final time = tester.getRect(find.text('지금'));
    expect(time.top, closeTo(name.top, 4));
    // Card spans 16..396 with 12dp inner padding.
    expect(time.right, closeTo(412 - 16 - 12, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('320dp 글자 2배에서 헤더가 overflow 없이 표시되어야 한다', (tester) async {
    await _pump(tester, 320, 2);
    expect(find.text('MindLog'), findsOneWidget);
    expect(find.text('지금'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
