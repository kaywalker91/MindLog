import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
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

/// 프리셋 카테고리
enum _PresetCategory {
  morningAffirmation('아침 다짐', Icons.wb_sunny_outlined),
  selfComfort('자기 위로', Icons.favorite_outline),
  gratitude('감사 확인', Icons.auto_awesome_outlined),
  growthAck('성장 인정', Icons.trending_up_outlined),
  pastSelf('과거의 나에서', Icons.history_outlined);

  const _PresetCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// 프리셋 템플릿 데이터
const Map<_PresetCategory, List<String>> _presetTemplates = {
  _PresetCategory.morningAffirmation: [
    '오늘 하루도 내 속도로 괜찮아',
    '작은 것부터 시작해보자',
    '오늘도 한 걸음 나아가자',
    '나는 할 수 있어, 천천히',
  ],
  _PresetCategory.selfComfort: [
    '힘들 때 쉬어가는 것도 용기야',
    '지금의 감정도 괜찮아',
    '완벽하지 않아도 충분해',
    '나 자신을 먼저 안아줘야지',
  ],
  _PresetCategory.gratitude: [
    '작은 것에도 감사할 줄 아는 내가 좋아',
    '오늘도 무사히 하루를 보낸 것에 감사',
    '내 곁에 있는 사람들이 고마워',
    '이 순간이 있어서 다행이야',
  ],
  _PresetCategory.growthAck: [
    '어제보다 나은 오늘의 나',
    '조금씩 성장하고 있어',
    '실패해도 배울 수 있었어',
    '포기하지 않은 내가 대단해',
  ],
  _PresetCategory.pastSelf: [
    '지난번 힘들었을 때도 잘 이겨냈잖아',
    '그때의 나도 충분히 용감했어',
    '과거의 나, 고마워',
    '힘든 시간을 견딘 나를 믿어',
  ],
};

class _MessageInputDialogState extends State<MessageInputDialog> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  _PresetCategory _selectedCategory = _PresetCategory.morningAffirmation;

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

            // 프리셋 템플릿 (새 메시지 작성 시에만)
            if (!widget.isEditing) ...[
              const SizedBox(height: 12),

              // 카테고리 선택 칩
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: _PresetCategory.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final category = _PresetCategory.values[index];
                    final isSelected = _selectedCategory == category;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = category);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.cheerMeAccent.withValues(alpha: 0.15)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.cheerMeAccent.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              size: 14,
                              color: isSelected
                                  ? AppColors.cheerMeAccent
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              category.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? AppColors.cheerMeAccent
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.w600 : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // 선택된 카테고리의 프리셋 메시지
              ...(_presetTemplates[_selectedCategory] ?? []).map(
                (suggestion) {
                  final isSelected = _controller.text == suggestion;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GestureDetector(
                      onTap: () => _selectSuggestion(suggestion),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.cheerMeAccent.withValues(alpha: 0.12)
                              : colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.cheerMeAccent.withValues(alpha: 0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          '"$suggestion"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? AppColors.cheerMeAccent
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
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
