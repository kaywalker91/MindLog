import 'package:flutter/material.dart';
import 'network_status_type.dart';
import 'status_card.dart';

export 'network_status_type.dart';

/// 네트워크 상태 및 API 응답 상태 표시 오버레이
class NetworkStatusOverlay extends StatefulWidget {
  final bool isVisible;
  final String? statusMessage;
  final NetworkStatusType? statusType;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const NetworkStatusOverlay({
    super.key,
    this.isVisible = false,
    this.statusMessage,
    this.statusType,
    this.onRetry,
    this.onDismiss,
  });

  @override
  State<NetworkStatusOverlay> createState() => _NetworkStatusOverlayState();
}

class _NetworkStatusOverlayState extends State<NetworkStatusOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NetworkStatusOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.isVisible) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.7),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: StatusCard(
                  statusType: widget.statusType,
                  statusMessage: widget.statusMessage,
                  animationController: _animationController,
                  onRetry: widget.onRetry,
                  onDismiss: widget.onDismiss,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
