import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 위기 상담 안내 카드 (Safety 블락 시 표시)
class SosCard extends StatelessWidget {
  final VoidCallback onClose;

  const SosCard({
    super.key,
    required this.onClose,
  });

  Future<void> _makePhoneCall(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.sosBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.sosBorder, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 아이콘 및 제목
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    AppStrings.sosTitle,
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 메시지
            Text(
              AppStrings.sosMessage,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),

            // 상담 전화 버튼들
            _buildHotlineButton(
              label: AppStrings.sosHotline,
              phoneNumber: '1393',
              icon: Icons.phone,
            ),
            const SizedBox(height: 12),
            _buildHotlineButton(
              label: AppStrings.sosMentalHealth,
              phoneNumber: '15770199',
              icon: Icons.local_hospital,
            ),
            const SizedBox(height: 24),

            // 닫기 버튼
            TextButton(
              onPressed: onClose,
              child: Text(
                AppStrings.closeButton,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotlineButton({
    required String label,
    required String phoneNumber,
    required IconData icon,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _makePhoneCall(phoneNumber),
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
