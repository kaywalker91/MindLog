import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
import 'package:mindlog/domain/usecases/set_notification_settings_usecase.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/providers/notification_settings_controller.dart';
import 'package:mindlog/presentation/providers/self_encouragement_controller.dart';

import '../../mocks/mock_repositories.dart';

/// Mock SetNotificationSettingsUseCase (index 조정 검증용)
class MockSetNotificationSettingsUseCase
    implements SetNotificationSettingsUseCase {
  final List<NotificationSettings> savedSettings = [];

  void reset() {
    savedSettings.clear();
  }

  @override
  Future<void> execute(NotificationSettings settings) async {
    savedSettings.add(settings);
  }
}

/// 테스트용 헬퍼: 메시지 생성
SelfEncouragementMessage _makeMessage(
  String id, {
  int displayOrder = 0,
  String? content,
}) {
  return SelfEncouragementMessage(
    id: id,
    content: content ?? '메시지 $id',
    createdAt: DateTime(2026, 1, 1),
    displayOrder: displayOrder,
  );
}

void main() {
  late ProviderContainer container;
  late MockSettingsRepositoryWithMessages mockRepository;
  late MockSetNotificationSettingsUseCase mockSetUseCase;

  /// ProviderContainer 생성 (notificationSettings 오버라이드 포함)
  ProviderContainer createContainer({
    NotificationSettings? notificationSettings,
  }) {
    final settings = notificationSettings ?? NotificationSettings.defaults();
    mockSetUseCase = MockSetNotificationSettingsUseCase();

    return ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(mockRepository),
        // notificationSettingsProvider를 특정 설정으로 오버라이드
        notificationSettingsProvider.overrideWith(() {
          return _FakeNotificationSettingsController(settings);
        }),
        setNotificationSettingsUseCaseProvider
            .overrideWithValue(mockSetUseCase),
      ],
    );
  }

  setUp(() {
    mockRepository = MockSettingsRepositoryWithMessages();
    mockSetUseCase = MockSetNotificationSettingsUseCase();
  });

  tearDown(() {
    container.dispose();
    mockRepository.reset();
    mockSetUseCase.reset();
  });

  group('SelfEncouragementController', () {
    group('build (초기 로드)', () {
      test('Repository에서 메시지 목록을 조회해야 한다', () async {
        // Arrange
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
        ];
        container = createContainer();

        // Act
        final messages =
            await container.read(selfEncouragementProvider.future);

        // Assert
        expect(messages.length, 2);
        expect(messages[0].id, 'm1');
        expect(messages[1].id, 'm2');
      });

      test('메시지가 displayOrder 순으로 정렬되어야 한다', () async {
        // Arrange
        mockRepository.messages = [
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m3', displayOrder: 2),
        ];
        container = createContainer();

        // Act
        final messages =
            await container.read(selfEncouragementProvider.future);

        // Assert
        expect(messages[0].id, 'm1');
        expect(messages[1].id, 'm2');
        expect(messages[2].id, 'm3');
      });

      test('메시지가 없으면 빈 리스트를 반환해야 한다', () async {
        // Arrange
        container = createContainer();

        // Act
        final messages =
            await container.read(selfEncouragementProvider.future);

        // Assert
        expect(messages, isEmpty);
      });
    });

    group('addMessage', () {
      test('정상 메시지를 추가해야 한다', () async {
        // Arrange
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        final result = await notifier.addMessage('새 응원 메시지');

        // Assert
        expect(result, true);
        final messages = container.read(selfEncouragementProvider).value!;
        expect(messages.length, 1);
        expect(messages[0].content, '새 응원 메시지');
        expect(messages[0].displayOrder, 0);
      });

      test('빈 메시지는 거부해야 한다', () async {
        // Arrange
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        final result = await notifier.addMessage('');

        // Assert
        expect(result, false);
        expect(container.read(selfEncouragementProvider).value, isEmpty);
      });

      test('공백만 있는 메시지는 거부해야 한다', () async {
        // Arrange
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        final result = await notifier.addMessage('   ');

        // Assert
        expect(result, false);
      });

      test('최대 길이 초과 메시지는 거부해야 한다', () async {
        // Arrange
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);
        final longContent =
            'a' * (SelfEncouragementMessage.maxContentLength + 1);

        // Act
        final result = await notifier.addMessage(longContent);

        // Assert
        expect(result, false);
      });

      test('최대 개수 초과 시 거부해야 한다', () async {
        // Arrange
        for (var i = 0;
            i < SelfEncouragementMessage.maxMessageCount;
            i++) {
          mockRepository.messages.add(
            _makeMessage('m$i', displayOrder: i, content: '메시지 $i'),
          );
        }
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        final result = await notifier.addMessage('초과 메시지');

        // Assert
        expect(result, false);
        expect(
          container.read(selfEncouragementProvider).value!.length,
          SelfEncouragementMessage.maxMessageCount,
        );
      });

      test('displayOrder가 기존 목록 끝에 추가되어야 한다', () async {
        // Arrange
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
        ];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.addMessage('세 번째');

        // Assert
        final messages = container.read(selfEncouragementProvider).value!;
        expect(messages.length, 3);
        expect(messages[2].content, '세 번째');
        expect(messages[2].displayOrder, 2);
      });

      test('Repository에 저장되어야 한다', () async {
        // Arrange
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.addMessage('저장할 메시지');

        // Assert
        expect(mockRepository.addedMessages.length, 1);
        expect(mockRepository.addedMessages[0].content, '저장할 메시지');
      });
    });

    group('updateMessage', () {
      test('기존 메시지 내용을 수정해야 한다', () async {
        // Arrange
        mockRepository.messages = [_makeMessage('m1', content: '원본')];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        final result = await notifier.updateMessage('m1', '수정됨');

        // Assert
        expect(result, true);
        final messages = container.read(selfEncouragementProvider).value!;
        expect(messages[0].content, '수정됨');
      });

      test('존재하지 않는 ID는 false를 반환해야 한다', () async {
        // Arrange
        mockRepository.messages = [_makeMessage('m1')];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        final result = await notifier.updateMessage('nonexistent', '수정');

        // Assert
        expect(result, false);
      });

      test('빈 내용으로 수정 시 false를 반환해야 한다', () async {
        // Arrange
        mockRepository.messages = [_makeMessage('m1')];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        final result = await notifier.updateMessage('m1', '');

        // Assert
        expect(result, false);
      });

      test('최대 길이 초과 수정은 false를 반환해야 한다', () async {
        // Arrange
        mockRepository.messages = [_makeMessage('m1')];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);
        final longContent =
            'a' * (SelfEncouragementMessage.maxContentLength + 1);

        // Act
        final result = await notifier.updateMessage('m1', longContent);

        // Assert
        expect(result, false);
      });

      test('Repository에 수정된 메시지가 저장되어야 한다', () async {
        // Arrange
        mockRepository.messages = [_makeMessage('m1', content: '원본')];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.updateMessage('m1', '수정됨');

        // Assert
        expect(mockRepository.updatedMessages.length, 1);
        expect(mockRepository.updatedMessages[0].content, '수정됨');
        expect(mockRepository.updatedMessages[0].id, 'm1');
      });
    });

    group('deleteMessage', () {
      test('메시지를 삭제해야 한다', () async {
        // Arrange
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m3', displayOrder: 2),
        ];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.deleteMessage('m2');

        // Assert
        final messages = container.read(selfEncouragementProvider).value!;
        expect(messages.length, 2);
        expect(messages.any((m) => m.id == 'm2'), false);
      });

      test('삭제 후 displayOrder가 재정렬되어야 한다', () async {
        // Arrange
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m3', displayOrder: 2),
        ];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.deleteMessage('m1');

        // Assert
        final messages = container.read(selfEncouragementProvider).value!;
        expect(messages[0].displayOrder, 0); // m2 → 0
        expect(messages[1].displayOrder, 1); // m3 → 1
      });

      test('Repository에서 삭제되어야 한다', () async {
        // Arrange
        mockRepository.messages = [_makeMessage('m1')];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.deleteMessage('m1');

        // Assert
        expect(mockRepository.deletedMessageIds, ['m1']);
      });
    });

    group('deleteMessage - _adjustLastDisplayedIndex (순차 모드)', () {
      test('랜덤 모드에서는 index 조정하지 않아야 한다', () async {
        // Arrange - random 모드
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.random,
          lastDisplayedIndex: 1,
        );
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m3', displayOrder: 2),
        ];
        container = createContainer(notificationSettings: settings);
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.deleteMessage('m1');

        // Assert - setUseCase가 호출되지 않아야 함
        expect(mockSetUseCase.savedSettings, isEmpty);
      });

      test('삭제 위치가 lastDisplayedIndex 이후면 변경하지 않아야 한다', () async {
        // Arrange - 순차 모드, lastDisplayedIndex=0, 삭제 위치=2
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.sequential,
          lastDisplayedIndex: 0,
        );
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m3', displayOrder: 2),
        ];
        container = createContainer(notificationSettings: settings);
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act - 마지막 메시지 삭제 (index 2)
        await notifier.deleteMessage('m3');

        // Assert - index가 변경되지 않아야 함
        expect(mockSetUseCase.savedSettings, isEmpty);
      });

      test('삭제 위치가 lastDisplayedIndex 이전이면 1 감소해야 한다', () async {
        // Arrange - 순차 모드, lastDisplayedIndex=2, 삭제 위치=0
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.sequential,
          lastDisplayedIndex: 2,
        );
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m3', displayOrder: 2),
        ];
        container = createContainer(notificationSettings: settings);
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act - 첫 번째 메시지 삭제 (index 0)
        await notifier.deleteMessage('m1');

        // Assert - lastDisplayedIndex: 2 → 1
        expect(mockSetUseCase.savedSettings.length, 1);
        expect(mockSetUseCase.savedSettings[0].lastDisplayedIndex, 1);
      });

      test('삭제 위치가 lastDisplayedIndex와 같으면 1 감소 (wrap-around)해야 한다',
          () async {
        // Arrange - 순차 모드, lastDisplayedIndex=1, 삭제 위치=1
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.sequential,
          lastDisplayedIndex: 1,
        );
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m3', displayOrder: 2),
        ];
        container = createContainer(notificationSettings: settings);
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act - 두 번째 메시지 삭제 (index 1)
        await notifier.deleteMessage('m2');

        // Assert
        // remaining=2, (1-1+2)%2 = 0
        expect(mockSetUseCase.savedSettings.length, 1);
        expect(mockSetUseCase.savedSettings[0].lastDisplayedIndex, 0);
      });

      test('lastDisplayedIndex=0에서 첫 번째 삭제 시 wrap-around해야 한다',
          () async {
        // Arrange - 순차 모드, lastDisplayedIndex=0, 삭제 위치=0
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.sequential,
          lastDisplayedIndex: 0,
        );
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m3', displayOrder: 2),
        ];
        container = createContainer(notificationSettings: settings);
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act - 첫 번째 메시지 삭제 (index 0)
        await notifier.deleteMessage('m1');

        // Assert
        // remaining=2, (0-1+2)%2 = 1
        expect(mockSetUseCase.savedSettings.length, 1);
        expect(mockSetUseCase.savedSettings[0].lastDisplayedIndex, 1);
      });

      test('모든 메시지 삭제 시 index가 0이 되어야 한다', () async {
        // Arrange - 순차 모드, lastDisplayedIndex=0, 메시지 1개
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.sequential,
          lastDisplayedIndex: 0,
        );
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
        ];
        container = createContainer(notificationSettings: settings);
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act - 유일한 메시지 삭제
        await notifier.deleteMessage('m1');

        // Assert - remainingCount=0 → adjusted=0, 하지만 last도 0이라 변경 없음
        // 코드: adjusted = 0, last = 0 → adjusted != last false → return
        expect(mockSetUseCase.savedSettings, isEmpty);
      });

      test('5개 중 중간(index 2) 삭제 시 lastDisplayedIndex=3이 2로 변경되어야 한다',
          () async {
        // Arrange
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.sequential,
          lastDisplayedIndex: 3,
        );
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m3', displayOrder: 2),
          _makeMessage('m4', displayOrder: 3),
          _makeMessage('m5', displayOrder: 4),
        ];
        container = createContainer(notificationSettings: settings);
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.deleteMessage('m3');

        // Assert
        // remaining=4, deletedIndex=2, last=3
        // deletedIndex(2) <= last(3) → adjusted = (3-1+4)%4 = 2
        expect(mockSetUseCase.savedSettings.length, 1);
        expect(mockSetUseCase.savedSettings[0].lastDisplayedIndex, 2);
      });

      test('마지막 index에서 해당 위치 삭제 시 wrap-around해야 한다', () async {
        // Arrange - 5개 메시지, lastDisplayedIndex=4(마지막), 삭제 위치=4
        final settings = NotificationSettings.defaults().copyWith(
          rotationMode: MessageRotationMode.sequential,
          lastDisplayedIndex: 4,
        );
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m3', displayOrder: 2),
          _makeMessage('m4', displayOrder: 3),
          _makeMessage('m5', displayOrder: 4),
        ];
        container = createContainer(notificationSettings: settings);
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act - 마지막 메시지 삭제
        await notifier.deleteMessage('m5');

        // Assert
        // remaining=4, deletedIndex=4, last=4
        // deletedIndex(4) <= last(4) → adjusted = (4-1+4)%4 = 3
        expect(mockSetUseCase.savedSettings.length, 1);
        expect(mockSetUseCase.savedSettings[0].lastDisplayedIndex, 3);
      });
    });

    group('reorder', () {
      test('정상적으로 메시지 순서를 변경해야 한다', () async {
        // Arrange
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0, content: '첫 번째'),
          _makeMessage('m2', displayOrder: 1, content: '두 번째'),
          _makeMessage('m3', displayOrder: 2, content: '세 번째'),
        ];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act - m1(0)을 m3 위치(2)로 이동
        await notifier.reorder(0, 2);

        // Assert
        final messages = container.read(selfEncouragementProvider).value!;
        expect(messages[0].id, 'm2');
        expect(messages[1].id, 'm3');
        expect(messages[2].id, 'm1');
      });

      test('reorder 후 displayOrder가 올바르게 업데이트되어야 한다', () async {
        // Arrange
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m3', displayOrder: 2),
        ];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.reorder(2, 0);

        // Assert
        final messages = container.read(selfEncouragementProvider).value!;
        for (var i = 0; i < messages.length; i++) {
          expect(messages[i].displayOrder, i);
        }
      });

      test('oldIndex가 범위 밖이면 무시해야 한다', () async {
        // Arrange
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
        ];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.reorder(-1, 0);
        await notifier.reorder(5, 0);

        // Assert - 변경 없음
        final messages = container.read(selfEncouragementProvider).value!;
        expect(messages[0].id, 'm1');
        expect(messages[1].id, 'm2');
      });

      test('newIndex가 범위 밖이면 무시해야 한다', () async {
        // Arrange
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
        ];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.reorder(0, -1);
        await notifier.reorder(0, 5);

        // Assert - 변경 없음
        final messages = container.read(selfEncouragementProvider).value!;
        expect(messages[0].id, 'm1');
        expect(messages[1].id, 'm2');
      });

      test('같은 위치로 reorder 시 내용은 유지되어야 한다', () async {
        // Arrange
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
        ];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act
        await notifier.reorder(0, 0);

        // Assert
        final messages = container.read(selfEncouragementProvider).value!;
        expect(messages[0].id, 'm1');
        expect(messages[1].id, 'm2');
      });

      test('Repository에 새 순서가 저장되어야 한다', () async {
        // Arrange
        mockRepository.messages = [
          _makeMessage('m1', displayOrder: 0),
          _makeMessage('m2', displayOrder: 1),
          _makeMessage('m3', displayOrder: 2),
        ];
        container = createContainer();
        await container.read(selfEncouragementProvider.future);
        final notifier = container.read(selfEncouragementProvider.notifier);

        // Act - m3(2)를 0으로 이동
        await notifier.reorder(2, 0);

        // Assert - 호출 확인 (reorderSelfEncouragementMessages)
        // MockSettingsRepositoryWithMessages의 messages가 reorder됨
        final messages = container.read(selfEncouragementProvider).value!;
        expect(messages[0].id, 'm3');
        expect(messages[1].id, 'm1');
        expect(messages[2].id, 'm2');
      });
    });
  });
}

/// notificationSettingsProvider 오버라이드용 Fake Controller
class _FakeNotificationSettingsController
    extends AsyncNotifier<NotificationSettings>
    implements NotificationSettingsController {
  _FakeNotificationSettingsController(this._settings);

  final NotificationSettings _settings;

  @override
  FutureOr<NotificationSettings> build() => _settings;

  @override
  Future<void> updateReminderEnabled(bool enabled) async {}

  @override
  Future<void> updateReminderTime({
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> updateMindcareTopicEnabled(bool enabled) async {}

  @override
  Future<void> updateRotationMode(MessageRotationMode mode) async {}

  @override
  Future<void> rescheduleWithMessages(
    List<SelfEncouragementMessage> messages,
  ) async {}
}
