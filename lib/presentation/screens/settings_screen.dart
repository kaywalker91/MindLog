import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_strings.dart';
import '../providers/diary_list_controller.dart';
import '../providers/providers.dart';

/// 설정 화면
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                trailing: Text(
                  '1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                icon: Icons.description_outlined,
                title: '개인정보 처리방침',
                onTap: () => _launchUrl('https://example.com/privacy'),
              ),
              _buildDivider(context),
              _buildSettingItem(
                context,
                icon: Icons.gavel_outlined,
                title: '이용약관',
                onTap: () => _launchUrl('https://example.com/terms'),
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
                onTap: () => _launchUrl('mailto:support@example.com'),
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

  Widget _buildDivider(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Divider(
      height: 1,
      indent: 56,
      color: colorScheme.outline.withAlpha(51),
    );
  }

  Future<void> _launchUrl(String url) async {
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
        content: const Text(
          '정말로 모든 일기를 삭제하시겠습니까?\n\n'
          '이 작업은 되돌릴 수 없으며, 모든 감정 분석 기록도 함께 삭제됩니다.',
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
      builder: (context) => AlertDialog(
        title: const Text('도움말'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📝 일기 작성',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('하단의 "오늘 기록하기" 버튼을 눌러 오늘의 감정을 기록해보세요.'),
              SizedBox(height: 16),
              Text(
                '🤖 AI 분석',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('작성한 일기를 AI가 분석하여 감정 키워드, 공감 메시지, '
                  '추천 행동을 제공합니다.'),
              SizedBox(height: 16),
              Text(
                '📊 감정 통계',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('통계 탭에서 감정 변화 추이와 자주 느낀 감정을 확인할 수 있습니다.'),
              SizedBox(height: 16),
              Text(
                '🆘 긴급 상황',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('힘든 상황에서는 자살예방상담전화 1393으로 연락해주세요. '
                  '전문 상담사가 24시간 도움을 드립니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
