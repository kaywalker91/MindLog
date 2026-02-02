import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/widgets/settings/settings_sections.dart';

import '../../../mocks/mock_repositories.dart';

/// Settings Section 위젯 테스트
///
/// 분해된 5개 Section 위젯의 렌더링 및 상호작용 테스트
void main() {
  group('EmotionCareSection', () {
    late ProviderContainer container;
    late MockSettingsRepository mockSettingsRepo;

    setUp(() {
      mockSettingsRepo = MockSettingsRepository();
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
      );
    });

    tearDown(() {
      mockSettingsRepo.reset();
      container.dispose();
    });

    testWidgets('AI 캐릭터 섹션이 렌더링되어야 한다', (tester) async {
      // Arrange
      mockSettingsRepo.setMockCharacter(AiCharacter.warmCounselor);

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCareSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('감정 케어'), findsOneWidget);
      expect(find.text('AI 캐릭터'), findsOneWidget);
      expect(find.text('내 이름'), findsOneWidget);
    });

    testWidgets('AI 캐릭터 라벨이 올바르게 표시되어야 한다', (tester) async {
      // Arrange
      mockSettingsRepo.setMockCharacter(AiCharacter.realisticCoach);

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCareSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - 현실적인 코치 캐릭터 이름 표시
      expect(find.text(AiCharacter.realisticCoach.displayName), findsOneWidget);
    });
  });

  group('NotificationSection', () {
    late ProviderContainer container;
    late MockSettingsRepository mockSettingsRepo;

    setUp(() {
      mockSettingsRepo = MockSettingsRepository();
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ],
      );
    });

    tearDown(() {
      mockSettingsRepo.reset();
      container.dispose();
    });

    testWidgets('알림 섹션이 렌더링되어야 한다', (tester) async {
      // Arrange
      mockSettingsRepo.setMockNotificationSettings(NotificationSettings.defaults());

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NotificationSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('알림'), findsOneWidget);
      expect(find.text('일기 리마인더'), findsOneWidget);
      expect(find.text('리마인더 시간'), findsOneWidget);
      expect(find.text('테스트 알림 보내기'), findsOneWidget);
      expect(find.text('마음 케어 알림'), findsOneWidget);
    });

    testWidgets('리마인더 토글 상태가 올바르게 표시되어야 한다', (tester) async {
      // Arrange - 리마인더 비활성화 상태
      mockSettingsRepo.setMockNotificationSettings(NotificationSettings(
        isReminderEnabled: false,
        reminderHour: 21,
        reminderMinute: 0,
        isMindcareTopicEnabled: false,
      ));

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: NotificationSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Switch 위젯이 OFF 상태
      final switchFinder = find.byType(Switch).first;
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, false);
    });
  });

  group('DataManagementSection', () {
    late ProviderContainer container;
    late MockDiaryRepository mockDiaryRepo;

    setUp(() {
      mockDiaryRepo = MockDiaryRepository();
      container = ProviderContainer(
        overrides: [
          diaryRepositoryProvider.overrideWithValue(mockDiaryRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('데이터 관리 섹션이 렌더링되어야 한다', (tester) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DataManagementSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('데이터 관리'), findsOneWidget);
      expect(find.text('모든 일기 삭제'), findsOneWidget);
    });

    testWidgets('삭제 버튼 탭 시 확인 다이얼로그가 표시되어야 한다', (tester) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DataManagementSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 삭제 버튼 탭
      await tester.tap(find.text('모든 일기 삭제'));
      await tester.pumpAndSettle();

      // Assert - 확인 다이얼로그 표시
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });
  });

  group('SupportSection', () {
    testWidgets('지원 섹션이 렌더링되어야 한다', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SupportSection(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('지원'), findsOneWidget);
      expect(find.text('도움말'), findsOneWidget);
      expect(find.text('문의하기'), findsOneWidget);
    });

    testWidgets('도움말 탭 시 다이얼로그가 표시되어야 한다', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SupportSection(),
            ),
          ),
        ),
      );

      // 도움말 탭
      await tester.tap(find.text('도움말'));
      await tester.pumpAndSettle();

      // Assert - HelpDialog 표시
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
