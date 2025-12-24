import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/validators.dart';
import '../providers/diary_analysis_controller.dart';
import '../widgets/result_card.dart';
import '../widgets/sos_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/mindlog_app_bar.dart';
import '../widgets/network_status_overlay.dart';

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
      _showNetworkFeedback(
        statusType: NetworkStatusType.loading,
        message: 'AI가 당신의 마음을 분석하고 있어요...',
      );
      
      ref
          .read(diaryAnalysisControllerProvider.notifier)
          .analyzeDiary(_textController.text)
          .catchError((e) {
        _handleAnalysisError(e);
      });
    }
  }

  void _handleAnalysisError(Object error) {
    // 오류 타입에 따른 피드백 표시
    if (error.toString().contains('네트워크') || 
        error.toString().contains('연결')) {
      _showNetworkFeedback(
        statusType: NetworkStatusType.networkError,
        message: '인터넷 연결을 확인해주세요.\n자동으로 재시도합니다...',
      );
    } else if (error.toString().contains('파싱') ||
               error.toString().contains('응답')) {
      _showNetworkFeedback(
        statusType: NetworkStatusType.apiError,
        message: '서버 응답 처리 중 문제가 발생했습니다.\n다시 시도해주세요.',
      );
    } else {
      _showNetworkFeedback(
        statusType: NetworkStatusType.apiError,
        message: error.toString(),
      );
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
      _onSubmit();
    });
  }

  void _onDismissNetworkFeedback() {
    _hideNetworkFeedback();
  }

  void _onReset() {
    // 분석 완료 후 '확인'을 누르면 목록 화면으로 돌아감
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // 혹시 pop할 수 없는 상황이면 초기화 (예외 케이스)
      _textController.clear();
      _hideNetworkFeedback();
      ref.read(diaryAnalysisControllerProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(diaryAnalysisControllerProvider);
    final isLoading = analysisState is DiaryAnalysisLoading;

    // 분석 상태 변경 감지
    ref.listen(diaryAnalysisControllerProvider, (previous, next) {
      if (previous is DiaryAnalysisLoading && next is DiaryAnalysisSuccess) {
        _showNetworkFeedback(
          statusType: NetworkStatusType.retrySuccess,
          message: '성공적으로 분석이 완료되었습니다!',
        );
        
        // 2초 후 자동 숨김
        Future.delayed(const Duration(seconds: 2), () {
          _hideNetworkFeedback();
        });
      }
    });

    return Scaffold(
      appBar: MindlogAppBar(
        title: const Text(AppStrings.diaryScreenTitle),
      ),
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
            onRetry: _networkStatusType == NetworkStatusType.loading ? null : _onRetry,
            onDismiss: _networkStatusType == NetworkStatusType.loading ? null : _onDismissNetworkFeedback,
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
              DiaryAnalysisSuccess(diary: final diary) =>
                ResultCard(diary: diary, onNewDiary: _onReset),
              DiaryAnalysisError(failure: final failure) =>
                _buildErrorState(failure.displayMessage),
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
                  message: '마음을 읽고 있어요...',
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
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
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
