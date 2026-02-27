import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/accessibility/app_accessibility.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/datasources/local/preferences_local_datasource.dart';
import '../router/app_router.dart';
import '../widgets/splash_animation_widget.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return AccessibilityWrapper(
      screenTitle: 'MindLog',
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.background,
                      AppColors.primaryLight.withValues(alpha: 0.4),
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
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
            _buildAccentCircle(
              bottom: -120,
              left: -60,
              size: 240,
              color: AppColors.primaryLight.withValues(alpha: 0.3),
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
                          // 로고 애니메이션 (breathing pulse, 회전 없음)
                          const SplashAnimationWidget(),
                          const SizedBox(height: 28),

                          // 앱 이름
                          Text(
                                AppConstants.appName,
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                textAlign: TextAlign.center,
                              )
                              .animate(controller: _animationController)
                              .fadeIn(delay: const Duration(milliseconds: 150))
                              .slideY(begin: 0.2, end: 0),

                          // 부제목
                          const SizedBox(height: 6),
                          Text(
                                '오늘의 마음을 부드럽게 기록해요',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                textAlign: TextAlign.center,
                              )
                              .animate(controller: _animationController)
                              .fadeIn(delay: const Duration(milliseconds: 250))
                              .slideY(begin: 0.2, end: 0),

                          // 점 3개 wave 로딩 인디케이터
                          const SizedBox(height: 24),
                          _buildSplashDots(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplashDots() {
    return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(
                    begin: 0,
                    end: -6,
                    delay: Duration(milliseconds: i * 150),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  ),
            );
          }),
        )
        .animate(controller: _animationController)
        .fadeIn(delay: const Duration(milliseconds: 400));
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
