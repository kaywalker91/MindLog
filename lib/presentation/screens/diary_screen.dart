import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../providers/diary_analysis_controller.dart';
import '../widgets/result_card.dart';
import '../widgets/sos_card.dart';
import '../widgets/loading_indicator.dart';

/// 일기 작성 화면
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(diaryAnalysisControllerProvider.notifier)
          .analyzeDiary(_textController.text);
    }
  }

  void _onReset() {
    _textController.clear();
    ref.read(diaryAnalysisControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(diaryAnalysisControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.diaryScreenTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 분석 결과 또는 입력 폼 표시
              switch (analysisState) {
                DiaryAnalysisInitial() => _buildInputForm(),
                DiaryAnalysisLoading() => _buildLoadingState(),
                DiaryAnalysisSuccess(diary: final diary) =>
                  ResultCard(diary: diary, onNewDiary: _onReset),
                DiaryAnalysisError(failure: final failure) =>
                  _buildErrorState(failure.displayMessage),
                DiaryAnalysisSafetyBlocked() => SosCard(onClose: _onReset),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 인트로 텍스트
          Text(
            '오늘 하루는 어떠셨나요?',
            style: AppTextStyles.headline,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '마음 속 이야기를 자유롭게 적어보세요.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 텍스트 입력 필드
          TextFormField(
            controller: _textController,
            maxLines: 8,
            maxLength: AppConstants.diaryMaxLength,
            decoration: const InputDecoration(
              hintText: AppStrings.diaryHint,
              alignLabelWithHint: true,
            ),
            validator: Validators.validateDiaryContent,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // 제출 버튼
          ElevatedButton(
            onPressed: _textController.text.trim().length >=
                    AppConstants.diaryMinLength
                ? _onSubmit
                : null,
            child: const Text(AppStrings.submitButton),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const LoadingIndicator(
      message: '마음을 읽고 있어요...',
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      children: [
        Card(
          color: AppColors.error.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: AppTextStyles.body.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _onReset,
          child: const Text(AppStrings.tryAgainButton),
        ),
      ],
    );
  }
}
