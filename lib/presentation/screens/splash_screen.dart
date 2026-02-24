import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/splash_theme.dart';
import '../../data/datasources/local/preferences_local_datasource.dart';
import '../router/app_router.dart';
import '../widgets/splash_animation_widget.dart';
import '../widgets/loading_indicator.dart';

/// 앱 전체 시작 화면
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isOnboardingCompleted = true; // 기본값: 온보딩 완료 (기존 유저 보호)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 환경 변수는 main.dart에서 이미 로드됨
    unawaited(AnalyticsService.logAppOpen());
    _startAnimations();
    _checkOnboardingAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    // 등장 인사 애니메이션
    _animationController.forward();
  }

  Future<void> _checkOnboardingAndNavigate() async {
    // 온보딩 완료 여부 확인
    _isOnboardingCompleted = await PreferencesLocalDataSource()
        .isOnboardingCompleted();

    // 2초 후 자동으로 적절한 화면으로 이동
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    // 프레임 완료 후 GoRouter가 준비된 상태에서 안전하게 navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_isOnboardingCompleted) {
        context.goHome();
      } else {
        context.goOnboarding();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final splashTheme = SplashTheme.createSplashTheme();

    return Scaffold(
      backgroundColor: splashTheme.colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.statsBackground,
                    AppColors.statsSecondary.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          _buildAccentCircle(
            top: -80,
            right: -40,
            size: 200,
            color: AppColors.statsPrimary.withValues(alpha: 0.2),
          ),
          _buildAccentCircle(
            bottom: -120,
            left: -60,
            size: 240,
            color: AppColors.statsAccentMint.withValues(alpha: 0.25),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 로고 애니메이션
                        const SplashAnimationWidget(),
                        const SizedBox(height: 28),

                        // 앱 이름 표시
                        Text(
                              AppConstants.appName,
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: splashTheme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                              textAlign: TextAlign.center,
                            )
                            .animate(controller: _animationController)
                            .fadeIn(delay: const Duration(milliseconds: 150))
                            .slideY(begin: 0.2, end: 0),

                        // 부제목 텍스트
                        const SizedBox(height: 6),
                        Text(
                              '오늘의 마음을 부드럽게 기록해요',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.statsTextSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            )
                            .animate(controller: _animationController)
                            .fadeIn(delay: const Duration(milliseconds: 250))
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 20),

                        // 애니메이션 로딩
                        const LoadingIndicator(
                              message: '마음 기록을 준비 중이에요',
                              subMessage: '따뜻한 마음 케어를 준비하고 있어요',
                              accentColor: AppColors.statsPrimaryDark,
                              cardColor: AppColors.statsCardBackground,
                              subTextColor: AppColors.statsTextTertiary,
                            )
                            .animate(controller: _animationController)
                            .fadeIn(delay: const Duration(milliseconds: 400)),

                        // 로딩 버튼
                        const SizedBox(height: 22),
                        _buildStartButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    const borderRadius = BorderRadius.all(Radius.circular(28));
    final colorScheme = Theme.of(context).colorScheme;
    final transparentSurface = colorScheme.surface.withValues(alpha: 0);

    return Material(
          color: transparentSurface,
          elevation: 0,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: () {
              if (mounted) {
                _navigateToNextScreen();
              }
            },
            borderRadius: borderRadius,
            splashColor: colorScheme.onPrimary.withValues(alpha: 0.2),
            highlightColor: colorScheme.onPrimary.withValues(alpha: 0.1),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.statsPrimary, AppColors.statsSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: borderRadius,
                border: Border.all(
                  color: AppColors.statsPrimaryDark.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '시작하기',
                    style: AppTextStyles.button.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colorScheme.onPrimary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(controller: _animationController)
        .fadeIn(delay: const Duration(milliseconds: 550))
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildAccentCircle({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
