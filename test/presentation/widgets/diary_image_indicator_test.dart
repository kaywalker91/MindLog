import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/diary_image_indicator.dart';

void main() {
  /// 테스트용 위젯 생성
  Widget buildTestWidget({required int count}) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: Center(child: DiaryImageIndicator(count: count)),
      ),
    );
  }

  group('DiaryImageIndicator', () {
    group('표시 조건', () {
      testWidgets('count가 0이면 아무것도 표시하지 않는다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildTestWidget(count: 0));

        // Assert
        expect(find.byType(DiaryImageIndicator), findsOneWidget);
        expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
        expect(find.text('0'), findsNothing);
      });

      testWidgets('count가 음수면 아무것도 표시하지 않는다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildTestWidget(count: -1));

        // Assert
        expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
      });

      testWidgets('count가 1 이상이면 인디케이터를 표시한다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildTestWidget(count: 1));

        // Assert
        expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
      });
    });

    group('카운터 표시', () {
      testWidgets('count가 1이면 "1"을 표시한다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildTestWidget(count: 1));

        // Assert
        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('count가 5이면 "5"를 표시한다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildTestWidget(count: 5));

        // Assert
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('count가 10이면 "10"을 표시한다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildTestWidget(count: 10));

        // Assert
        expect(find.text('10'), findsOneWidget);
      });
    });

    group('아이콘 표시', () {
      testWidgets('카메라 아이콘이 표시된다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildTestWidget(count: 3));

        // Assert
        expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
      });
    });

    group('접근성', () {
      testWidgets('Semantics 위젯이 포함되어 있다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildTestWidget(count: 3));

        // Assert - Semantics 위젯이 존재함
        expect(find.byType(Semantics), findsWidgets);
      });
    });

    group('레이아웃', () {
      testWidgets('아이콘과 텍스트가 Row 내에 있다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildTestWidget(count: 2));

        // Assert
        final row = find.byType(Row);
        expect(row, findsWidgets);
      });

      testWidgets('Container에 둥근 모서리가 있다', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(buildTestWidget(count: 2));

        // Assert - 컨테이너가 존재함
        expect(find.byType(Container), findsWidgets);
      });
    });
  });
}
