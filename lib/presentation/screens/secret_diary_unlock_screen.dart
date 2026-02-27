import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/app_accessibility.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../providers/providers.dart';
import '../router/app_router.dart';
import '../widgets/secret/pin_keypad_widget.dart';

/// 비밀일기 잠금 해제 화면
///
/// PIN 입력 → SecretAuthNotifier.unlock() → 성공 시 비밀일기 목록으로 이동
/// 실패 [_maxAttempts]회 → "비밀번호를 잊으셨나요?" 링크 표시
/// 초기화 → DeleteSecretPinUseCase → 홈으로
class SecretDiaryUnlockScreen extends ConsumerStatefulWidget {
  const SecretDiaryUnlockScreen({super.key});

  @override
  ConsumerState<SecretDiaryUnlockScreen> createState() =>
      _SecretDiaryUnlockScreenState();
}

class _SecretDiaryUnlockScreenState
    extends ConsumerState<SecretDiaryUnlockScreen> {
  static const int _maxAttempts = 3;
  int _failCount = 0;
  int _errorCount = 0;
  bool _isLoading = false;

  bool get _showForgotPin => _failCount >= _maxAttempts;

  Future<void> _onPinCompleted(String pin) async {
    setState(() => _isLoading = true);
    try {
      final verifyUseCase = ref.read(verifySecretPinUseCaseProvider);
      final success = await ref
          .read(secretAuthProvider.notifier)
          .unlock(pin, verifyUseCase);

      if (!mounted) return;

      if (success) {
        context.pushReplacement(AppRoutes.secretDiaryList);
      } else {
        setState(() {
          _failCount++;
          _errorCount++;
          _isLoading = false;
        });
        _showMessage(
          _failCount >= _maxAttempts
              ? 'PIN이 일치하지 않습니다. 아래 링크를 통해 초기화할 수 있습니다.'
              : 'PIN이 일치하지 않습니다. ($_failCount/$_maxAttempts)',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorCount++;
          _isLoading = false;
        });
        _showMessage('오류가 발생했습니다. 다시 시도해주세요.');
      }
    }
  }

  void _onForgotPin() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('비밀일기 초기화'),
        content: const Text('PIN을 초기화하면 모든 비밀일기도 일반 일기로 전환됩니다.\n계속하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              ctx.pop();
              _deletePin();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePin() async {
    setState(() => _isLoading = true);
    try {
      final useCase = ref.read(deleteSecretPinUseCaseProvider);
      await useCase.execute();
      ref.invalidate(hasPinProvider);
      ref.invalidate(secretDiaryListProvider);
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('초기화 중 오류가 발생했습니다.');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AccessibilityWrapper(
      screenTitle: '비밀일기 잠금해제',
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isLoading ? null : () => context.pop(),
          ),
          title: Text(
            '비밀일기',
            style: AppTextStyles.appBarTitle.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.statsPrimary),
              )
            : _buildCenteredBody(),
      ),
    );
  }

  Widget _buildCenteredBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalPadding = screenWidth < 360 ? 16.0 : 20.0;
        final minHeight = (constraints.maxHeight - 24)
            .clamp(0.0, double.infinity)
            .toDouble();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: isDark
              ? null
              : const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF8FBFF), Color(0xFFF2F8FD)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              ResponsiveUtils.bottomSafeAreaPadding(context, extra: 12),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: PinKeypadWidget(
                    onPinCompleted: _onPinCompleted,
                    title: 'PIN을 입력해주세요',
                    errorCount: _errorCount,
                    onForgotPin: _showForgotPin ? _onForgotPin : null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
