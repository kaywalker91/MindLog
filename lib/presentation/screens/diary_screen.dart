import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/validators.dart';
import '../providers/diary_analysis_controller.dart';
import '../providers/diary_list_controller.dart';
import '../widgets/result_card.dart';
import '../widgets/sos_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/mindlog_app_bar.dart';
import '../widgets/network_status_overlay.dart';
import '../widgets/image_picker_section.dart';

/// 일기 작성 화면
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showNetworkOverlay = false;
  String _networkOverlayMessage = '';
  NetworkStatusType _networkStatusType = NetworkStatusType.loading;

  /// 선택된 이미지 경로 목록
  final List<String> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 분석 상태 초기화 (새 일기 작성을 위해)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(diaryAnalysisControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      _startAnalysis();
    }
  }

  void _onRetryAnalysis() {
    _startAnalysis();
  }

  void _startAnalysis() {
    if (!mounted) {
      return;
    }

    final hasImages = _selectedImages.isNotEmpty;
    _showNetworkFeedback(
      statusType: NetworkStatusType.loading,
      message: hasImages
          ? 'AI가 사진과 함께 마음을 분석하고 있어요...'
          : 'AI가 당신의 마음을 분석하고 있어요...',
    );

    ref
        .read(diaryAnalysisControllerProvider.notifier)
        .analyzeDiary(
          _textController.text,
          imagePaths: hasImages ? List.from(_selectedImages) : null,
        );
  }

  void _onImageAdded(String path) {
    if (_selectedImages.length < AppConstants.maxImagesPerDiary) {
      setState(() {
        _selectedImages.add(path);
      });
    }
  }

  void _onImageRemoved(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      setState(() {
        _selectedImages.removeAt(index);
      });
    }
  }

  void _showNetworkFeedback({
    required NetworkStatusType statusType,
    required String message,
  }) {
    setState(() {
      _showNetworkOverlay = true;
      _networkOverlayMessage = message;
      _networkStatusType = statusType;
    });
  }

  void _hideNetworkFeedback() {
    setState(() {
      _showNetworkOverlay = false;
      _networkOverlayMessage = '';
    });
  }

  void _onRetry() {
    _hideNetworkFeedback();
    // 잠시 후 다시 시도
    Future.delayed(const Duration(milliseconds: 500), () {
      _startAnalysis();
    });
  }

  void _onDismissNetworkFeedback() {
    _hideNetworkFeedback();
  }

  void _onReset() {
    // 목록 새로고침 후 돌아감
    ref.read(diaryListControllerProvider.notifier).refresh();
    if (context.canPop()) {
      context.pop();
    } else {
      context.goHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(diaryAnalysisControllerProvider);
    final isLoading = analysisState is DiaryAnalysisLoading;

    // 분석 상태 변경 감지
    ref.listen(diaryAnalysisControllerProvider, (previous, next) {
      if (!mounted) {
        return;
      }

      if (next is DiaryAnalysisError || next is DiaryAnalysisSafetyBlocked) {
        _hideNetworkFeedback();
      }

      if (previous is DiaryAnalysisLoading && next is DiaryAnalysisSuccess) {
        _showNetworkFeedback(
          statusType: NetworkStatusType.retrySuccess,
          message: '성공적으로 분석이 완료되었습니다!',
        );

        // 2초 후 자동 숨김
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) {
            return;
          }
          _hideNetworkFeedback();
        });
      }
    });

    return Scaffold(
      appBar: const MindlogAppBar(title: Text(AppStrings.diaryScreenTitle)),
      body: Stack(
        children: [
          if (isLoading)
            _buildLoadingBody(context)
          else
            _buildContentBody(context, analysisState),

          // 네트워크 상태 오버레이
          NetworkStatusOverlay(
            isVisible: _showNetworkOverlay,
            statusMessage: _networkOverlayMessage,
            statusType: _networkStatusType,
            onRetry: _networkStatusType == NetworkStatusType.loading
                ? null
                : _onRetry,
            onDismiss: _networkStatusType == NetworkStatusType.loading
                ? null
                : _onDismissNetworkFeedback,
          ),
        ],
      ),
    );
  }

  Widget _buildContentBody(
    BuildContext context,
    DiaryAnalysisState analysisState,
  ) {
    return SafeArea(
      bottom: false, // 하단 SafeArea는 수동으로 처리
      child: SingleChildScrollView(
        padding: ResponsiveUtils.scrollPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 분석 결과 또는 입력 폼 표시
            switch (analysisState) {
              DiaryAnalysisInitial() => _buildInputForm(),
              DiaryAnalysisLoading() => _buildLoadingState(),
              DiaryAnalysisSuccess(diary: final diary) => ResultCard(
                diary: diary,
                onNewDiary: _onReset,
              ),
              DiaryAnalysisError(failure: final failure) => _buildErrorState(
                failure.displayMessage,
              ),
              DiaryAnalysisSafetyBlocked() => SosCard(onClose: _onReset),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surface,
                    AppColors.statsBackground,
                    AppColors.statsSecondary.withValues(alpha: 0.25),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          _buildAccentCircle(
            bottom: -120,
            right: -40,
            size: 220,
            color: AppColors.statsPrimary.withValues(alpha: 0.18),
            duration: const Duration(milliseconds: 4200),
          ),
          _buildAccentCircle(
            bottom: -170,
            left: -60,
            size: 260,
            color: AppColors.statsSecondary.withValues(alpha: 0.22),
            duration: const Duration(milliseconds: 4600),
            delay: const Duration(milliseconds: 600),
          ),
          SafeArea(
            child: Align(
              alignment: const Alignment(0, -0.2),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: const LoadingIndicator(
                  rotatingMessages: LoadingIndicator.analysisMessages,
                  centerContent: false,
                ),
              ),
            ),
          ),
        ],
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
          const Text(
            '오늘 하루는 어떠셨나요?',
            style: AppTextStyles.headline,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
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
          const SizedBox(height: 16),

          // 이미지 선택 섹션
          ImagePickerSection(
            imagePaths: _selectedImages,
            onImageAdded: _onImageAdded,
            onImageRemoved: _onImageRemoved,
          ),
          const SizedBox(height: 24),

          // 제출 버튼
          ElevatedButton(
            onPressed:
                _textController.text.trim().length >=
                    AppConstants.diaryMinLength
                ? _onSubmit
                : null,
            child: Text(
              _selectedImages.isNotEmpty
                  ? '${AppStrings.submitButton} (사진 ${_selectedImages.length}장 포함)'
                  : AppStrings.submitButton,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const LoadingIndicator(
      rotatingMessages: LoadingIndicator.analysisMessages,
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _onReset,
                child: const Text('목록으로'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _onRetryAnalysis,
                child: const Text(AppStrings.tryAgainButton),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccentCircle({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required Color color,
    Duration duration = const Duration(milliseconds: 4200),
    Duration delay = Duration.zero,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child:
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
                delay: delay,
              )
              .scale(
                begin: const Offset(0.96, 0.96),
                end: const Offset(1.04, 1.04),
                duration: duration,
                curve: Curves.easeInOut,
              ),
    );
  }
}
