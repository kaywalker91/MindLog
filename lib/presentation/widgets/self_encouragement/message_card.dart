import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/notification_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/self_encouragement_message.dart';
import '../../providers/user_name_controller.dart';

/// 개인 응원 메시지 카드 위젯
///
/// 디자인 특징:
/// - 따뜻한 그라데이션 배경 (gardenWarm 색상)
/// - 이모지 뱃지 (메시지에서 추출 또는 기본값)
/// - TappableCard 패턴 (scale + 햅틱)
/// - Dismissible 스와이프 제스처 (왼쪽: 삭제, 오른쪽: 수정)
class MessageCard extends ConsumerStatefulWidget {
  final SelfEncouragementMessage message;
  final int index;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MessageCard({
    super.key,
    required this.message,
    required this.index,
    this.onEdit,
    this.onDelete,
  });

  @override
  ConsumerState<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends ConsumerState<MessageCard> {
  bool _isPressed = false;

  /// 이모지 추출용 정규식 (static으로 한 번만 생성)
  static final _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]',
    unicode: true,
  );

  /// 메시지에서 첫 번째 이모지 추출
  String _extractEmoji(String text) {
    final match = _emojiRegex.firstMatch(text);
    return match?.group(0) ?? '💝';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final userName = ref.watch(userNameProvider).valueOrNull;
    final personalizedContent = NotificationMessages.applyNamePersonalization(
      widget.message.content,
      userName,
    );
    final emoji = _extractEmoji(personalizedContent);
    final cardGradientColors = isDark
        ? [colorScheme.surfaceContainerHigh, colorScheme.surfaceContainerLow]
        : [AppColors.gardenWarm1, AppColors.gardenWarm2.withValues(alpha: 0.7)];
    final cardBorderColor = isDark
        ? colorScheme.outlineVariant.withValues(alpha: 0.7)
        : AppColors.gardenWarm3.withValues(alpha: 0.5);
    final metaTextColor = colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child:
          Dismissible(
                key: ValueKey('dismissible_${widget.message.id}'),
                direction: DismissDirection.horizontal,
                // 왼쪽 스와이프 배경 (삭제)
                background: _buildSwipeBackground(
                  alignment: Alignment.centerLeft,
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  icon: Icons.edit_outlined,
                  label: '수정',
                ),
                // 오른쪽 스와이프 배경 (삭제)
                secondaryBackground: _buildSwipeBackground(
                  alignment: Alignment.centerRight,
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                  icon: Icons.delete_outlined,
                  label: '삭제',
                ),
                confirmDismiss: (direction) async {
                  await HapticFeedback.mediumImpact();
                  if (direction == DismissDirection.startToEnd) {
                    // 오른쪽으로 스와이프 → 수정
                    widget.onEdit?.call();
                    return false; // 원위치로 복귀
                  } else {
                    // 왼쪽으로 스와이프 → 삭제 확인
                    if (!context.mounted) return false;
                    return await _confirmDelete(context);
                  }
                },
                onDismissed: (_) {
                  widget.onDelete?.call();
                },
                child: GestureDetector(
                  onTapDown: (_) {
                    HapticFeedback.lightImpact();
                    setState(() => _isPressed = true);
                  },
                  onTapUp: (_) {
                    setState(() => _isPressed = false);
                    widget.onEdit?.call();
                  },
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: AnimatedScale(
                    scale: _isPressed ? 0.97 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(
                              alpha: _isPressed ? 0.02 : 0.05,
                            ),
                            blurRadius: _isPressed ? 4 : 8,
                            offset: Offset(0, _isPressed ? 2 : 4),
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: cardGradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cardBorderColor),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // 드래그 핸들 (순서 변경용)
                                ReorderableDragStartListener(
                                  index: widget.message.displayOrder,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: metaTextColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 이모지 뱃지
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.shadow.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 메시지 내용
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        personalizedContent,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface,
                                            ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_outlined,
                                            size: 14,
                                            color: metaTextColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(
                                              widget.message.createdAt,
                                            ),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: metaTextColor,
                                                ),
                                          ),
                                          if (widget.message.timeCategory !=
                                              null) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              _timeCategoryIcon(
                                                widget.message.timeCategory!,
                                              ),
                                              size: 14,
                                              color: metaTextColor,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              _timeCategoryLabel(
                                                widget.message.timeCategory!,
                                              ),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: metaTextColor,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // 더보기 힌트
                                Icon(
                                  Icons.chevron_right,
                                  color: metaTextColor.withValues(alpha: 0.5),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 50 * widget.index),
                duration: 400.ms,
              )
              .slideX(
                begin: 0.1,
                delay: Duration(milliseconds: 50 * widget.index),
                duration: 400.ms,
                curve: Curves.easeOutCubic,
              ),
    );
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color backgroundColor,
    required Color foregroundColor,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerRight
            ? [
                Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: foregroundColor),
              ]
            : [
                Icon(icon, color: foregroundColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('메시지 삭제'),
          content: const Text('이 응원 메시지를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  static IconData _timeCategoryIcon(String category) {
    return switch (category) {
      'morning' => Icons.wb_sunny_outlined,
      'afternoon' => Icons.wb_cloudy_outlined,
      'evening' => Icons.nightlight_outlined,
      _ => Icons.schedule_outlined,
    };
  }

  static String _timeCategoryLabel(String category) {
    return switch (category) {
      'morning' => '아침',
      'afternoon' => '오후',
      'evening' => '저녁',
      _ => category,
    };
  }

  /// 날짜 포맷팅 (static 헬퍼로 now 계산 최소화)
  static String _formatDate(DateTime date) {
    return _DateFormatter.format(date);
  }
}

/// 날짜 포맷팅 헬퍼 (리빌드마다 DateTime.now() 재계산 방지)
class _DateFormatter {
  static DateTime? _cachedNow;
  static int? _cachedNowDay;

  static String format(DateTime date) {
    final now = DateTime.now();
    // 같은 날 내에서는 캐시된 now 사용
    if (_cachedNow == null || _cachedNowDay != now.day) {
      _cachedNow = now;
      _cachedNowDay = now.day;
    }

    final diff = _cachedNow!.difference(date);

    if (diff.inDays == 0) {
      return '오늘 작성';
    } else if (diff.inDays == 1) {
      return '어제 작성';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전 작성';
    } else {
      return '${date.month}월 ${date.day}일 작성';
    }
  }
}
