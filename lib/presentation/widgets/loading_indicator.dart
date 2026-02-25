import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_text_styles.dart';

/// 로딩 메시지 데이터
class LoadingMessage {
  final String message;
  final String subMessage;

  const LoadingMessage({required this.message, required this.subMessage});
}

/// 로딩 인디케이터 위젯
/// 일기 분석 중 표시되는 로딩 화면
///
/// [rotatingMessages]가 제공되면 2초마다 메시지가 로테이션됨
class LoadingIndicator extends StatefulWidget {
  final String message;
  final String subMessage;
  final Color? accentColor;
  final Color? cardColor;
  final Color? subTextColor;
  final bool centerContent;

  /// 로테이션할 메시지 목록 (제공 시 자동 로테이션)
  final List<LoadingMessage>? rotatingMessages;

  /// 메시지 전환 간격 (기본 2초)
  final Duration rotationInterval;

  const LoadingIndicator({
    super.key,
    this.message = '처리 중...',
    this.subMessage = 'AI가 당신의 마음을 분석하고 있어요...',
    this.accentColor,
    this.cardColor,
    this.subTextColor,
    this.centerContent = true,
    this.rotatingMessages,
    this.rotationInterval = const Duration(seconds: 2),
  });

  /// 분석용 기본 로테이션 메시지
  static const List<LoadingMessage> analysisMessages = [
    LoadingMessage(message: '일기를 저장하는 중...', subMessage: '소중한 기록을 보관하고 있어요'),
    LoadingMessage(message: 'AI가 감정을 분석하는 중...', subMessage: '당신의 이야기를 천천히 들어볼게요'),
    LoadingMessage(message: '거의 다 됐어요', subMessage: '따뜻한 마음 케어를 준비하고 있어요'),
  ];

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> {
  int _currentMessageIndex = 0;
  Timer? _rotationTimer;

  String get _currentMessage {
    if (widget.rotatingMessages != null &&
        widget.rotatingMessages!.isNotEmpty) {
      return widget.rotatingMessages![_currentMessageIndex].message;
    }
    return widget.message;
  }

  String get _currentSubMessage {
    if (widget.rotatingMessages != null &&
        widget.rotatingMessages!.isNotEmpty) {
      return widget.rotatingMessages![_currentMessageIndex].subMessage;
    }
    return widget.subMessage;
  }

  @override
  void initState() {
    super.initState();
    _startRotationTimer();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _startRotationTimer() {
    if (widget.rotatingMessages == null || widget.rotatingMessages!.isEmpty) {
      return;
    }

    _rotationTimer = Timer.periodic(widget.rotationInterval, (_) {
      if (!mounted) return;
      setState(() {
        _currentMessageIndex =
            (_currentMessageIndex + 1) % widget.rotatingMessages!.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? colorScheme.primary;
    final surface = widget.cardColor ?? colorScheme.surface;
    final subText =
        widget.subTextColor ?? colorScheme.onSurface.withValues(alpha: 0.6);

    // 반응형 크기 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 360 ? 70.0 : 90.0;
    final innerIconSize = screenWidth < 360 ? 36.0 : 44.0;

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI 로딩 애니메이션 (개선된 스타일)
          _buildLoadingIcon(context, accent, surface, iconSize, innerIconSize),
          const SizedBox(height: 28),

          // 메시지 카드 (개선된 스타일)
          _buildMessageCard(context, accent, surface, subText, screenWidth),
          const SizedBox(height: 20),

          // 점 애니메이션 (개선된 스타일)
          _buildDotsAnimation(context, accent),
        ],
      ),
    );

    if (!widget.centerContent) {
      return content;
    }

    return Center(child: content);
  }

  /// 로딩 아이콘 위젯 (그라데이션 링 + 뇌 아이콘)
  Widget _buildLoadingIcon(
    BuildContext context,
    Color accent,
    Color surface,
    double size,
    double innerIconSize,
  ) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 외곽 그라데이션 링 애니메이션
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.3),
                      accent.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              )
              .animate(
                onPlay: (controller) => _repeatIfMounted(context, controller),
              )
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.05, 1.05),
                end: const Offset(0.95, 0.95),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
              ),

          // 내부 원 (더 밝은 색상)
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: surface,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),

          // 뇌 아이콘
          Icon(Icons.psychology_rounded, size: innerIconSize, color: accent)
              .animate(
                onPlay: (controller) => _repeatIfMounted(context, controller),
              )
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.1, 1.1),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.1, 1.1),
                end: const Offset(0.85, 0.85),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
              ),

          // 회전하는 점들 (파티클 효과)
          ...List.generate(4, (index) {
            final angle = (index * 90.0) * (3.14159 / 180);
            return Positioned.fill(
              child: Transform.rotate(
                angle: angle,
                child: Align(
                  alignment: Alignment.topCenter,
                  child:
                      Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          )
                          .animate(
                            onPlay: (controller) =>
                                _repeatIfMounted(context, controller),
                            delay: Duration(milliseconds: 150 * index),
                          )
                          .fadeIn(duration: const Duration(milliseconds: 400))
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.2, 1.2),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                          )
                          .then()
                          .fadeOut(duration: const Duration(milliseconds: 400))
                          .scale(
                            begin: const Offset(1.2, 1.2),
                            end: const Offset(0.5, 0.5),
                            duration: const Duration(milliseconds: 600),
                          ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 메시지 카드 위젯 (그라데이션 배경 + 강화된 그림자)
  Widget _buildMessageCard(
    BuildContext context,
    Color accent,
    Color surface,
    Color subText,
    double screenWidth,
  ) {
    return Container(
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [surface, accent.withValues(alpha: 0.03)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 주 메시지 (AnimatedSwitcher로 부드러운 전환)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _currentMessage,
                  key: ValueKey<String>(_currentMessage),
                  style: AppTextStyles.title.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
              const SizedBox(height: 12),

              // 서브 메시지 (AnimatedSwitcher로 부드러운 전환)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  _currentSubMessage,
                  key: ValueKey<String>(_currentSubMessage),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: subText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 400))
        .slideY(
          begin: 0.1,
          end: 0,
          duration: const Duration(milliseconds: 500),
        );
  }

  /// 점 애니메이션 위젯 (물결 효과)
  Widget _buildDotsAnimation(BuildContext context, Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            )
            .animate(
              onPlay: (controller) => _repeatIfMounted(context, controller),
              delay: Duration(milliseconds: 200 * index),
            )
            .scaleXY(
              begin: 0.6,
              end: 1.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
            )
            .moveY(
              begin: 0,
              end: -6,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            )
            .then(delay: const Duration(milliseconds: 100))
            .moveY(
              begin: -6,
              end: 0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeIn,
            )
            .scaleXY(
              begin: 1.0,
              end: 0.6,
              duration: const Duration(milliseconds: 400),
            );
      }),
    );
  }

  void _repeatIfMounted(BuildContext context, AnimationController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      controller.repeat();
    });
  }
}
