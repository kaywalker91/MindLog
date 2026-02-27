import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 스플래시스크린 로고 애니메이션 위젯
///
/// - 등장 (800ms, one-shot): scale 0.6→1.0 (easeOutBack) + opacity 0.0→1.0
/// - 루프 (2500ms, breathing): scale 1.0→1.06 + glow blurRadius 15→30
class SplashAnimationWidget extends StatefulWidget {
  const SplashAnimationWidget({super.key});

  @override
  State<SplashAnimationWidget> createState() => _SplashAnimationWidgetState();
}

class _SplashAnimationWidgetState extends State<SplashAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _loopController;
  late Animation<double> _entranceScale;
  late Animation<double> _entranceOpacity;
  late Animation<double> _loopScale;
  late Animation<double> _glowRadius;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _loopController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _entranceScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _loopScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );

    _glowRadius = Tween<double>(begin: 15.0, end: 30.0).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
    _entranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _loopController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onPrimary;

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _loopController]),
      child: Icon(Icons.auto_stories_rounded, size: 72, color: iconColor),
      builder: (context, child) {
        return Opacity(
          opacity: _entranceOpacity.value,
          child: Transform.scale(
            scale: _entranceScale.value * _loopScale.value,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: _glowRadius.value,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(child: child),
            ),
          ),
        );
      },
    );
  }
}
