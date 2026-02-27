import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/accessibility/app_accessibility.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/responsive_utils.dart';
import '../widgets/mindlog_app_bar.dart';
import '../widgets/settings/settings_sections.dart';

/// 설정 화면
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AccessibilityWrapper(
      screenTitle: '설정',
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: const MindlogAppBar(
          title: Text('설정'),
          leading: SizedBox.shrink(),
        ),
        body: ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: ResponsiveUtils.bottomSafeAreaPadding(context, extra: 32),
          ),
          children: [
            // 앱 정보 섹션
            const AppInfoSection(),
            const SizedBox(height: 24),

            // 감정 케어 섹션
            const EmotionCareSection(),
            const SizedBox(height: 24),

            // 알림 섹션
            const NotificationSection(),
            const SizedBox(height: 24),

            // 데이터 관리 섹션
            const DataManagementSection(),
            const SizedBox(height: 24),

            // 지원 섹션
            const SupportSection(),
            const SizedBox(height: 32),

            // 앱 정보 푸터
            _buildAppFooter(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAppFooter(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
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
    );
  }
}
