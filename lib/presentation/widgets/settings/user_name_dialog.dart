import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

/// 사용자 이름 설정 다이얼로그
class UserNameDialog extends ConsumerStatefulWidget {
  final String? currentName;

  const UserNameDialog({super.key, this.currentName});

  /// 다이얼로그 표시 유틸리티 메서드
  static Future<void> show(BuildContext context, {String? currentName}) {
    return showDialog(
      context: context,
      builder: (context) => UserNameDialog(currentName: currentName),
    );
  }

  @override
  ConsumerState<UserNameDialog> createState() => _UserNameDialogState();
}

class _UserNameDialogState extends ConsumerState<UserNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    await ref.read(userNameProvider.notifier).setUserName(null);
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름이 초기화되었습니다.')));
    }
  }

  Future<void> _handleSave() async {
    final name = _controller.text.trim();
    await ref
        .read(userNameProvider.notifier)
        .setUserName(name.isEmpty ? null : name);
    if (mounted) {
      context.pop();
      if (name.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name님으로 설정되었습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('내 이름 설정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI 상담사가 이름을 불러드려요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: '이름을 입력하세요',
              border: const OutlineInputBorder(),
              counterText: '',
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _controller.clear(),
              ),
            ),
            maxLength: 20,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _handleReset,
          child: Text('초기화', style: TextStyle(color: colorScheme.error)),
        ),
        FilledButton(onPressed: _handleSave, child: const Text('저장')),
      ],
    );
  }
}
