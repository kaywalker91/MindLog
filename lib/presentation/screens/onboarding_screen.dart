import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/datasources/local/preferences_local_datasource.dart';
import '../router/app_router.dart';

/// 온보딩 페이지 데이터
class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
  });
}

/// 최초 사용자 온보딩 화면
///
/// 앱의 목적과 사용법을 3단계로 안내
/// - 앱 소개
/// - 기능 안내 (감정 분석)
/// - 프라이버시 약속
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.edit_note_rounded,
      title: '마음을 기록해요',
      description: '하루의 감정을 자유롭게 적어보세요.\nAI가 따뜻한 마음으로 분석해드려요.',
      iconColor: AppColors.statsPrimary,
    ),
    _OnboardingPage(
      icon: Icons.psychology_rounded,
      title: '감정을 이해해요',
      description: '감정 온도, 핵심 키워드, 맞춤 행동 추천까지.\n당신의 마음을 더 잘 이해할 수 있어요.',
      iconColor: AppColors.statsAccentMint,
    ),
    _OnboardingPage(
      icon: Icons.lock_outline_rounded,
      title: '당신만의 공간이에요',
      description: '모든 일기는 기기에만 저장돼요.\n외부로 전송되지 않으니 안심하세요.',
      iconColor: AppColors.primary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('onboarding_started');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    AnalyticsService.logEvent(
      'onboarding_skipped',
      parameters: {'page': _currentPage},
    );
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await AnalyticsService.logEvent('onboarding_completed');
    await PreferencesLocalDataSource().setOnboardingCompleted();
    if (mounted) {
      context.goHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.statsBackground,
      body: SafeArea(
        child: Column(
          children: [
            // 건너뛰기 버튼
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    '건너뛰기',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // 페이지 콘텐츠
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),

            // 하단 인디케이터 및 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  // 페이지 인디케이터
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: WormEffect(
                      dotWidth: 10,
                      dotHeight: 10,
                      spacing: 12,
                      dotColor: colorScheme.surfaceContainerHighest,
                      activeDotColor: AppColors.statsPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 다음/시작하기 버튼
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _goToNextPage,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.statsPrimary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 ? '다음' : '시작하기',
                        style: AppTextStyles.button.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: page.iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(page.icon, size: 56, color: page.iconColor),
              )
              .animate(delay: Duration(milliseconds: 100 * index))
              .fadeIn(duration: const Duration(milliseconds: 400))
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          const SizedBox(height: 40),

          // 앱 이름 (첫 페이지만)
          if (index == 0) ...[
            Text(
                  AppConstants.appName,
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.statsPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                )
                .animate(delay: const Duration(milliseconds: 200))
                .fadeIn(duration: const Duration(milliseconds: 400)),
            const SizedBox(height: 8),
          ],

          // 타이틀
          Text(
                page.title,
                style: AppTextStyles.title.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              )
              .animate(delay: Duration(milliseconds: 150 + 100 * index))
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),

          // 설명
          Text(
                page.description,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              )
              .animate(delay: Duration(milliseconds: 250 + 100 * index))
              .fadeIn(duration: const Duration(milliseconds: 400))
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}
