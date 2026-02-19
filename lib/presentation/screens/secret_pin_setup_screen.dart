import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
      backgroundColor: colorScheme.surface,
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
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    return Column(
      children: [
        // 진행 단계 표시
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              _buildStepDot(0, colorScheme),
              Expanded(
                child: Container(
                  height: 2,
                  color: _step >= 1
                      ? AppColors.primary
                      : colorScheme.outlineVariant,
                ),
              ),
              _buildStepDot(1, colorScheme),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: PinKeypadWidget(
              key: ValueKey(_step),
              onPinCompleted: _onPinCompleted,
              title: _step == 0 ? '새 PIN을 입력해주세요' : 'PIN을 한 번 더 입력해주세요',
              subtitle: _step == 0 ? '4자리 숫자로 비밀일기를 보호합니다' : '입력한 PIN을 확인합니다',
              errorCount: _errorCount,
            ),
          ),
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
        color: isActive ? AppColors.primary : colorScheme.outlineVariant,
      ),
      child: Center(
        child: Text(
          '${step + 1}',
          style: TextStyle(
            color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
