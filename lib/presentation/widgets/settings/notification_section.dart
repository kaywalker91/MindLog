import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/notification_diagnostic_service.dart';
import '../../../core/services/notification_permission_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/notification_settings.dart';
import '../../../domain/entities/self_encouragement_message.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../mindcare_welcome_dialog.dart';
import 'permission_dialogs.dart';
import 'message_rotation_mode_sheet.dart';
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
        notificationSettingsAsync.valueOrNull ??
        NotificationSettings.defaults();
    final notificationsReady = !notificationSettingsAsync.isLoading;
    // PERF-004: select로 필요한 값만 watch하여 불필요한 리빌드 방지
    final messageCount = ref.watch(
      selfEncouragementProvider.select((value) => value.valueOrNull?.length ?? 0),
    );

    // 테스트 알림은 마음케어 활성화 상태에서만 발송 가능
    final testNotificationEnabled =
        notificationsReady && notificationSettings.isMindcareTopicEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: '알림'),

        // === Cheer Me 카드 (자기 응원) ===
        _AccentSettingsCard(
          accentColor: AppColors.cheerMeAccent,
          children: [
            SettingsToggleItem(
              icon: Icons.notifications_active_outlined,
              title: 'Cheer Me — 자기 응원',
              subtitle: '내가 쓴 응원 메시지로 매일 나를 다독여요',
              value: notificationSettings.isReminderEnabled,
              enabled: notificationsReady,
              onChanged: (value) {
                unawaited(_handleReminderToggle(context, ref, value));
              },
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.edit_note_outlined,
              title: '응원 메시지 관리',
              titleColor: notificationSettings.isReminderEnabled
                  ? null
                  : colorScheme.outline,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$messageCount개',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: notificationSettings.isReminderEnabled
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: notificationSettings.isReminderEnabled
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.outline,
                  ),
                ],
              ),
              onTap: notificationSettings.isReminderEnabled
                  ? () => context.pushSelfEncouragement()
                  : null,
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.shuffle_outlined,
              title: '메시지 순서',
              titleColor: notificationSettings.isReminderEnabled
                  ? null
                  : colorScheme.outline,
              trailing: ModeTrailing(
                label: _rotationModeLabel(notificationSettings.rotationMode),
                enabled: notificationSettings.isReminderEnabled,
              ),
              onTap: notificationSettings.isReminderEnabled
                  ? () => MessageRotationModeSheet.show(
                      context,
                      selected: notificationSettings.rotationMode,
                    )
                  : null,
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.schedule_outlined,
              title: '알림 시간',
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
              onTap:
                  (!notificationSettings.isReminderEnabled ||
                      !notificationsReady)
                  ? null
                  : () => _pickReminderTime(context, ref, notificationSettings),
            ),
            if (notificationSettings.isReminderEnabled) ...[
              const SettingsDivider(),
              const _NotificationDiagnosticWidget(),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // === 마음케어 카드 (전문 케어) ===
        _AccentSettingsCard(
          accentColor: AppColors.mindcareAccent,
          children: [
            SettingsToggleItem(
              icon: Icons.favorite_border,
              title: '마음케어',
              subtitle: '감정 분석 기반 전문 마음 케어를 받아보세요',
              value: notificationSettings.isMindcareTopicEnabled,
              enabled: notificationsReady,
              onChanged: (value) {
                unawaited(_handleMindcareToggle(context, ref, value));
              },
            ),
            const SettingsDivider(),
            SettingsToggleItem(
              icon: Icons.insights_outlined,
              title: '주간 감정 인사이트',
              subtitle: '매주 일요일 저녁, 한 주 감정 요약 알림',
              value: notificationSettings.isWeeklyInsightEnabled,
              enabled: notificationsReady &&
                  notificationSettings.isMindcareTopicEnabled,
              onChanged: (value) {
                ref
                    .read(notificationSettingsProvider.notifier)
                    .updateWeeklyInsightEnabled(value);
              },
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.send_outlined,
              title: '테스트 알림 보내기',
              titleColor: testNotificationEnabled ? null : colorScheme.outline,
              trailing: Icon(
                Icons.chevron_right,
                color: testNotificationEnabled
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.outline,
              ),
              onTap: testNotificationEnabled
                  ? () => _sendTestNotification(context)
                  : null,
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
                  content: Text('배터리 최적화가 활성화되어 있어 알람이 전달되지 않을 수 있습니다.'),
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
    await ref
        .read(notificationSettingsProvider.notifier)
        .updateReminderTime(hour: picked.hour, minute: picked.minute);
  }

  static String _rotationModeLabel(MessageRotationMode mode) {
    switch (mode) {
      case MessageRotationMode.random:
        return '무작위';
      case MessageRotationMode.sequential:
        return '순차';
      case MessageRotationMode.emotionAware:
        return '감정 맞춤';
    }
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

/// 알림 진단 상태 위젯
class _NotificationDiagnosticWidget extends StatefulWidget {
  const _NotificationDiagnosticWidget();

  @override
  State<_NotificationDiagnosticWidget> createState() =>
      _NotificationDiagnosticWidgetState();
}

class _NotificationDiagnosticWidgetState
    extends State<_NotificationDiagnosticWidget> {
  Future<NotificationDiagnosticData>? _diagnosticFuture;

  @override
  void initState() {
    super.initState();
    _diagnosticFuture = NotificationDiagnosticService.collect();
  }

  void _refresh() {
    setState(() {
      _diagnosticFuture = NotificationDiagnosticService.collect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<NotificationDiagnosticData>(
      future: _diagnosticFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '진단 확인 중...',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!;
        final cheerMeCount = data.pendingNotifications
            .where((n) => n.id == 1001)
            .length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    size: 16,
                    color: data.hasAnyIssue
                        ? Colors.orange
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '알림 상태',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _refresh,
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _DiagnosticRow(
                label: '예약 알림',
                value: cheerMeCount > 0
                    ? '$cheerMeCount개 (ID: 1001)'
                    : '없음',
                isWarning: cheerMeCount == 0,
              ),
              const SizedBox(height: 4),
              _DiagnosticRow(
                label: '정확한 알람',
                value: data.canScheduleExact == true ? '허용됨' : '거부됨',
                isWarning: data.hasExactAlarmIssue,
                warningText: '알림이 지연될 수 있습니다',
              ),
              const SizedBox(height: 4),
              _DiagnosticRow(
                label: '배터리 최적화',
                value: data.isIgnoringBattery ? '제외됨' : '활성화됨',
                isWarning: data.hasBatteryIssue,
                warningText: '알림이 억제될 수 있습니다',
              ),
              const SizedBox(height: 4),
              _DiagnosticRow(
                label: '시간대',
                value: data.timezoneName,
                isWarning: false,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 진단 항목 행
class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;
  final String? warningText;

  const _DiagnosticRow({
    required this.label,
    required this.value,
    required this.isWarning,
    this.warningText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor =
        isWarning ? Colors.orange : colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isWarning ? '  \u26a0\ufe0f ' : '  \u2705 ',
              style: const TextStyle(fontSize: 11),
            ),
            Text(
              '$label: ',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (isWarning && warningText != null)
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 2),
            child: Text(
              warningText!,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade700,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}

/// 좌측 accent 컬러 스트라이프가 있는 설정 카드
class _AccentSettingsCard extends StatelessWidget {
  final Color accentColor;
  final List<Widget> children;

  const _AccentSettingsCard({
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha(51),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accentColor),
              Expanded(
                child: Column(children: children),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
