import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'action_buttons.dart';
import 'network_status_type.dart';
import 'status_icon.dart';

/// 네트워크 상태 카드 위젯
class StatusCard extends StatelessWidget {
  final NetworkStatusType? statusType;
  final String? statusMessage;
  final AnimationController animationController;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const StatusCard({
    super.key,
    required this.statusType,
    this.statusMessage,
    required this.animationController,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusIcon(
                  statusType: statusType,
                  animationController: animationController,
                ),
                const SizedBox(height: 16),
                Text(
                  statusType?.title ?? '알림',
                  style: AppTextStyles.headline.copyWith(
                    color: _getStatusColor(),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  statusMessage ?? statusType?.defaultMessage ?? '알림 메시지',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ActionButtons(
                  statusType: statusType,
                  onRetry: onRetry,
                  onDismiss: onDismiss,
                  onRetryWithAnimation: onRetry != null
                      ? () {
                          animationController.reset();
                          animationController.forward();
                          onRetry!();
                        }
                      : null,
                ),
              ],
            ),
          ),
        )
        .animate(
          controller: animationController,
          autoPlay: false,
          delay: const Duration(milliseconds: 100),
        )
        .slideY(
          begin: 0.2,
          end: 0.0,
          duration: const Duration(milliseconds: 300),
        );
  }

  Color _getStatusColor() {
    switch (statusType) {
      case NetworkStatusType.networkError:
        return AppColors.error;
      case NetworkStatusType.apiError:
        return AppColors.warning;
      case NetworkStatusType.retrySuccess:
        return AppColors.success;
      case NetworkStatusType.loading:
      default:
        return AppColors.primary;
    }
  }
}
