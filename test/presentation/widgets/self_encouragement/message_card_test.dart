import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/widgets/self_encouragement/message_card.dart';

import '../../../mocks/mock_repositories.dart';

/// 테스트용 메시지 팩토리
SelfEncouragementMessage _makeMessage({
  String id = '1',
  String content = '오늘도 화이팅!',
  int displayOrder = 0,
}) {
  return SelfEncouragementMessage(
    id: id,
    content: content,
    createdAt: DateTime(2026, 1, 1),
    displayOrder: displayOrder,
  );
}

/// MessageCard를 ReorderableListView 안에 렌더링 (ReorderableDragStartListener 요구)
Widget _buildTestWidget({
  required SelfEncouragementMessage message,
  List<Override> overrides = const [],
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: ReorderableListView(
          onReorder: (_, __) {},
          children: [
            MessageCard(
              key: ValueKey(message.id),
              message: message,
              index: 0,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    ),
  );
}

/// flutter_animate pump 패턴 (500ms x4 = 2000ms)
Future<void> _pumpAnimations(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  late MockSettingsRepository mockRepo;

  setUpAll(() {
    Animate.restartOnHotReload = false;
  });

  setUp(() {
    mockRepo = MockSettingsRepository();
  });

  tearDown(() {
    mockRepo.reset();
  });

  group('MessageCard 이름 개인화', () {
    testWidgets('이름이 설정되면 {name}을 실제 이름으로 치환해야 한다', (tester) async {
      // Arrange
      await mockRepo.setUserName('지수');
      final message = _makeMessage(content: '{name}님, 오늘도 화이팅! 💪');

      // Act
      await tester.pumpWidget(
        _buildTestWidget(
          message: message,
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await _pumpAnimations(tester);

      // Assert: 개인화된 텍스트 표시
      expect(find.textContaining('지수님, 오늘도 화이팅!'), findsOneWidget);
      expect(find.textContaining('{name}'), findsNothing);
    });

    testWidgets('이름이 null이면 {name}님, 패턴을 제거해야 한다', (tester) async {
      // Arrange: mockRepo의 userName은 기본 null
      final message = _makeMessage(content: '{name}님, 오늘도 화이팅! 💪');

      // Act
      await tester.pumpWidget(
        _buildTestWidget(
          message: message,
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await _pumpAnimations(tester);

      // Assert: {name}님, 패턴 제거
      expect(find.textContaining('오늘도 화이팅!'), findsOneWidget);
      expect(find.textContaining('{name}'), findsNothing);
    });

    testWidgets('{name} 없는 메시지는 그대로 표시해야 한다', (tester) async {
      // Arrange
      final message = _makeMessage(content: '오늘 하루도 수고했어! 🌟');

      // Act
      await tester.pumpWidget(
        _buildTestWidget(
          message: message,
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await _pumpAnimations(tester);

      // Assert: 원문 그대로
      expect(find.textContaining('오늘 하루도 수고했어!'), findsOneWidget);
    });

    testWidgets('이모지 추출이 개인화된 텍스트에서 동작해야 한다', (tester) async {
      // Arrange
      await mockRepo.setUserName('민수');
      final message = _makeMessage(content: '🎉 {name}님, 축하해요!');

      // Act
      await tester.pumpWidget(
        _buildTestWidget(
          message: message,
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await _pumpAnimations(tester);

      // Assert: 이모지 뱃지에 🎉 표시
      expect(find.text('🎉'), findsAtLeastNWidgets(1));
      // 개인화된 본문 표시
      expect(find.textContaining('민수님, 축하해요!'), findsOneWidget);
    });

    testWidgets('{name}님의 패턴도 올바르게 처리해야 한다', (tester) async {
      // Arrange: 이름 없음
      final message = _makeMessage(content: '{name}님의 하루가 빛나길 🌈');

      // Act
      await tester.pumpWidget(
        _buildTestWidget(
          message: message,
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await _pumpAnimations(tester);

      // Assert: {name}님의 패턴 제거
      expect(find.textContaining('하루가 빛나길'), findsOneWidget);
      expect(find.textContaining('{name}'), findsNothing);
    });

    testWidgets('{name}님의 패턴 + 이름 있을 때 치환해야 한다', (tester) async {
      // Arrange
      await mockRepo.setUserName('하늘');
      final message = _makeMessage(content: '{name}님의 하루가 빛나길 🌈');

      // Act
      await tester.pumpWidget(
        _buildTestWidget(
          message: message,
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
        ),
      );
      await _pumpAnimations(tester);

      // Assert: {name}을 실제 이름으로 치환
      expect(find.textContaining('하늘님의 하루가 빛나길'), findsOneWidget);
    });

    testWidgets('탭 시 onEdit 콜백을 호출해야 한다', (tester) async {
      // Arrange
      bool editCalled = false;
      final message = _makeMessage(content: '응원 메시지');

      // Act
      await tester.pumpWidget(
        _buildTestWidget(
          message: message,
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          onEdit: () => editCalled = true,
        ),
      );
      await _pumpAnimations(tester);

      // GestureDetector의 onTapUp 트리거
      final cardFinder = find.textContaining('응원 메시지');
      await tester.tap(cardFinder);
      await tester.pump();

      // Assert
      expect(editCalled, isTrue);
    });
  });
}
