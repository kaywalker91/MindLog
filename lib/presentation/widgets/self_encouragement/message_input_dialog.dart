import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/self_encouragement_message.dart';

/// 응원 메시지 입력 바텀시트
///
/// 새 메시지 작성 시 가로 스크롤 추천 칩 표시,
/// 수정 모드에서는 입력 필드만 표시
class MessageInputDialog extends StatefulWidget {
  final String? initialValue;
  final bool isEditing;

  const MessageInputDialog({
    super.key,
    this.initialValue,
    this.isEditing = false,
  });

  /// 바텀시트 표시
  ///
  /// Returns: 입력된 메시지 또는 null (취소 시)
  static Future<String?> show(
    BuildContext context, {
    String? initialValue,
    bool isEditing = false,
  }) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: MessageInputDialog(
            initialValue: initialValue,
            isEditing: isEditing,
          ),
        ),
      ),
    );
  }

  @override
  State<MessageInputDialog> createState() => _MessageInputDialogState();
}

class _MessageInputDialogState extends State<MessageInputDialog> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  /// 추천 예시 메시지
  static const List<String> _suggestions = [
    '오늘도 힘내자! 💪',
    '나는 충분히 잘하고 있어',
    '한 걸음씩 나아가자',
    '힘들 때일수록 더 빛나는 나',
    '오늘 하루도 수고했어',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    // 바텀시트가 열리면 자동으로 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectSuggestion(String suggestion) {
    HapticFeedback.selectionClick();
    setState(() {
      _controller.text = suggestion;
      // 커서를 끝으로 이동
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: suggestion.length),
      );
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const maxLength = SelfEncouragementMessage.maxContentLength;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 타이틀
            Text(
              widget.isEditing ? '메시지 수정' : '응원 메시지 작성',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // TextField
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLength: maxLength,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '나에게 보내고 싶은 한마디를 작성해주세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // 글자 수 카운터
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_controller.text.length}/$maxLength',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _controller.text.length > maxLength
                      ? colorScheme.error
                      : colorScheme.outline,
                ),
              ),
            ),

            // 추천 칩 (새 메시지 작성 시에만)
            if (!widget.isEditing) ...[
              const SizedBox(height: 12),
              Text(
                '💡 탭해서 입력',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // 가로 스크롤 칩 with ShaderMask 그라데이션
              SizedBox(
                height: 36,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        colorScheme.surface,
                        colorScheme.surface,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.02, 0.95, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final suggestion = _suggestions[index];
                      final isSelected = _controller.text == suggestion;

                      return GestureDetector(
                        onTap: () => _selectSuggestion(suggestion),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.5)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            suggestion,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '최대 ${SelfEncouragementMessage.maxMessageCount}개까지 등록 가능',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 버튼 Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _controller.text.trim().isEmpty
                        ? null
                        : () => Navigator.pop(context, _controller.text.trim()),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(widget.isEditing ? '수정' : '저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
