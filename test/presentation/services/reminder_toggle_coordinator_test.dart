import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/services/reminder_toggle_coordinator.dart';

void main() {
  group('ReminderToggleCoordinator', () {
    late List<bool> persisted;
    late bool canExact;
    late bool ignoringBattery;
    late int exactRequestCount;
    late int exactMarkCount;
    late int batteryRequestCount;

    ReminderToggleCoordinator buildCoordinator() {
      return ReminderToggleCoordinator(
        updateReminderEnabled: (enabled) async {
          persisted.add(enabled);
        },
        canScheduleExactAlarms: () async => canExact,
        requestExactAlarmPermission: () async {
          exactRequestCount++;
        },
        markExactAlarmPrompted: () async {
          exactMarkCount++;
        },
        isIgnoringBatteryOptimizations: () async => ignoringBattery,
        requestDisableBatteryOptimization: () async {
          batteryRequestCount++;
        },
      );
    }

    setUp(() {
      persisted = [];
      canExact = true;
      ignoringBattery = true;
      exactRequestCount = 0;
      exactMarkCount = 0;
      batteryRequestCount = 0;
    });

    test('비활성화 시 설정을 끄고 ReminderDisabled를 반환해야 한다', () async {
      final coordinator = buildCoordinator();

      final result = await coordinator.setEnabled(false);

      expect(result, isA<ReminderDisabled>());
      expect(persisted, [false]);
    });

    test('권한 모두 허용 시 바로 ReminderEnabled를 반환해야 한다', () async {
      final coordinator = buildCoordinator();

      final result = await coordinator.setEnabled(true);

      expect(result, isA<ReminderEnabled>());
      expect((result as ReminderEnabled).warnings, isEmpty);
      expect(persisted, [true]);
    });

    test('정확알람 미허용 시 NeedExactAlarmPrompt를 반환해야 한다', () async {
      canExact = false;
      final coordinator = buildCoordinator();

      final result = await coordinator.prepareEnable();

      expect(result, isA<NeedExactAlarmPrompt>());
      expect(persisted, isEmpty);
    });

    test('정확알람 동의 후 여전히 거부면 경고를 남기고 배터리 단계로 진행해야 한다', () async {
      canExact = false;
      ignoringBattery = true;
      final coordinator = buildCoordinator();

      expect(await coordinator.prepareEnable(), isA<NeedExactAlarmPrompt>());

      // User opens settings but still denied
      canExact = false;
      final afterExact = await coordinator.onExactAlarmPromptResult(true);

      expect(afterExact, isA<ReminderEnabled>());
      final enabled = afterExact as ReminderEnabled;
      expect(enabled.warnings, [
        ReminderToggleCoordinator.exactAlarmWarningMessage,
      ]);
      expect(exactRequestCount, 1);
      expect(exactMarkCount, 1);
      expect(persisted, [true]);
    });

    test('정확알람 다이얼로그 취소 시 요청 없이 활성화해야 한다', () async {
      canExact = false;
      final coordinator = buildCoordinator();

      await coordinator.prepareEnable();
      final result = await coordinator.onExactAlarmPromptResult(false);

      expect(result, isA<ReminderEnabled>());
      expect((result as ReminderEnabled).warnings, isEmpty);
      expect(exactRequestCount, 0);
      expect(persisted, [true]);
    });

    test('배터리 최적화 활성 시 NeedBatteryPrompt를 반환해야 한다', () async {
      ignoringBattery = false;
      final coordinator = buildCoordinator();

      final result = await coordinator.prepareEnable();

      expect(result, isA<NeedBatteryPrompt>());
      expect(persisted, isEmpty);
    });

    test('배터리 해제 요청 후에도 활성 상태면 경고 후 활성화해야 한다', () async {
      ignoringBattery = false;
      final coordinator = buildCoordinator();

      expect(await coordinator.prepareEnable(), isA<NeedBatteryPrompt>());

      ignoringBattery = false;
      final result = await coordinator.onBatteryPromptResult(true);

      expect(result, isA<ReminderEnabled>());
      expect((result as ReminderEnabled).warnings, [
        ReminderToggleCoordinator.batteryWarningMessage,
      ]);
      expect(batteryRequestCount, 1);
      expect(persisted, [true]);
    });

    test('정확알람→배터리 순서로 두 경고를 모두 수집해야 한다', () async {
      canExact = false;
      ignoringBattery = false;
      final coordinator = buildCoordinator();

      expect(await coordinator.prepareEnable(), isA<NeedExactAlarmPrompt>());
      canExact = false;
      expect(
        await coordinator.onExactAlarmPromptResult(true),
        isA<NeedBatteryPrompt>(),
      );
      ignoringBattery = false;
      final result = await coordinator.onBatteryPromptResult(true);

      expect(result, isA<ReminderEnabled>());
      expect((result as ReminderEnabled).warnings, [
        ReminderToggleCoordinator.exactAlarmWarningMessage,
        ReminderToggleCoordinator.batteryWarningMessage,
      ]);
      expect(persisted, [true]);
    });

    test('영속화 실패 시 ReminderEnableFailed를 반환해야 한다', () async {
      final coordinator = ReminderToggleCoordinator(
        updateReminderEnabled: (_) async {
          throw StateError('persist failed');
        },
        canScheduleExactAlarms: () async => true,
        isIgnoringBatteryOptimizations: () async => true,
      );

      final result = await coordinator.setEnabled(true);

      expect(result, isA<ReminderEnableFailed>());
      expect(
        (result as ReminderEnableFailed).error,
        isA<StateError>(),
      );
    });
  });
}
