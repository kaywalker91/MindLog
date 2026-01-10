import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/ai_character.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/notification_permission_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/update_service.dart';
import '../../core/utils/responsive_utils.dart';
import '../../domain/entities/notification_settings.dart';
import '../providers/ai_character_controller.dart';
import '../providers/diary_list_controller.dart';
import '../providers/providers.dart';
import '../providers/app_info_provider.dart';
import '../providers/notification_settings_controller.dart';
import '../providers/update_provider.dart';
import '../widgets/help_dialog.dart';
import '../widgets/mindcare_welcome_dialog.dart';
import '../widgets/mindlog_app_bar.dart';
import '../widgets/update_up_to_date_dialog.dart';
import '../widgets/update_prompt_dialog.dart';
import 'changelog_screen.dart';
import 'privacy_policy_screen.dart';

/// 설정 화면
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appInfoAsync = ref.watch(appInfoProvider);
    final appInfo = appInfoAsync.asData?.value;
    final characterAsync = ref.watch(aiCharacterProvider);
    final selectedCharacter =
        characterAsync.valueOrNull ?? AiCharacter.warmCounselor;
    final notificationSettingsAsync = ref.watch(notificationSettingsProvider);
    final notificationSettings =
        notificationSettingsAsync.valueOrNull ?? NotificationSettings.defaults();
    final notificationsReady = !notificationSettingsAsync.isLoading;
    final userNameAsync = ref.watch(userNameProvider);
    final userName = userNameAsync.valueOrNull;
    final versionLabel = appInfo == null
        ? (appInfoAsync.hasError ? '버전 확인 실패' : '불러오는 중...')
        : _formatVersionLabel(appInfo);
    final characterLabel = characterAsync.when(
      data: (character) => character.displayName,
      loading: () => '불러오는 중...',
      error: (_, _) => AiCharacter.warmCounselor.displayName,
    );

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: const MindlogAppBar(
        title: Text('설정'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          // 하단 시스템 바를 고려한 패딩
          bottom: ResponsiveUtils.bottomSafeAreaPadding(context, extra: 32),
        ),
        children: [
          // 앱 정보 섹션
          _buildSectionHeader(context, '앱 정보'),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingItem(
                context,
                icon: Icons.info_outline,
                title: '앱 버전',
                trailing: _buildVersionTrailing(
                  context,
                  label: versionLabel,
                  isReady: appInfo != null,
                ),
                onTap: appInfo == null
                    ? null
                    : () => ChangelogScreen.navigate(
                          context,
                          version: appInfo.version,
                          buildNumber: appInfo.buildNumber,
                        ),
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                icon: Icons.system_update,
                title: '업데이트 확인',
                onTap: () => _checkForUpdates(context, ref, appInfo),
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                icon: Icons.description_outlined,
                title: '개인정보 처리방침',
                onTap: () => PrivacyPolicyScreen.navigate(context),
              ),
              // TODO: 이용약관 URL 준비되면 주석 해제
              // _buildDivider(context),
              // _buildSettingItem(
              //   context,
              //   icon: Icons.gavel_outlined,
              //   title: '이용약관',
              //   onTap: () => _openWebView(
              //     context,
              //     url: 'https://example.com/terms',
              //     title: '이용약관',
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 24),

          // 감정 케어 섹션
          _buildSectionHeader(context, '감정 케어'),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingItem(
                context,
                icon: Icons.mood_outlined,
                title: 'AI 캐릭터',
                trailing: _buildAiCharacterTrailing(context, characterLabel),
                onTap: () => _showAiCharacterSheet(
                  context,
                  ref,
                  selectedCharacter,
                ),
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                icon: Icons.person_outline,
                title: '내 이름',
                trailing: _buildUserNameTrailing(context, userName),
                onTap: () => _showUserNameDialog(context, ref, userName),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 알림 섹션
          _buildSectionHeader(context, '알림'),
          _buildSettingsCard(
            context,
            children: [
              _buildToggleSettingItem(
                context,
                icon: Icons.notifications_active_outlined,
                title: '일기 리마인더',
                subtitle: '매일 지정한 시간에 일기 작성을 알려드려요.',
                value: notificationSettings.isReminderEnabled,
                enabled: notificationsReady,
                onChanged: (value) {
                  unawaited(
                    _handleReminderToggle(context, ref, value),
                  );
                },
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                icon: Icons.schedule_outlined,
                title: '리마인더 시간',
                titleColor: notificationSettings.isReminderEnabled
                    ? null
                    : colorScheme.outline,
                trailing: _buildTimeTrailing(
                  context,
                  label: _formatTimeLabel(
                    context,
                    notificationSettings.reminderHour,
                    notificationSettings.reminderMinute,
                  ),
                  enabled: notificationSettings.isReminderEnabled,
                ),
                onTap: (!notificationSettings.isReminderEnabled ||
                        !notificationsReady)
                    ? null
                    : () => _pickReminderTime(
                          context,
                          ref,
                          notificationSettings,
                        ),
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
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
              _buildDivider(context),
              _buildToggleSettingItem(
                context,
                icon: Icons.favorite_border,
                title: '마음 케어 알림',
                subtitle: '매일 아침 따뜻한 마음 케어 메시지를 받아요.',
                value: notificationSettings.isMindcareTopicEnabled,
                enabled: notificationsReady,
                onChanged: (value) {
                  unawaited(_handleMindcareToggle(context, ref, value));
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 데이터 관리 섹션
          _buildSectionHeader(context, '데이터 관리'),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingItem(
                context,
                icon: Icons.delete_outline,
                title: '모든 일기 삭제',
                titleColor: colorScheme.error,
                onTap: () => _showDeleteAllDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 지원 섹션
          _buildSectionHeader(context, '지원'),
          _buildSettingsCard(
            context,
            children: [
              _buildSettingItem(
                context,
                icon: Icons.help_outline,
                title: '도움말',
                onTap: () => _showHelpDialog(context),
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                icon: Icons.email_outlined,
                title: '문의하기',
                onTap: () => _launchExternalUrl('mailto:rikygak@gmail.com', context),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 앱 정보 푸터
          Center(
            child: Column(
              children: [
                Text(
                  AppStrings.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI 기반 감정 케어 다이어리',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Made with ❤️ for your mental health',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withAlpha(51), // 0.2 * 255 ≈ 51
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: titleColor ?? colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: titleColor ?? colorScheme.onSurface,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.outline,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiCharacterTrailing(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right,
          color: colorScheme.outline,
        ),
      ],
    );
  }

  Widget _buildUserNameTrailing(BuildContext context, String? userName) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = userName ?? '설정 안 함';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: userName != null
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right,
          color: colorScheme.outline,
        ),
      ],
    );
  }

  void _showUserNameDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentName,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('내 이름 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI 상담사가 이름을 불러드려요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '이름을 입력하세요',
                border: const OutlineInputBorder(),
                counterText: '',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => controller.clear(),
                ),
              ),
              maxLength: 20,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(userNameProvider.notifier).setUserName(null);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이름이 초기화되었습니다.')),
                );
              }
            },
            child: Text(
              '초기화',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              await ref.read(userNameProvider.notifier).setUserName(
                    name.isEmpty ? null : name,
                  );
              if (context.mounted) {
                Navigator.of(context).pop();
                if (name.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name님으로 설정되었습니다.')),
                  );
                }
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = enabled ? colorScheme.onSurface : colorScheme.outline;
    final subtitleColor =
        enabled ? colorScheme.onSurfaceVariant : colorScheme.outline;

    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: enabled ? colorScheme.onSurfaceVariant : colorScheme.outline,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTrailing(
    BuildContext context, {
    required String label,
    required bool enabled,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = enabled ? colorScheme.onSurfaceVariant : colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (enabled) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: colorScheme.outline,
          ),
        ],
      ],
    );
  }

  Widget _buildCharacterThumbnail(AiCharacter character) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        character.imagePath,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 44,
            height: 44,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.image_not_supported_outlined, size: 20),
          );
        },
      ),
    );
  }

  void _showAiCharacterSheet(
    BuildContext context,
    WidgetRef ref,
    AiCharacter selected,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Text(
                  'AI 캐릭터 선택',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // RadioGroup으로 감싸서 groupValue/onChanged 대체 (Flutter 3.32+)
                RadioGroup<AiCharacter>(
                  groupValue: selected,
                  onChanged: (value) async {
                    if (value == null) return;
                    if (value != selected) {
                      unawaited(AnalyticsService.logAiCharacterChanged(
                        fromCharacterId: selected.id,
                        toCharacterId: value.id,
                      ));
                    }
                    await ref
                        .read(aiCharacterProvider.notifier)
                        .setCharacter(value);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: AiCharacter.values.map(
                      (character) => RadioListTile<AiCharacter>(
                        value: character,
                        secondary: _buildCharacterThumbnail(character),
                        controlAffinity: ListTileControlAffinity.trailing,
                        title: Text(
                          character.displayName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          character.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        activeColor: theme.colorScheme.primary,
                      ),
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatVersionLabel(AppVersionInfo info) {
    final build = info.buildNumber.trim();
    if (build.isEmpty) {
      return 'v${info.version}';
    }
    return 'v${info.version} ($build)';
  }

  Widget _buildVersionTrailing(
    BuildContext context, {
    required String label,
    required bool isReady,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!isReady) {
      return Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.chevron_right,
          color: colorScheme.outline,
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
      _showSnackBar(context, '버전 정보를 불러오는 중입니다.');
      return;
    }

    final updateService = ref.read(updateServiceProvider);
    _showUpdateProgressDialog(context);

    late final UpdateCheckResult result;
    try {
      result = await updateService.checkForUpdate(
        currentVersion: appInfo.version,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBar(context, '업데이트 정보를 가져오지 못했습니다.');
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    await _showUpdateResultDialog(context, result);
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

    final primaryLabel = canUpdate ? (result.isRequired ? '업데이트' : '스토어로 이동') : '확인';
    final secondaryLabel = canUpdate && !result.isRequired ? '나중에' : null;

    return showDialog(
      context: context,
      barrierDismissible: !(result.isRequired && canUpdate),
      builder: (context) => UpdatePromptDialog(
        isRequired: result.isRequired,
        title: title,
        message: message,
        notes: result.notes,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        onSecondary: secondaryLabel == null ? null : () => Navigator.of(context).pop(),
        onPrimary: () async {
          Navigator.of(context).pop();
          if (canUpdate) {
            await _launchExternalUrl(result.storeUrl!, context);
          }
        },
      ),
    );
  }

  String _formatTimeLabel(
    BuildContext context,
    int hour,
    int minute,
  ) {
    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    return MaterialLocalizations.of(context).formatTimeOfDay(timeOfDay);
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

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 마음 케어 알림 토글 핸들러
  Future<void> _handleMindcareToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    // FCM 토픽 구독/해제 처리
    await ref
        .read(notificationSettingsProvider.notifier)
        .updateMindcareTopicEnabled(value);

    // Analytics 이벤트 (fire-and-forget)
    if (value) {
      unawaited(AnalyticsService.logMindcareEnabled());
    } else {
      unawaited(AnalyticsService.logMindcareDisabled());
    }

    if (!context.mounted) return;

    if (value) {
      // 활성화: 첫 활성화인지 확인
      final prefs = await SharedPreferences.getInstance();
      final hasShownWelcome =
          prefs.getBool('mindcare_first_activation_shown') ?? false;

      if (!hasShownWelcome) {
        // 첫 활성화: 환영 다이얼로그 표시
        await prefs.setBool('mindcare_first_activation_shown', true);
        if (context.mounted) {
          await MindcareWelcomeDialog.show(context);
        }
      } else {
        // 재활성화: SnackBar 피드백
        if (context.mounted) {
          _showSnackBar(context, '마음 케어 알림이 켜졌어요');
        }
      }
    } else {
      // 비활성화: SnackBar 피드백
      _showSnackBar(context, '마음 케어 알림을 껐어요');
    }
  }

  Widget _buildDivider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      indent: 56,
      color: colorScheme.outline.withAlpha(51),
    );
  }

  /// 외부 앱으로 URL 열기 (이메일, Play Store 등)
  ///
  /// [LaunchMode.externalApplication]을 사용하여 Play Store URL이
  /// 인앱 브라우저가 아닌 Play Store 앱으로 직접 열리도록 합니다.
  Future<bool> _launchExternalUrl(String url, [BuildContext? context]) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
      return launched;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('링크 열기 실패: $e')),
        );
      }
      return false;
    }
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
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

      // 목록 새로고침
      await ref.read(diaryListControllerProvider.notifier).refresh();
      // 통계 새로고침
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HelpDialog(),
    );
  }

  /// 리마인더 토글 핸들러
  ///
  /// 리마인더를 활성화할 때:
  /// 1. Android 12+ 기기에서 정확한 알람 권한을 확인
  /// 2. 배터리 최적화 상태를 확인하고 제외 요청
  Future<void> _handleReminderToggle(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    // 리마인더 비활성화 시 바로 처리
    if (!enabled) {
      await ref
          .read(notificationSettingsProvider.notifier)
          .updateReminderEnabled(false);
      return;
    }

    // 1. 정확한 알람 권한 확인 (Android 12+)
    final canScheduleExact =
        await NotificationPermissionService.canScheduleExactAlarms();

    if (!canScheduleExact && context.mounted) {
      // 권한이 없으면 안내 다이얼로그 표시
      final shouldContinue = await _showExactAlarmPermissionDialog(context);

      if (shouldContinue == true) {
        // 설정 화면으로 이동
        await NotificationPermissionService.requestExactAlarmPermission();
        await NotificationPermissionService.markExactAlarmPrompted();

        // 설정 화면에서 돌아온 후 권한 재확인
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

    // 2. 배터리 최적화 상태 확인
    if (context.mounted) {
      final isIgnoringBattery =
          await NotificationPermissionService.isIgnoringBatteryOptimizations();

      if (!isIgnoringBattery && context.mounted) {
        // 배터리 최적화 대상이면 안내 다이얼로그 표시
        final shouldDisable =
            await _showBatteryOptimizationDialog(context);

        if (shouldDisable == true && context.mounted) {
          // 시스템 다이얼로그로 배터리 최적화 비활성화 요청
          await NotificationPermissionService
              .requestDisableBatteryOptimization();

          // 재확인 후 안내
          if (context.mounted) {
            final nowIgnoring = await NotificationPermissionService
                .isIgnoringBatteryOptimizations();
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

    // 리마인더 활성화 진행
    if (context.mounted) {
      await ref
          .read(notificationSettingsProvider.notifier)
          .updateReminderEnabled(true);
    }
  }

  /// 정확한 알람 권한 안내 다이얼로그
  Future<bool?> _showExactAlarmPermissionDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.alarm_outlined, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text('정확한 알람 권한 필요'),
            ),
          ],
        ),
        content: const Text(
          '리마인더가 정확한 시간에 울리려면 "알람 및 리마인더" 권한이 필요합니다.\n\n'
          '설정에서 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  /// 테스트 알림 보내기
  ///
  /// 알림이 제대로 작동하는지 확인하기 위해 즉시 알림을 보냅니다.
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

  /// 배터리 최적화 안내 다이얼로그
  ///
  /// 배터리 최적화가 활성화되어 있으면 알람이 시스템에 의해 억제될 수 있음을 안내합니다.
  Future<bool?> _showBatteryOptimizationDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.battery_alert_outlined, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text('배터리 최적화 설정'),
            ),
          ],
        ),
        content: const Text(
          '리마인더 알림이 정확히 전달되려면 배터리 최적화에서 이 앱을 제외해야 합니다.\n\n'
          '배터리 최적화가 활성화되면 시스템이 알람을 지연시키거나 전달하지 않을 수 있습니다.\n\n'
          '"허용"을 선택하여 배터리 최적화를 비활성화해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
            child: const Text('허용'),
          ),
        ],
      ),
    );
  }
}
