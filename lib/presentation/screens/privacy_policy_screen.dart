import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../widgets/mindlog_app_bar.dart';

/// 개인정보 처리방침 화면
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String? _markdownContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMarkdownContent();
  }

  Future<void> _loadMarkdownContent() async {
    try {
      final content = await rootBundle.loadString(
        'docs/legal/privacy-policy.md',
      );
      if (mounted) {
        setState(() {
          _markdownContent = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '개인정보 처리방침을 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: const MindlogAppBar(title: Text('개인정보 처리방침')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState(context);
    }

    return ListView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: ResponsiveUtils.bottomSafeAreaPadding(context, extra: 32),
      ),
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildContentCard(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final headerFg = colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.statsPrimary, AppColors.statsSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: headerFg.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shield_outlined, color: headerFg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MindLog 개인정보 처리방침',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: headerFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: headerFg.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '시행일: 2025년 12월 18일',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: headerFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: MarkdownBody(
        data: _processMarkdownContent(_markdownContent ?? ''),
        styleSheet: _buildMarkdownStyleSheet(context),
        onTapLink: _handleLinkTap,
      ),
    );
  }

  /// Markdown 콘텐츠에서 최상위 제목 제거 (헤더에서 이미 표시)
  String _processMarkdownContent(String content) {
    // 첫 번째 H1 제목 라인 제거
    final lines = content.split('\n');
    final filteredLines = <String>[];
    bool skippedFirstH1 = false;

    for (final line in lines) {
      if (!skippedFirstH1 && line.startsWith('# ') && !line.startsWith('## ')) {
        skippedFirstH1 = true;
        continue;
      }
      filteredLines.add(line);
    }

    return filteredLines.join('\n').trim();
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MarkdownStyleSheet(
      // 제목 스타일
      h2: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
        height: 1.4,
      ),
      h2Padding: const EdgeInsets.only(top: 20, bottom: 8),
      h3: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontSize: 14,
        height: 1.4,
      ),
      h3Padding: const EdgeInsets.only(top: 12, bottom: 6),
      // 본문 스타일
      p: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.6,
      ),
      pPadding: const EdgeInsets.only(bottom: 8),
      // 리스트 스타일
      listBullet: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.primary,
      ),
      listBulletPadding: const EdgeInsets.only(right: 8),
      listIndent: 16,
      // 링크 스타일
      a: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: colorScheme.primary,
      ),
      // 수평선
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      // 강조 스타일
      strong: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      em: theme.textTheme.bodySmall?.copyWith(
        fontStyle: FontStyle.italic,
        color: colorScheme.onSurfaceVariant,
      ),
      // 블록 인용
      blockquote: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
    );
  }

  Future<void> _handleLinkTap(String text, String? href, String title) async {
    if (href == null) return;

    final uri = Uri.parse(href);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('링크를 열 수 없습니다: $href')));
      }
    }
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _error ?? '오류가 발생했습니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadMarkdownContent();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
