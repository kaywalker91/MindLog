import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import 'network_status_type.dart';

/// 네트워크 상태 아이콘 위젯
class StatusIcon extends StatelessWidget {
  final NetworkStatusType? statusType;
  final AnimationController? animationController;

  const StatusIcon({
    super.key,
    required this.statusType,
    this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    switch (statusType) {
      case NetworkStatusType.loading:
        return _buildLoadingIcon(primary);
      case NetworkStatusType.networkError:
        return _buildNetworkErrorIcon();
      case NetworkStatusType.apiError:
        return _buildApiErrorIcon();
      case NetworkStatusType.retrySuccess:
        return _buildSuccessIcon();
      default:
        return _buildDefaultIcon(primary);
    }
  }

  Widget _buildLoadingIcon(Color primary) {
    final icon = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: CircularProgressIndicator(color: primary, strokeWidth: 3),
      ),
    );

    if (animationController == null) return icon;

    return icon
        .animate(
          controller: animationController,
          autoPlay: false,
          delay: const Duration(milliseconds: 100),
        )
        .rotate(duration: const Duration(milliseconds: 1000));
  }

  Widget _buildNetworkErrorIcon() {
    final icon = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Icon(Icons.wifi_off, color: AppColors.error, size: 32),
    );

    if (animationController == null) return icon;

    return icon
        .animate(
          controller: animationController,
          autoPlay: false,
          delay: const Duration(milliseconds: 100),
        )
        .scaleX(
          begin: 0.8,
          end: 1.2,
          duration: const Duration(milliseconds: 500),
        )
        .then()
        .scaleX(
          begin: 1.2,
          end: 1.0,
          duration: const Duration(milliseconds: 300),
        );
  }

  Widget _buildApiErrorIcon() {
    final icon = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Icon(
        Icons.error_outline,
        color: AppColors.warning,
        size: 32,
      ),
    );

    if (animationController == null) return icon;

    return icon
        .animate(
          controller: animationController,
          autoPlay: false,
          delay: const Duration(milliseconds: 100),
        )
        .scaleY(
          begin: 0.8,
          end: 1.2,
          duration: const Duration(milliseconds: 500),
        )
        .then()
        .scaleY(
          begin: 1.2,
          end: 1.0,
          duration: const Duration(milliseconds: 300),
        );
  }

  Widget _buildSuccessIcon() {
    final icon = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: const Icon(Icons.check_circle, color: AppColors.success, size: 32),
    );

    if (animationController == null) return icon;

    return icon
        .animate(
          controller: animationController,
          autoPlay: false,
          delay: const Duration(milliseconds: 100),
        )
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: const Duration(milliseconds: 400),
        );
  }

  Widget _buildDefaultIcon(Color primary) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Icon(_getDefaultIconData(), color: primary, size: 32),
    );
  }

  IconData _getDefaultIconData() {
    switch (statusType) {
      case NetworkStatusType.networkError:
        return Icons.wifi_off;
      case NetworkStatusType.apiError:
        return Icons.error_outline;
      case NetworkStatusType.retrySuccess:
        return Icons.check_circle;
      case NetworkStatusType.loading:
        return Icons.refresh;
      default:
        return Icons.info;
    }
  }
}
