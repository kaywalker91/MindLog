import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 응급 상황(SOS) 카드 위젯
class SOSCard extends StatelessWidget {
  const SOSCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.sosCardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sosCardBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.sosIcon.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 56, color: AppColors.sosIcon)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 1000.ms,
              ),
          const SizedBox(height: 20),
          Text(
            '전문가의 도움이 필요할 수 있어요',
            style: AppTextStyles.headline.copyWith(color: AppColors.sosTextDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '혼자서 너무 힘들어하지 마세요.\n당신의 이야기를 들어줄 전문가가 기다리고 있습니다.',
            style: AppTextStyles.body.copyWith(
              height: 1.5,
              color: AppColors.sosTextDarker,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const _EmergencyButton(
            label: '24시간 자살예방상담전화 (109)',
            number: '109',
            icon: Icons.phone_in_talk,
          ),
          const SizedBox(height: 12),
          const _EmergencyButton(
            label: '정신건강상담전화',
            number: '1577-0199',
            icon: Icons.support_agent,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final String label;
  final String number;
  final IconData icon;

  const _EmergencyButton({
    required this.label,
    required this.number,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final Uri launchUri = Uri(scheme: 'tel', path: number);
        if (await canLaunchUrl(launchUri)) {
          await launchUrl(launchUri);
        }
      },
      icon: Icon(icon, color: Theme.of(context).colorScheme.onError),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.sosButton,
        foregroundColor: Theme.of(context).colorScheme.onError,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
