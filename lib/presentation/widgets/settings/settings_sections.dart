import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/ai_character.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/notification_permission_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/update_service.dart';
import '../../../domain/entities/notification_settings.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../help_dialog.dart';
import '../mindcare_welcome_dialog.dart';
import '../update_badge.dart';
import '../update_prompt_dialog.dart';
import '../update_up_to_date_dialog.dart';
import 'ai_character_sheet.dart';
import 'permission_dialogs.dart';
import 'settings_card.dart';
import 'settings_item.dart';
import 'settings_trailing.dart';
import 'user_name_dialog.dart';
import 'settings_utils.dart';

/// 앱 정보 섹션
class AppInfoSection extends ConsumerWidget {
  const AppInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfoAsync = ref.watch(appInfoProvider);
    final appInfo = appInfoAsync.asData?.value;
    final versionLabel = appInfo == null
        ? (appInfoAsync.hasError ? '버전 확인 실패' : '불러오는 중...')
        : formatVersionLabel(appInfo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: '앱 정보'),
        SettingsCard(
          children: [
            SettingsItem(
              icon: Icons.info_outline,
              title: '앱 버전',
              trailing: VersionTrailing(
                label: versionLabel,
                isReady: appInfo != null,
              ),
              onTap: appInfo == null
                  ? null
                  : () => context.pushChangelog(
                        version: appInfo.version,
                        buildNumber: appInfo.buildNumber,
                      ),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.system_update,
              title: '업데이트 확인',
              trailing: const UpdateBadge(),
              onTap: () => _checkForUpdates(context, ref, appInfo),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.description_outlined,
              title: '개인정보 처리방침',
              onTap: () => context.pushPrivacyPolicy(),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _checkForUpdates(
    BuildContext context,
    WidgetRef ref,
    AppVersionInfo? appInfo,
  ) async {
    if (appInfo == null) {
      showSnackBar(context, '버전 정보를 불러오는 중입니다.');
      return;
    }

    final notifier = ref.read(updateStateProvider.notifier);

    _showUpdateProgressDialog(context);
    await notifier.clearDismissal();
    await notifier.check(appInfo.version);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final state = ref.read(updateStateProvider);
    if (state.result != null) {
      await _showUpdateResultDialog(context, ref, state.result!);
    } else {
      showSnackBar(context, '업데이트 정보를 가져오지 못했습니다.');
    }
  }

  void _showUpdateProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text('업데이트 확인 중...'),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdateResultDialog(
    BuildContext context,
    WidgetRef ref,
    UpdateCheckResult result,
  ) {
    final canUpdate = result.storeUrl != null && result.storeUrl!.isNotEmpty;

    if (result.availability == UpdateAvailability.upToDate) {
      return showDialog(
        context: context,
        builder: (context) => UpdateUpToDateDialog(
          currentVersion: result.currentVersion,
        ),
      );
    }

    String title;
    String message;
    if (result.isRequired) {
      title = '업데이트가 필요합니다';
      message = '현재 버전이 지원 범위를 벗어났습니다. 업데이트 후 이용해주세요.';
    } else {
      title = '새 버전이 있어요';
      message = 'v${result.latestVersion} 업데이트를 확인해주세요.';
    }

    final primaryLabel =
        canUpdate ? (result.isRequired ? '업데이트' : '스토어로 이동') : '확인';
    final secondaryLabel = canUpdate && !result.isRequired ? '나중에' : null;

    return showDialog(
      context: context,
      barrierDismissible: !(result.isRequired && canUpdate),
      builder: (dialogContext) => UpdatePromptDialog(
        isRequired: result.isRequired,
        title: title,
        message: message,
        currentVersion: result.currentVersion,
        latestVersion: result.latestVersion,
        notes: result.notes,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        onSecondary:
            secondaryLabel == null ? null : () => Navigator.of(dialogContext).pop(),
        onPrimary: () async {
          Navigator.of(dialogContext).pop();
          if (canUpdate) {
            await launchExternalUrl(result.storeUrl!, context);
          }
        },
        onRemindLater: result.isRequired
            ? null
            : () async {
                await ref.read(updateStateProvider.notifier).dismiss();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
      ),
    );
  }
}

/// 감정 케어 섹션
class EmotionCareSection extends ConsumerWidget {
  const EmotionCareSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterAsync = ref.watch(aiCharacterProvider);
    final selectedCharacter =
        characterAsync.valueOrNull ?? AiCharacter.warmCounselor;
    final userNameAsync = ref.watch(userNameProvider);
    final userName = userNameAsync.valueOrNull;

    final characterLabel = characterAsync.when(
      data: (character) => character.displayName,
      loading: () => '불러오는 중...',
      error: (_, _) => AiCharacter.warmCounselor.displayName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: '감정 케어'),
        SettingsCard(
          children: [
            SettingsItem(
              icon: Icons.mood_outlined,
              title: 'AI 캐릭터',
              trailing: AiCharacterTrailing(label: characterLabel),
              onTap: () => AiCharacterSheet.show(
                context,
                selected: selectedCharacter,
              ),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.person_outline,
              title: '내 이름',
              trailing: UserNameTrailing(userName: userName),
              onTap: () => UserNameDialog.show(context, currentName: userName),
            ),
          ],
        ),
      ],
    );
  }
}

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

/// 데이터 관리 섹션
class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: '데이터 관리'),
        SettingsCard(
          children: [
            SettingsItem(
              icon: Icons.delete_outline,
              title: '모든 일기 삭제',
              titleColor: colorScheme.error,
              onTap: () => _showDeleteAllDialog(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteAllDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error),
            const SizedBox(width: 8),
            const Text('모든 일기 삭제'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            '정말로 모든 일기를 삭제하시겠습니까?\n\n'
            '이 작업은 되돌릴 수 없으며, 모든 감정 분석 기록도 함께 삭제됩니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              context.pop();
              await _deleteAllDiaries(context, ref);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllDiaries(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(diaryRepositoryProvider);
      await repository.deleteAllDiaries();

      await ref.read(diaryListControllerProvider.notifier).refresh();
      ref.invalidate(statisticsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 일기가 삭제되었습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
}

/// 지원 섹션
class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: '지원'),
        SettingsCard(
          children: [
            SettingsItem(
              icon: Icons.help_outline,
              title: '도움말',
              onTap: () => _showHelpDialog(context),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.email_outlined,
              title: '문의하기',
              onTap: () => launchExternalUrl('mailto:rikygak@gmail.com', context),
            ),
          ],
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HelpDialog(),
    );
  }
}
