import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/update_service.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../update_badge.dart';
import '../update_prompt_dialog.dart';
import '../update_up_to_date_dialog.dart';
import 'settings_card.dart';
import 'settings_item.dart';
import 'settings_trailing.dart';
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

    _showUpdateProgressDialog(context);

    // Android: Play Store In-App Update 우선 시도
    if (Platform.isAndroid) {
      await ref.read(inAppUpdateProvider.notifier).checkForUpdate();
      final inAppState = ref.read(inAppUpdateProvider);

      if (inAppState.isUpdateAvailable) {
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        await _handleInAppUpdate(context, ref, inAppState);
        return;
      }
    }

    // Fallback: 기존 GitHub Pages 방식
    final notifier = ref.read(updateStateProvider.notifier);
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

  /// Android Play Store In-App Update 처리
  Future<void> _handleInAppUpdate(
    BuildContext context,
    WidgetRef ref,
    InAppUpdateState inAppState,
  ) async {
    final notifier = ref.read(inAppUpdateProvider.notifier);

    // 즉시 업데이트 가능 시 (필수 업데이트)
    if (inAppState.immediateAllowed) {
      await notifier.performImmediateUpdate();
      return;
    }

    // 유연 업데이트 가능 시 (선택적 업데이트)
    if (inAppState.flexibleAllowed) {
      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('새 버전이 있어요'),
          content: const Text(
            'Play Store에서 새로운 버전을 다운로드할 수 있습니다.\n'
            '백그라운드에서 다운로드하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('나중에'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('다운로드'),
            ),
          ],
        ),
      );

      if (shouldUpdate == true) {
        final success = await notifier.startFlexibleUpdate();
        if (!context.mounted) return;

        if (success) {
          // 다운로드 완료 후 설치 유도
          final installNow = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('다운로드 완료'),
              content: const Text('앱을 다시 시작하여 업데이트를 적용하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('나중에'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('지금 설치'),
                ),
              ],
            ),
          );

          if (installNow == true) {
            await notifier.completeFlexibleUpdate();
          }
        } else {
          showSnackBar(context, '다운로드에 실패했습니다. 나중에 다시 시도해주세요.');
        }
      }
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
        builder: (context) =>
            UpdateUpToDateDialog(currentVersion: result.currentVersion),
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

    final primaryLabel = canUpdate
        ? (result.isRequired ? '업데이트' : '스토어로 이동')
        : '확인';
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
        onSecondary: secondaryLabel == null
            ? null
            : () => Navigator.of(dialogContext).pop(),
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
