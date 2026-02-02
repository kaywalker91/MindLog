import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/notification_permission_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/notification_settings.dart';
import '../../providers/providers.dart';
import '../mindcare_welcome_dialog.dart';
import 'permission_dialogs.dart';
import 'settings_card.dart';
import 'settings_item.dart';
import 'settings_trailing.dart';
import 'settings_utils.dart';

/// 알림 섹션
class NotificationSection extends ConsumerWidget {
  const NotificationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notificationSettingsAsync = ref.watch(notificationSettingsProvider);
    final notificationSettings =
        notificationSettingsAsync.valueOrNull ?? NotificationSettings.defaults();
    final notificationsReady = !notificationSettingsAsync.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: '알림'),
        SettingsCard(
          children: [
            SettingsToggleItem(
              icon: Icons.notifications_active_outlined,
              title: '일기 리마인더',
              subtitle: '매일 지정한 시간에 일기 작성을 알려드려요.',
              value: notificationSettings.isReminderEnabled,
              enabled: notificationsReady,
              onChanged: (value) {
                unawaited(_handleReminderToggle(context, ref, value));
              },
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.schedule_outlined,
              title: '리마인더 시간',
              titleColor: notificationSettings.isReminderEnabled
                  ? null
                  : colorScheme.outline,
              trailing: TimeTrailing(
                label: formatTimeLabel(
                  context,
                  notificationSettings.reminderHour,
                  notificationSettings.reminderMinute,
                ),
                enabled: notificationSettings.isReminderEnabled,
              ),
              onTap: (!notificationSettings.isReminderEnabled || !notificationsReady)
                  ? null
                  : () => _pickReminderTime(context, ref, notificationSettings),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.send_outlined,
              title: '테스트 알림 보내기',
              titleColor: notificationsReady ? null : colorScheme.outline,
              trailing: Icon(
                Icons.chevron_right,
                color: notificationsReady
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.outline,
              ),
              onTap: notificationsReady
                  ? () => _sendTestNotification(context)
                  : null,
            ),
            const SettingsDivider(),
            SettingsToggleItem(
              icon: Icons.favorite_border,
              title: '마음 케어 알림',
              subtitle: '매일 저녁 9시에 하루 마무리 메시지를 받아요.',
              value: notificationSettings.isMindcareTopicEnabled,
              enabled: notificationsReady,
              onChanged: (value) {
                unawaited(_handleMindcareToggle(context, ref, value));
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleReminderToggle(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (!enabled) {
      await ref
          .read(notificationSettingsProvider.notifier)
          .updateReminderEnabled(false);
      return;
    }

    final canScheduleExact =
        await NotificationPermissionService.canScheduleExactAlarms();

    if (!canScheduleExact && context.mounted) {
      final shouldContinue = await ExactAlarmPermissionDialog.show(context);

      if (shouldContinue == true) {
        await NotificationPermissionService.requestExactAlarmPermission();
        await NotificationPermissionService.markExactAlarmPrompted();

        if (context.mounted) {
          final nowCanSchedule =
              await NotificationPermissionService.canScheduleExactAlarms();
          if (!nowCanSchedule && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('알람이 정확한 시간에 울리지 않을 수 있습니다.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
    }

    if (context.mounted) {
      final isIgnoringBattery =
          await NotificationPermissionService.isIgnoringBatteryOptimizations();

      if (!isIgnoringBattery && context.mounted) {
        final shouldDisable = await BatteryOptimizationDialog.show(context);

        if (shouldDisable == true && context.mounted) {
          await NotificationPermissionService.requestDisableBatteryOptimization();

          if (context.mounted) {
            final nowIgnoring =
                await NotificationPermissionService.isIgnoringBatteryOptimizations();
            if (!nowIgnoring && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '배터리 최적화가 활성화되어 있어 알람이 전달되지 않을 수 있습니다.',
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        }
      }
    }

    if (context.mounted) {
      await ref
          .read(notificationSettingsProvider.notifier)
          .updateReminderEnabled(true);
    }
  }

  Future<void> _handleMindcareToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    await ref
        .read(notificationSettingsProvider.notifier)
        .updateMindcareTopicEnabled(value);

    if (value) {
      unawaited(AnalyticsService.logMindcareEnabled());
    } else {
      unawaited(AnalyticsService.logMindcareDisabled());
    }

    if (!context.mounted) return;

    if (value) {
      final prefs = await SharedPreferences.getInstance();
      final hasShownWelcome =
          prefs.getBool('mindcare_first_activation_shown') ?? false;

      if (!hasShownWelcome) {
        await prefs.setBool('mindcare_first_activation_shown', true);
        if (context.mounted) {
          await MindcareWelcomeDialog.show(context);
        }
      } else {
        if (context.mounted) {
          showSnackBar(context, '마음 케어 알림이 켜졌어요');
        }
      }
    } else {
      showSnackBar(context, '마음 케어 알림을 껐어요');
    }
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) async {
    final initialTime = TimeOfDay(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) return;
    await ref.read(notificationSettingsProvider.notifier).updateReminderTime(
          hour: picked.hour,
          minute: picked.minute,
        );
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    try {
      await NotificationService.showTestNotification();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('테스트 알림을 보냈습니다. 알림이 표시되는지 확인해주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 전송 실패: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
