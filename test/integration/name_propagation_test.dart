import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/notification_messages.dart';
import 'package:mindlog/core/services/fcm_service.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/providers/notification_settings_controller.dart';
import 'package:mindlog/presentation/providers/self_encouragement_controller.dart';
import 'package:mindlog/presentation/providers/user_name_controller.dart';

import '../mocks/mock_repositories.dart';

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
    rescheduleCalls.add(List.from(messages));
  }
}

/// 메시지 리스트를 제공하는 Fake Controller
class _FakeSelfEncouragementController extends SelfEncouragementController {
  final List<SelfEncouragementMessage> _messages;
  _FakeSelfEncouragementController(this._messages);

  @override
  FutureOr<List<SelfEncouragementMessage>> build() => _messages;
}

void main() {
  late MockSettingsRepository mockRepo;
  late _TrackingNotificationSettingsController trackingController;

  setUp(() {
    mockRepo = MockSettingsRepository();
    trackingController = _TrackingNotificationSettingsController();
    FCMService.resetForTesting();
    NotificationMessages.resetForTesting();
  });

  tearDown(() {
    mockRepo.reset();
    FCMService.resetForTesting();
    NotificationMessages.resetForTesting();
  });

  group('이름 전파 통합 테스트', () {
    test('이름 설정 → repository + provider + 알림 재스케줄 모두 반영', () async {
      // Arrange
      final messages = [_makeMessage('1', content: '{name}님, 화이팅!')];
      final fakeEncouragementController = _FakeSelfEncouragementController(
        messages,
      );

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockRepo),
          notificationSettingsProvider.overrideWith(() => trackingController),
          selfEncouragementProvider.overrideWith(
            () => fakeEncouragementController,
          ),
        ],
      );
      addTearDown(container.dispose);

      // Act: 이름 설정
      await container.read(userNameProvider.future);
      await container.read(userNameProvider.notifier).setUserName('지수');

      // Assert 1: Provider 값 확인
      final providerValue = container.read(userNameProvider).valueOrNull;
      expect(providerValue, '지수');

      // Assert 2: Repository 값 확인
      final repoValue = await mockRepo.getUserName();
      expect(repoValue, '지수');

      // Assert 3: 알림 재스케줄 호출 확인
      expect(trackingController.rescheduleCalls, hasLength(1));
      expect(
        trackingController.rescheduleCalls.first.first.content,
        '{name}님, 화이팅!',
      );
    });

    test('이름 삭제(null) → 모든 터치포인트에서 null 전파', () async {
      // Arrange: 이름 '민수' 설정 후 삭제
      await mockRepo.setUserName('민수');

      final messages = [_makeMessage('1')];
      final fakeEncouragementController = _FakeSelfEncouragementController(
        messages,
      );

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockRepo),
          notificationSettingsProvider.overrideWith(() => trackingController),
          selfEncouragementProvider.overrideWith(
            () => fakeEncouragementController,
          ),
        ],
      );
      addTearDown(container.dispose);

      // Act: 이름 삭제
      await container.read(userNameProvider.future);
      await container.read(userNameProvider.notifier).setUserName(null);

      // Assert 1: Provider 값 null
      final providerValue = container.read(userNameProvider).valueOrNull;
      expect(providerValue, isNull);

      // Assert 2: Repository 값 null
      final repoValue = await mockRepo.getUserName();
      expect(repoValue, isNull);
    });

    test('FCM 메시지에 userName 개인화가 적용되지 않아야 한다', () async {
      // Arrange: FCM은 백그라운드에서 OS가 직접 표시하므로 userName 개인화 불가
      FCMService.emotionScoreProvider = () async => null;

      // Act
      final result = await FCMService.buildPersonalizedMessage(
        serverTitle: '좋은 하루',
        serverBody: '테스트 본문',
      );

      // Assert: 서버 메시지 그대로 사용 (userName 개인화 없음)
      expect(result.title, '좋은 하루');
      expect(result.body, '테스트 본문');
      expect(result.title, isNot(contains('{name}')));
      expect(result.body, isNot(contains('{name}')));
    });

    test('빈 문자열 이름 → null로 정규화', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockRepo),
          notificationSettingsProvider.overrideWith(() => trackingController),
          selfEncouragementProvider.overrideWith(
            () => _FakeSelfEncouragementController([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Act: 빈 문자열 설정
      await container.read(userNameProvider.future);
      await container.read(userNameProvider.notifier).setUserName('   ');

      // Assert: null로 정규화됨
      final providerValue = container.read(userNameProvider).valueOrNull;
      expect(providerValue, isNull);

      final repoValue = await mockRepo.getUserName();
      expect(repoValue, isNull);
    });

    test('applyNamePersonalization 순수 함수 동작 확인', () {
      // 이름 있을 때
      expect(
        NotificationMessages.applyNamePersonalization('{name}님, 화이팅!', '지수'),
        '지수님, 화이팅!',
      );

      // 이름 없을 때
      expect(
        NotificationMessages.applyNamePersonalization('{name}님, 화이팅!', null),
        '화이팅!',
      );

      // {name} 없는 메시지
      expect(
        NotificationMessages.applyNamePersonalization('오늘도 좋은 하루!', '민수'),
        '오늘도 좋은 하루!',
      );
    });
  });
}
