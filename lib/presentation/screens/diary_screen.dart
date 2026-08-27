import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../../core/accessibility/app_accessibility.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/image_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../../domain/entities/diary_draft.dart';
import '../providers/providers.dart';
import '../widgets/diary/diary_draft_banner.dart';
import '../widgets/diary/diary_input_form.dart';
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

  /// 선택된 이미지 경로 목록
  final List<String> _selectedImages = [];

  /// 화면 진입 시점의 오늘 날짜 (자정 넘김에도 기본값 유지)
  late final DateTime _screenEntryDay;

  /// 선택된 작성 날짜 (기본: 오늘)
  late DateTime _selectedDate;

  /// 백그라운드 전환 시 초안을 즉시 저장한다.
  late final AppLifecycleListener _lifecycleListener;

  /// PopScope 중복 pop 방지 (flush 중 재진입 가드)
  bool _isPopInProgress = false;

  /// picker 캐시 경로를 앱 디렉토리로 승격할 때 쓰는 초안 전용 diaryId
  static const _draftImageDiaryId = '__draft__';

  List<String>? get _draftImagePaths =>
      _selectedImages.isEmpty ? null : List<String>.from(_selectedImages);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _screenEntryDay = DateTime(now.year, now.month, now.day);
    _selectedDate = _screenEntryDay;
    _lifecycleListener = AppLifecycleListener(
      onPause: _flushDraftOnBackground,
      onHide: _flushDraftOnBackground,
    );
    // reset 이후에 restore — Success 잔상이 있으면 입력 폼이 없어 복원이 보이지 않는다.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      ref.read(diaryAnalysisControllerProvider.notifier).reset();
      await ref.read(diaryDraftControllerProvider.notifier).restore();
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
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
          entryDate: _selectedDate,
        );
  }

  bool get _isTodaySelected => _selectedDate == _screenEntryDay;

  String get _dateChipLabel {
    if (_isTodaySelected) {
      return '오늘';
    }
    final dateText = _selectedDate.year == _screenEntryDay.year
        ? '${_selectedDate.month}월 ${_selectedDate.day}일'
        : '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일';
    final daysAgo = _screenEntryDay.difference(_selectedDate).inDays;
    return daysAgo == 1 ? '어제 ($dateText)' : '$dateText ($daysAgo일 전)';
  }

  Future<void> _pickEntryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(
        _screenEntryDay.year - 5,
        _screenEntryDay.month,
        _screenEntryDay.day,
      ),
      lastDate: _screenEntryDay,
      helpText: '일기 날짜 선택',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
      await _flushDraft();
    }
  }

  void _onImageAdded(String path) {
    unawaited(_promoteAndAddImage(path));
  }

  /// picker 경로는 OS 캐시라 다음 실행에 사라지므로 `__draft__` 로 즉시 승격한다.
  Future<void> _promoteAndAddImage(String path) async {
    if (_selectedImages.length >= AppConstants.maxImagesPerDiary) {
      return;
    }

    var storedPath = path;
    try {
      storedPath = await ImageService.copyToAppDirectory(
        sourcePath: path,
        diaryId: _draftImageDiaryId,
        index: _selectedImages.length,
      );
    } catch (_) {
      // 승격 실패 시 원본 경로로 폴백 — 사용자 흐름은 막지 않는다.
      storedPath = path;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _selectedImages.add(storedPath);
    });
    await _flushDraft();
  }

  void _onImageRemoved(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      setState(() {
        _selectedImages.removeAt(index);
      });
      unawaited(_flushDraft());
    }
  }

  void _flushDraftOnBackground() {
    unawaited(_flushDraft());
  }

  /// 작성 중인 값을 초안에 즉시 저장한다. 분석 터미널 상태에서는 폐기를 되돌리지 않는다.
  Future<void> _flushDraft() async {
    if (!mounted) {
      return;
    }
    final analysis = ref.read(diaryAnalysisControllerProvider);
    if (analysis is DiaryAnalysisSuccess ||
        analysis is DiaryAnalysisSafetyBlocked) {
      return;
    }
    await ref
        .read(diaryDraftControllerProvider.notifier)
        .flush(
          content: _textController.text,
          entryDate: _selectedDate,
          imagePaths: _draftImagePaths,
        );
  }

  void _applyRestoredDraft(DiaryDraft draft) {
    _textController.text = draft.content;
    final restoredDay = DateTime(
      draft.entryDate.year,
      draft.entryDate.month,
      draft.entryDate.day,
    );
    setState(() {
      _selectedDate = restoredDay.isAfter(_screenEntryDay)
          ? _screenEntryDay
          : restoredDay;
      _selectedImages
        ..clear()
        ..addAll(draft.imagePaths ?? const <String>[]);
    });
  }

  void _onDraftDelete() {
    unawaited(ref.read(diaryDraftControllerProvider.notifier).discard());
    _textController.clear();
    setState(() {
      _selectedImages.clear();
      _selectedDate = _screenEntryDay;
    });
  }

  void _onDraftDismiss() {
    ref.read(diaryDraftControllerProvider.notifier).dismissBanner();
  }

  Future<void> _discardDraftOnTerminalAnalysis() async {
    await ref.read(diaryDraftControllerProvider.notifier).discard();
    await ImageService.deleteDiaryImages(_draftImageDiaryId);
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

    // 초안 복원 수신 — 미래 날짜는 화면 진입일(오늘)로 클램프
    ref.listen<DiaryDraftState>(diaryDraftControllerProvider, (_, next) {
      if (!mounted) {
        return;
      }
      if (next is DiaryDraftRestored) {
        _applyRestoredDraft(next.draft);
      }
    });

    // 분석 상태 변경 감지
    ref.listen(diaryAnalysisControllerProvider, (previous, next) {
      if (!mounted) {
        return;
      }

      if (next is DiaryAnalysisError || next is DiaryAnalysisSafetyBlocked) {
        _hideNetworkFeedback();
      }

      // 폐기는 터미널 상태에서만. Error 는 재시도 대비 초안을 유지한다.
      if (next is DiaryAnalysisSuccess || next is DiaryAnalysisSafetyBlocked) {
        unawaited(_discardDraftOnTerminalAnalysis());
      }

      if (previous is DiaryAnalysisLoading && next is DiaryAnalysisSuccess) {
        HapticFeedback.lightImpact();
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _isPopInProgress) {
          return;
        }
        _isPopInProgress = true;
        await _flushDraft();
        if (!context.mounted) {
          return;
        }
        context.pop();
      },
      child: AccessibilityWrapper(
        screenTitle: '오늘의 마음',
        child: Scaffold(
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
        ),
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
              DiaryAnalysisInitial() => _buildInputForm(context),
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

  Widget _buildInputForm(BuildContext context) {
    final draftState = ref.watch(diaryDraftControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (draftState is DiaryDraftRestored)
          DiaryDraftBanner(
            savedAt: draftState.draft.updatedAt,
            onDelete: _onDraftDelete,
            onDismiss: _onDraftDismiss,
          ),
        DiaryInputForm(
          formKey: _formKey,
          textController: _textController,
          dateChipLabel: _dateChipLabel,
          isTodaySelected: _isTodaySelected,
          selectedImagePaths: _selectedImages,
          onPickDate: _pickEntryDate,
          onImageAdded: _onImageAdded,
          onImageRemoved: _onImageRemoved,
          onSubmit: _onSubmit,
          onTextChanged: () {
            setState(() {});
            ref
                .read(diaryDraftControllerProvider.notifier)
                .onChanged(
                  content: _textController.text,
                  entryDate: _selectedDate,
                  imagePaths: _draftImagePaths,
                );
          },
        ),
      ],
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
