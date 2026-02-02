import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

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
                child: _buildStatusCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(),
            const SizedBox(height: 16),
            Text(
              _getStatusTitle(),
              style: AppTextStyles.headline.copyWith(color: _getStatusColor()),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.statusMessage ?? _getDefaultMessage(),
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    )
        .animate(
          controller: _animationController,
          autoPlay: false,
          delay: const Duration(milliseconds: 100),
        )
        .slideY(begin: 0.2, end: 0.0, duration: const Duration(milliseconds: 300));
  }

  Widget _buildStatusIcon() {
    final primary = Theme.of(context).colorScheme.primary;

    switch (widget.statusType) {
      case NetworkStatusType.loading:
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: primary,
              strokeWidth: 3,
            ),
          ),
        )
        .animate(
          controller: _animationController,
          autoPlay: false,
          delay: const Duration(milliseconds: 100),
        )
        .rotate(duration: const Duration(milliseconds: 1000));
            
      case NetworkStatusType.networkError:
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Icon(
            Icons.wifi_off,
            color: AppColors.error,
            size: 32,
          ),
        )
        .animate(
          controller: _animationController,
          autoPlay: false,
          delay: const Duration(milliseconds: 100),
        )
        .scaleX(begin: 0.8, end: 1.2, duration: const Duration(milliseconds: 500))
            .then()
            .scaleX(begin: 1.2, end: 1.0, duration: const Duration(milliseconds: 300));
            
      case NetworkStatusType.apiError:
        return Container(
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
        )
        .animate(
          controller: _animationController,
          autoPlay: false,
          delay: const Duration(milliseconds: 100),
        )
        .scaleY(begin: 0.8, end: 1.2, duration: const Duration(milliseconds: 500))
            .then()
            .scaleY(begin: 1.2, end: 1.0, duration: const Duration(milliseconds: 300));
            
      case NetworkStatusType.retrySuccess:
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 32,
          ),
        )
        .animate(
          controller: _animationController,
          autoPlay: false,
          delay: const Duration(milliseconds: 100),
        )
        .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: const Duration(milliseconds: 400));
            
      default:
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Icon(
            _getStatusIcon(),
            color: primary,
            size: 32,
          ),
        );
    }
  }

  Widget _buildActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);

    if (widget.statusType == NetworkStatusType.loading) {
      return Column(
        children: [
          const SizedBox(height: 16),
          Text(
            '잠시만 기다려주세요...',
            style: AppTextStyles.bodySmall.copyWith(color: muted),
          ),
        ],
      );
    }

    if (widget.statusType == NetworkStatusType.retrySuccess) {
      return ElevatedButton(
        onPressed: widget.onDismiss,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 0),
        ),
        child: const Text('확인'),
      );
    }

    return Row(
      children: [
        if (widget.onDismiss != null)
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onDismiss,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: primary),
              ),
              child: const Text('취소'),
            ),
          ),
        if (widget.onDismiss != null && widget.onRetry != null)
          const SizedBox(width: 12),
        if (widget.onRetry != null)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // 힘치를 추가하기 위해 버튼 누를 때마다 애니메이션 재생
                _animationController.reset();
                _animationController.forward();
                widget.onRetry!();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(),
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: Text(_getRetryButtonText()),
            ),
          ),
      ],
    );
  }

  String _getStatusTitle() {
    switch (widget.statusType) {
      case NetworkStatusType.networkError:
        return '네트워크 연결 오류';
      case NetworkStatusType.apiError:
        return '응답 처리 오류';
      case NetworkStatusType.retrySuccess:
        return '성공적으로 완료!';
      case NetworkStatusType.loading:
        return '처리 중';
      default:
        return '알림';
    }
  }

  Color _getStatusColor() {
    final primary = Theme.of(context).colorScheme.primary;
    switch (widget.statusType) {
      case NetworkStatusType.networkError:
        return AppColors.error;
      case NetworkStatusType.apiError:
        return AppColors.warning;
      case NetworkStatusType.retrySuccess:
        return AppColors.success;
      case NetworkStatusType.loading:
        return primary;
      default:
        return primary;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.statusType) {
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

  String _getDefaultMessage() {
    switch (widget.statusType) {
      case NetworkStatusType.networkError:
        return '인터넷 연결을 확인하고 다시 시도해주세요.\n자동으로 재시도 합니다...';
      case NetworkStatusType.apiError:
        return '서버 응답을 처리하는 데 문제가 발생했습니다.\n잠시 후 다시 시도해주세요.';
      case NetworkStatusType.retrySuccess:
        return '작업이 성공적으로 완료되었습니다!';
      case NetworkStatusType.loading:
        return '요청을 처리하는 중입니다...';
      default:
        return '알림 메시지';
    }
  }

  String _getRetryButtonText() {
    switch (widget.statusType) {
      case NetworkStatusType.networkError:
        return '재시도';
      case NetworkStatusType.apiError:
        return '다시 시도';
      default:
        return '확인';
    }
  }
}

enum NetworkStatusType {
  loading,
  networkError,
  apiError,
  retrySuccess,
}
