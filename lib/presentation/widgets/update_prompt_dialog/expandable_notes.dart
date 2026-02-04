import 'package:flutter/material.dart';

/// 확장 가능한 변경사항 노트 위젯
class ExpandableNotes extends StatefulWidget {
  final List<String> notes;
  final int collapsedLimit;

  const ExpandableNotes({
    super.key,
    required this.notes,
    this.collapsedLimit = 3,
  });

  @override
  State<ExpandableNotes> createState() => _ExpandableNotesState();
}

class _ExpandableNotesState extends State<ExpandableNotes> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.notes.isEmpty) {
      return Text(
        '변경사항 정보가 없습니다.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    final hasMoreNotes = widget.notes.length > widget.collapsedLimit;
    final displayNotes = _isExpanded
        ? widget.notes
        : widget.notes.take(widget.collapsedLimit).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayNotes.map(
            (note) => _buildNoteItem(note, colorScheme, theme),
          ),
          if (hasMoreNotes) _buildExpandToggle(colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String note, ColorScheme colorScheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandToggle(ColorScheme colorScheme, ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() {
        _isExpanded = !_isExpanded;
      }),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isExpanded ? '접기' : '전체 변경사항 보기 (${widget.notes.length}개)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
