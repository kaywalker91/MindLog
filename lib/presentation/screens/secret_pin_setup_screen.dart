import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../providers/providers.dart';
import '../widgets/secret/pin_keypad_widget.dart';

/// PIN 설정 화면
///
/// 2단계 플로우:
/// 1. 새 PIN 4자리 입력
/// 2. PIN 확인 (재입력)
/// 일치 시 SetSecretPinUseCase 호출 → hasPinProvider 갱신 → pop
class SecretPinSetupScreen extends ConsumerStatefulWidget {
  const SecretPinSetupScreen({super.key});

  @override
  ConsumerState<SecretPinSetupScreen> createState() =>
      _SecretPinSetupScreenState();
}

class _SecretPinSetupScreenState extends ConsumerState<SecretPinSetupScreen> {
  /// 0 = 새 PIN 입력, 1 = PIN 확인
  int _step = 0;
  String _firstPin = '';
  int _errorCount = 0;
  bool _isLoading = false;

  Future<void> _onPinCompleted(String pin) async {
    if (_step == 0) {
      // 1단계: 첫 번째 PIN 저장 후 확인 단계로 이동
      setState(() {
        _firstPin = pin;
        _step = 1;
      });
    } else {
      // 2단계: 확인 PIN과 비교
      if (pin != _firstPin) {
        setState(() => _errorCount++);
        _showMessage('PIN이 일치하지 않습니다. 다시 입력해주세요.');
        return;
      }
      await _savePin(pin);
    }
  }

  Future<void> _savePin(String pin) async {
    setState(() => _isLoading = true);
    try {
      final useCase = ref.read(setSecretPinUseCaseProvider);
      await useCase.execute(pin);
      ref.invalidate(hasPinProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        _showMessage('PIN 설정 중 오류가 발생했습니다.');
        setState(() {
          _isLoading = false;
          _step = 0;
          _firstPin = '';
          _errorCount++;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goBack() {
    if (_step == 1) {
      setState(() {
        _step = 0;
        _firstPin = '';
      });
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : _goBack,
        ),
        title: Text(
          '비밀일기 PIN 설정',
          style: AppTextStyles.appBarTitle.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.statsPrimary),
            )
          : _buildCenteredBody(colorScheme),
    );
  }

  Widget _buildCenteredBody(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final horizontalPadding = screenWidth < 360 ? 16.0 : 20.0;
        final minHeight = (constraints.maxHeight - 24)
            .clamp(0.0, double.infinity)
            .toDouble();

        return Container(
          decoration: const BoxDecoration(
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
                  child: _buildBody(colorScheme),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.statsCardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.statsPrimary.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildStepDot(0, colorScheme),
              Expanded(
                child: Container(
                  height: 2,
                  color: _step >= 1
                      ? AppColors.statsPrimary
                      : colorScheme.outlineVariant,
                ),
              ),
              _buildStepDot(1, colorScheme),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PinKeypadWidget(
          key: ValueKey(_step),
          onPinCompleted: _onPinCompleted,
          title: _step == 0 ? '새 PIN을 입력해주세요' : 'PIN을 한 번 더 입력해주세요',
          subtitle: _step == 0 ? '4자리 숫자로 비밀일기를 보호합니다' : '입력한 PIN을 확인합니다',
          errorCount: _errorCount,
        ),
      ],
    );
  }

  Widget _buildStepDot(int step, ColorScheme colorScheme) {
    final isActive = _step >= step;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? AppColors.statsPrimaryDark
            : colorScheme.outlineVariant,
      ),
      child: Center(
        child: Text(
          '${step + 1}',
          style: TextStyle(
            color: isActive
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
