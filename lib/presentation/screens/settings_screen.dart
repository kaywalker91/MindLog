import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/update_service.dart';
import '../../core/utils/responsive_utils.dart';
import '../providers/diary_list_controller.dart';
import '../providers/providers.dart';
import '../providers/app_info_provider.dart';
import '../providers/update_provider.dart';
import '../widgets/help_dialog.dart';
import '../widgets/mindlog_app_bar.dart';
import '../widgets/update_up_to_date_dialog.dart';
import '../widgets/update_prompt_dialog.dart';
import 'changelog_screen.dart';
import 'webview_screen.dart';

/// 설정 화면
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appInfoAsync = ref.watch(appInfoProvider);
    final appInfo = appInfoAsync.asData?.value;
    final versionLabel = appInfo == null
        ? (appInfoAsync.hasError ? '버전 확인 실패' : '불러오는 중...')
        : _formatVersionLabel(appInfo);

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
                onTap: () => _openWebView(
                  context,
                  url: 'https://sites.google.com/view/mindlogprivacypolicy/%ED%99%88',
                  title: '개인정보 처리방침',
                ),
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
                onTap: () => _launchExternalUrl('mailto:rikygak@gmail.com'),
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
            await _launchExternalUrl(result.storeUrl!);
          }
        },
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      indent: 56,
      color: colorScheme.outline.withAlpha(51),
    );
  }

  /// 웹뷰로 URL 열기 (앱 내에서 표시)
  void _openWebView(BuildContext context, {required String url, required String title}) {
    WebViewScreen.navigate(context, url: url, title: title);
  }

  /// 외부 앱으로 URL 열기 (이메일 등)
  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
      ref.read(diaryListControllerProvider.notifier).refresh();
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
}
