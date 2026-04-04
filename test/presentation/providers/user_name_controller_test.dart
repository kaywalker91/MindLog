import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/providers/notification_settings_controller.dart';
import 'package:mindlog/presentation/providers/self_encouragement_controller.dart';
import 'package:mindlog/presentation/providers/user_name_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_fallbacks.dart';
import '../../mocks/mock_repositories.dart';

/// 테스트용 메시지 팩토리
SelfEncouragementMessage _makeMessage(String id, {String? content}) {
  return SelfEncouragementMessage(
    id: id,
    content: content ?? '메시지 $id',
    createdAt: DateTime(2026, 1, 1),
    displayOrder: 0,
  );
}

/// rescheduleWithMessages 호출을 추적하는 Fake Controller
class _TrackingNotificationSettingsController
    extends AsyncNotifier<NotificationSettings>
    implements NotificationSettingsController {
  final List<List<SelfEncouragementMessage>> rescheduleCalls = [];
  bool shouldThrow = false;

  @override
  FutureOr<NotificationSettings> build() => NotificationSettings.defaults();

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
  Future<void> updateWeeklyInsightEnabled(bool enabled) async {}

  @override
  Future<void> rescheduleWithMessages(
    List<SelfEncouragementMessage> messages,
  ) async {
    if (shouldThrow) {
      throw Exception('Reschedule failed');
    }
    rescheduleCalls.add(List.from(messages));
  }
}

void main() {
  late ProviderContainer container;
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerMockFallbackValues();
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    when(
      () => mockRepository.getUserName(),
    ).thenAnswer((_) async => null);
    when(
      () => mockRepository.setUserName(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.getSelectedAiCharacter(),
    ).thenAnswer((_) async => AiCharacter.warmCounselor);
    when(
      () => mockRepository.setSelectedAiCharacter(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.getNotificationSettings(),
    ).thenAnswer((_) async => NotificationSettings.defaults());
    when(
      () => mockRepository.setNotificationSettings(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.getSelfEncouragementMessages(),
    ).thenAnswer((_) async => []);

    container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  group('UserNameController', () {
    group('build', () {
      test('초기 로드 시 Repository에서 이름을 조회해야 한다', () async {
        // Arrange
        when(
          () => mockRepository.getUserName(),
        ).thenAnswer((_) async => '홍길동');

        // Act
        final userName = await container.read(userNameProvider.future);

        // Assert
        expect(userName, '홍길동');
      });

      test('이름이 설정되지 않았으면 null을 반환해야 한다', () async {
        // Act
        final userName = await container.read(userNameProvider.future);

        // Assert
        expect(userName, isNull);
      });

      test('Repository 에러 시 AsyncError 상태여야 한다', () async {
        // Arrange
        when(
          () => mockRepository.getUserName(),
        ).thenThrow(const Failure.cache(message: '이름 조회 실패'));

        // Act
        await container.read(userNameProvider.future).catchError((_) => null);

        // Assert
        final state = container.read(userNameProvider);
        expect(state, isA<AsyncError<String?>>());
      });
    });

    group('setUserName', () {
      test('이름 설정 시 Repository에 저장해야 한다', () async {
        // Arrange
        String? savedName;
        when(() => mockRepository.setUserName(any())).thenAnswer((inv) async {
          savedName = inv.positionalArguments[0] as String?;
        });
        when(
          () => mockRepository.getUserName(),
        ).thenAnswer((_) async => savedName);
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('김철수');

        // Assert - Repository에서 저장 확인
        final captured = verify(
          () => mockRepository.setUserName(captureAny()),
        ).captured;
        expect(captured.last, '김철수');
      });

      test('설정 후 상태가 업데이트되어야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('이영희');

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, '이영희');
      });

      test('null 전달 시 이름이 삭제되어야 한다', () async {
        // Arrange
        when(
          () => mockRepository.getUserName(),
        ).thenAnswer((_) async => '기존이름');
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName(null);

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, isNull);
      });

      test('빈 문자열은 null로 변환되어야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('');

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, isNull);
      });

      test('공백만 있는 문자열은 null로 변환되어야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('   ');

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, isNull);
      });

      test('앞뒤 공백이 제거되어야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('  홍길동  ');

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, '홍길동');
      });

      test('Repository 에러 시 예외를 전파해야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);
        when(
          () => mockRepository.setUserName(any()),
        ).thenThrow(const Failure.cache(message: '저장 실패'));

        // Act & Assert
        await expectLater(
          notifier.setUserName('테스트'),
          throwsA(isA<CacheFailure>()),
        );
      });

      test('연속 이름 변경이 올바르게 동작해야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('이름1');
        await notifier.setUserName('이름2');
        await notifier.setUserName('이름3');

        // Assert
        final state = container.read(userNameProvider);
        expect(state.value, '이름3');
      });

      test('이름 설정 후 다시 null로 변경할 수 있어야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('홍길동');
        expect(container.read(userNameProvider).value, '홍길동');

        await notifier.setUserName(null);

        // Assert
        expect(container.read(userNameProvider).value, isNull);
      });
    });

    group('이름 변경 시 알림 재스케줄링', () {
      late _TrackingNotificationSettingsController trackingController;
      late ProviderContainer rescheduleContainer;

      setUp(() {
        trackingController = _TrackingNotificationSettingsController();
      });

      ProviderContainer createRescheduleContainer({
        List<SelfEncouragementMessage> messages = const [],
      }) {
        final c = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepository),
            notificationSettingsProvider.overrideWith(() {
              return trackingController;
            }),
            selfEncouragementProvider.overrideWith(() {
              return _FakeSelfEncouragementController(messages);
            }),
          ],
        );
        addTearDown(c.dispose);
        return c;
      }

      test('setUserName 후 rescheduleWithMessages가 트리거되어야 한다', () async {
        final messages = [_makeMessage('m1', content: '{name}님, 힘내세요!')];
        rescheduleContainer = createRescheduleContainer(messages: messages);

        // 초기화
        await rescheduleContainer.read(userNameProvider.future);
        await rescheduleContainer.read(selfEncouragementProvider.future);

        // Act
        final notifier = rescheduleContainer.read(userNameProvider.notifier);
        await notifier.setUserName('지수');

        // Assert
        expect(trackingController.rescheduleCalls, hasLength(1));
        expect(trackingController.rescheduleCalls[0], hasLength(1));
        expect(
          trackingController.rescheduleCalls[0][0].content,
          '{name}님, 힘내세요!',
        );
      });

      test('메시지가 없어도 rescheduleWithMessages가 호출되어야 한다', () async {
        // Fix B: 외부 guard 제거 → applySettings 내부에서 empty 처리
        rescheduleContainer = createRescheduleContainer(messages: []);

        // 초기화
        await rescheduleContainer.read(userNameProvider.future);
        await rescheduleContainer.read(selfEncouragementProvider.future);

        // Act
        final notifier = rescheduleContainer.read(userNameProvider.notifier);
        await notifier.setUserName('지수');

        // Assert: empty messages로 reschedule 1회 호출됨
        expect(trackingController.rescheduleCalls, hasLength(1));
        expect(trackingController.rescheduleCalls[0], isEmpty);
      });

      test('reschedule 실패해도 이름 설정이 성공해야 한다', () async {
        final messages = [_makeMessage('m1')];
        trackingController.shouldThrow = true;
        rescheduleContainer = createRescheduleContainer(messages: messages);

        // 초기화
        await rescheduleContainer.read(userNameProvider.future);
        await rescheduleContainer.read(selfEncouragementProvider.future);

        // Act
        final notifier = rescheduleContainer.read(userNameProvider.notifier);
        await notifier.setUserName('지수');

        // Assert — 이름은 정상 저장됨
        final state = rescheduleContainer.read(userNameProvider);
        expect(state.value, '지수');
        // reschedule 호출은 시도됨 (throw됨)
        expect(trackingController.rescheduleCalls, isEmpty);
      });

      test('이름 삭제(null) 시에도 reschedule이 트리거되어야 한다', () async {
        final messages = [_makeMessage('m1', content: '{name}님, 화이팅!')];
        when(
          () => mockRepository.getUserName(),
        ).thenAnswer((_) async => '기존이름');
        rescheduleContainer = createRescheduleContainer(messages: messages);

        // 초기화
        await rescheduleContainer.read(userNameProvider.future);
        await rescheduleContainer.read(selfEncouragementProvider.future);

        // Act
        final notifier = rescheduleContainer.read(userNameProvider.notifier);
        await notifier.setUserName(null);

        // Assert
        expect(trackingController.rescheduleCalls, hasLength(1));
        final state = rescheduleContainer.read(userNameProvider);
        expect(state.value, isNull);
      });
    });

    group('특수 문자 처리', () {
      test('한글 이름을 올바르게 저장해야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('홍길동');

        // Assert
        expect(container.read(userNameProvider).value, '홍길동');
      });

      test('영문 이름을 올바르게 저장해야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('John Doe');

        // Assert
        expect(container.read(userNameProvider).value, 'John Doe');
      });

      test('이모지가 포함된 이름을 올바르게 저장해야 한다', () async {
        // Arrange
        await container.read(userNameProvider.future);
        final notifier = container.read(userNameProvider.notifier);

        // Act
        await notifier.setUserName('홍길동 😊');

        // Assert
        expect(container.read(userNameProvider).value, '홍길동 😊');
      });
    });
  });
}

/// Fake SelfEncouragementController that returns pre-set messages
class _FakeSelfEncouragementController
    extends AsyncNotifier<List<SelfEncouragementMessage>>
    implements SelfEncouragementController {
  _FakeSelfEncouragementController(this._messages);

  final List<SelfEncouragementMessage> _messages;

  @override
  FutureOr<List<SelfEncouragementMessage>> build() => _messages;

  @override
  Future<bool> addMessage(String content, {String? timeCategory}) async => true;

  @override
  Future<bool> updateMessage(String id, String content, {String? timeCategory}) async => true;

  @override
  Future<void> deleteMessage(String id) async {}

  @override
  Future<void> reorder(int oldIndex, int newIndex) async {}
}
