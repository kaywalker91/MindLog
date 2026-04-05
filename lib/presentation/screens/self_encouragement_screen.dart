import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/accessibility/app_accessibility.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/notification_settings_service.dart';
import '../../domain/entities/self_encouragement_message.dart';
import '../providers/providers.dart';
import '../widgets/self_encouragement/empty_message_view.dart';
import '../widgets/self_encouragement/message_card.dart';
import '../widgets/self_encouragement/message_input_dialog.dart';
import '../widgets/self_encouragement/notification_preview_widget.dart';

final cheerMePreviewProvider =
    FutureProvider.autoDispose<CheerMeScheduledNotification?>((ref) async {
      final settings = await ref.watch(notificationSettingsProvider.future);
      final messages = await ref.watch(selfEncouragementProvider.future);
      final userName = await ref.watch(userNameProvider.future);
      final recentEmotionScore = ref
          .watch(todayEmotionProvider)
          .sentimentScore
          ?.toDouble();

      return NotificationSettingsService.loadNextCheerMePreview(
        settings,
        messages: messages,
        userName: userName,
        recentEmotionScore: recentEmotionScore,
      );
    });

/// 개인 응원 메시지 관리 화면
class SelfEncouragementScreen extends ConsumerWidget {
  const SelfEncouragementScreen({super.key});

  static const _hintShownKey = 'self_encouragement_hint_shown';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messagesAsync = ref.watch(selfEncouragementProvider);

    return AccessibilityWrapper(
      screenTitle: 'Cheer Me',
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Cheer Me'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: messagesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('메시지를 불러올 수 없습니다', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(selfEncouragementProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          data: (messages) =>
              _MessageList(messages: messages, hintShownKey: _hintShownKey),
        ),
        // FAB는 메시지가 1개 이상일 때만 표시 (Empty State에서는 중앙 버튼만 사용)
        floatingActionButton: messagesAsync.maybeWhen(
          data: (messages) =>
              messages.isNotEmpty &&
                  messages.length < SelfEncouragementMessage.maxMessageCount
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddDialog(context, ref),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  icon: const Icon(Icons.add),
                  label: Text('메시지 추가 (${messages.length}/10)'),
                )
              : null,
          orElse: () => null,
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await MessageInputDialog.show(context);
    if (result != null && result.content.isNotEmpty && context.mounted) {
      await HapticFeedback.mediumImpact();
      final success = await ref
          .read(selfEncouragementProvider.notifier)
          .addMessage(result.content, timeCategory: result.timeCategory);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Text('🎉'),
                SizedBox(width: 8),
                Expanded(child: Text('응원 메시지가 추가되었습니다')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _MessageList extends ConsumerStatefulWidget {
  final List<SelfEncouragementMessage> messages;
  final String hintShownKey;

  const _MessageList({required this.messages, required this.hintShownKey});

  @override
  ConsumerState<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<_MessageList> {
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _checkFirstVisit();
  }

  Future<void> _checkFirstVisit() async {
    if (widget.messages.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final hintShown = prefs.getBool(widget.hintShownKey) ?? false;

    if (!hintShown && mounted) {
      setState(() => _showHint = true);
    }
  }

  Future<void> _dismissHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.hintShownKey, true);
    if (mounted) {
      setState(() => _showHint = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final previewAsync = ref.watch(cheerMePreviewProvider);

    if (widget.messages.isEmpty) {
      return const EmptyMessageView();
    }

    return Stack(
      children: [
        Column(
          children: [
            // 알림 미리보기 (메시지 리스트 화면에서만 표시)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: previewAsync.when(
                data: (preview) => NotificationPreviewWidget(
                  previewMessage: preview?.body,
                  previewTitle: preview?.title,
                ),
                loading: () => const NotificationPreviewWidget(),
                error: (_, _) => const NotificationPreviewWidget(),
              ),
            ),

            // 스와이프 힌트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '좌우로 스와이프하여 수정/삭제',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 메시지 목록 (ReorderableListView)
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.messages.length,
                onReorder: (oldIndex, newIndex) {
                  HapticFeedback.selectionClick();
                  if (newIndex > oldIndex) newIndex--;
                  ref
                      .read(selfEncouragementProvider.notifier)
                      .reorder(oldIndex, newIndex);
                },
                onReorderStart: (_) => HapticFeedback.selectionClick(),
                onReorderEnd: (_) => HapticFeedback.selectionClick(),
                proxyDecorator: _buildDragProxy,
                itemBuilder: (context, index) {
                  final message = widget.messages[index];
                  return MessageCard(
                    key: ValueKey(message.id),
                    message: message,
                    index: index,
                    onEdit: () => _showEditDialog(context, message),
                    onDelete: () => _deleteMessage(message),
                  );
                },
              ),
            ),
          ],
        ),

        // 첫 진입 힌트 오버레이
        if (_showHint) _DragHintOverlay(onDismiss: _dismissHint),
      ],
    );
  }

  /// 드래그 중인 아이템의 데코레이터 (성능 최적화)
  ///
  /// PERF-006: Tween을 매 프레임 생성하지 않고 static으로 재사용
  static final _elevationTween = Tween<double>(begin: 0, end: 8);

  Widget _buildDragProxy(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final elevation = _elevationTween.evaluate(animation);
        return Material(
          elevation: elevation,
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
          child: child,
        );
      },
      child: child,
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    SelfEncouragementMessage message,
  ) async {
    final result = await MessageInputDialog.show(
      context,
      initialValue: message.content,
      initialTimeCategory: message.timeCategory,
      isEditing: true,
    );
    if (result != null && result.content.isNotEmpty && context.mounted) {
      final success = await ref
          .read(selfEncouragementProvider.notifier)
          .updateMessage(
            message.id,
            result.content,
            timeCategory: result.timeCategory,
          );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메시지가 수정되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(SelfEncouragementMessage message) async {
    await ref
        .read(selfEncouragementProvider.notifier)
        .deleteMessage(message.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메시지가 삭제되었습니다'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// 첫 진입 시 드래그 힌트 오버레이
class _DragHintOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const _DragHintOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: colorScheme.scrim.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 드래그 아이콘 애니메이션
                Icon(Icons.drag_handle, size: 48, color: colorScheme.primary)
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .moveY(begin: -5, end: 5, duration: 800.ms),
                const SizedBox(height: 16),
                Text(
                  '드래그해서 순서를 바꿔보세요',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '왼쪽의 ≡ 핸들을 잡고\n위아래로 드래그하면 순서가 바뀌어요',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swipe, size: 16, color: colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      '좌우 스와이프로 수정/삭제도 가능해요',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: onDismiss, child: const Text('알겠어요')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
