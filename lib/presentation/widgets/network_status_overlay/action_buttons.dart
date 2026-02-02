import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'network_status_type.dart';

/// 네트워크 상태 액션 버튼 위젯
class ActionButtons extends StatelessWidget {
  final NetworkStatusType? statusType;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetryWithAnimation;

  const ActionButtons({
    super.key,
    required this.statusType,
    this.onRetry,
    this.onDismiss,
    this.onRetryWithAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (statusType == NetworkStatusType.loading) {
      return _buildLoadingMessage(colorScheme);
    }

    if (statusType == NetworkStatusType.retrySuccess) {
      return _buildSuccessButton(context, colorScheme);
    }

    return _buildActionRow(context, colorScheme);
  }

  Widget _buildLoadingMessage(ColorScheme colorScheme) {
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);
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

  Widget _buildSuccessButton(BuildContext context, ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: onDismiss,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: const Text('확인'),
    );
  }

  Widget _buildActionRow(BuildContext context, ColorScheme colorScheme) {
    final primary = colorScheme.primary;
    final statusColor = _getStatusColor(primary);

    return Row(
      children: [
        if (onDismiss != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onDismiss,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: primary),
              ),
              child: const Text('취소'),
            ),
          ),
        if (onDismiss != null && onRetry != null) const SizedBox(width: 12),
        if (onRetry != null)
          Expanded(
            child: ElevatedButton(
              onPressed: onRetryWithAnimation ?? onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: Text(statusType?.retryButtonText ?? '확인'),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(Color primary) {
    switch (statusType) {
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
}
