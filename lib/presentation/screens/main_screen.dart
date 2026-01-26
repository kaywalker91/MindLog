import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../providers/app_info_provider.dart';
import '../providers/app_upgrade_check_provider.dart';
import '../providers/ui_state_providers.dart';
import '../services/notification_action_handler.dart';
import '../widgets/whats_new_dialog.dart';
import 'diary_list_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

/// 메인 화면 (BottomNavigationBar 포함)
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _notificationDialogShown = false;
  bool _whatsNewDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationActionHandler.markMainReady();
      // What's New 다이얼로그 먼저 표시, 그 다음 알림 권한 요청
      unawaited(_maybeShowWhatsNewDialog().then((_) {
        unawaited(_maybeRequestNotificationPermission());
      }));
    });
  }

  /// 앱 업그레이드 후 What's New 다이얼로그 표시
  ///
  /// - 신규 설치: 다이얼로그 표시 안 함
  /// - 동일 버전 재실행: 다이얼로그 표시 안 함
  /// - 버전 업그레이드: 한 번만 다이얼로그 표시
  Future<void> _maybeShowWhatsNewDialog() async {
    if (_whatsNewDialogShown) return;

    try {
      final appInfo = await ref.read(appInfoProvider.future);
      await ref.read(appUpgradeCheckProvider.notifier).checkForUpgrade(appInfo.version);

      final upgradeState = ref.read(appUpgradeCheckProvider);
      final data = upgradeState.valueOrNull;

      // 업그레이드가 아니거나 이미 표시됨
      if (data == null || !data.isUpgradeDetected || data.hasShownWhatsNew) {
        return;
      }

      // changelog가 비어있으면 다이얼로그 스킵하고 버전만 저장
      if (data.changelogNotes.isEmpty) {
        await ref.read(appUpgradeCheckProvider.notifier).markWhatsNewShown();
        return;
      }

      if (!mounted) return;
      _whatsNewDialogShown = true;

      await WhatsNewDialog.show(
        context,
        version: data.currentVersion,
        notes: data.changelogNotes,
        onDismiss: () {
          ref.read(appUpgradeCheckProvider.notifier).markWhatsNewShown();
          Navigator.of(context).pop();
        },
      );
    } catch (e) {
      // 에러 발생 시 silent 처리 (다이얼로그 표시 안 함)
      debugPrint('[MainScreen] What\'s New dialog error: $e');
    }
  }

  Future<void> _maybeRequestNotificationPermission() async {
    if (_notificationDialogShown) return;
    final shouldPrompt =
        await NotificationPermissionService.shouldPromptAndroidPermission();
    if (!mounted || !shouldPrompt) return;

    _notificationDialogShown = true;

    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('알림 권한 허용'),
          content: const Text(
            '일기 작성 리마인더와 마음 케어 알림을 받으려면 알림 권한이 필요해요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('나중에'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.statsPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('알림 받기'),
            ),
          ],
        );
      },
    );

    await NotificationPermissionService.markPrompted();
    if (!mounted || allow != true) return;

    final granted =
        await NotificationPermissionService.requestAndroidPermission();
    if (!mounted || granted == true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림 권한이 거부되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          DiaryListScreen(),
          StatisticsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12 : 16,
            0,
            isCompact ? 12 : 16,
            isCompact ? 8 : 12,
          ),
          child: _buildNavigationBar(
            context,
            selectedIndex: selectedIndex,
            onSelected: (index) {
              ref.read(selectedTabIndexProvider.notifier).state = index;
            },
            isCompact: isCompact,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar(
    BuildContext context, {
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    required bool isCompact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final unselectedColor =
        colorScheme.onSurface.withValues(alpha: 0.65);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            AppColors.statsBackground,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.statsPrimary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.statsPrimary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return AppTextStyles.label.copyWith(
                color: isSelected
                    ? AppColors.statsPrimaryDark
                    : unselectedColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: isSelected
                    ? AppColors.statsPrimaryDark
                    : unselectedColor,
                size: isSelected ? 26 : 24,
              );
            }),
          ),
          child: NavigationBar(
            height: isCompact ? 58 : 64,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            backgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.statsPrimary.withValues(alpha: 0.18),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.book_outlined),
                selectedIcon: Icon(Icons.book_rounded),
                label: '일기',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics_rounded),
                label: '통계',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: '설정',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
