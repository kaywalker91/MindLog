import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/splash_theme.dart';
import '../widgets/splash_animation_widget.dart';
import '../widgets/loading_indicator.dart';
import 'diary_list_screen.dart';

/// 앱 전체 시작 화면
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _loadEnvironment();
    _startAnimations();
    _loadContent();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadEnvironment() async {
    try {
      // 환경 변수 로드
      await dotenv.load(fileName: '.env');
      
      // 앱 초기화 데이터 로드 (최종 SQLite DB, 기초 데이터 등)
    } catch (e) {
      debugPrint('환경 변수 로드 실패: $e');
    }
  }

  void _startAnimations() {
    // 등장 인사 애니메이션
    _animationController.forward();
  }

  void _loadContent() {
    // 2초 후 자동으로 메인 화면으로 이동
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateToDiary();
      }
    });
  }

  void _navigateToDiary() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const DiaryListScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final splashTheme = SplashTheme.createSplashTheme();
    
    return Scaffold(
      backgroundColor: splashTheme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 애니메이션
              const SplashAnimationWidget(),
              const SizedBox(height: 32),
              
              // 앱 이름 표시
              Text(
                AppConstants.appNameLong,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: splashTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              // 부제목 텍스트
              Text(
                '마음의 이야기를 들어주세요.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: splashTheme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // 애니메이션 로딩
              const LoadingIndicator(
                message: 'MindLog이 준비되는 중...',
              )
                .animate(controller: _animationController)
                .fadeIn(delay: const Duration(milliseconds: 500)),
              
              // 로딩 버튼
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    _navigateToDiary();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: splashTheme.colorScheme.primary,
                  foregroundColor: splashTheme.colorScheme.onSurface,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
