import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 안전 필터 차단 시 보여주는 SOS 카드 위젯
///
/// 소프트 랜딩 디자인:
/// - 단계적 페이드인으로 부드러운 노출
/// - 공감 메시지 먼저 표시 후 도움 정보 순차 노출
/// - 부드러운 amber 톤 배경 (빨간색은 긴급 버튼에만 사용)
class SosCard extends StatefulWidget {
  final VoidCallback onClose;

  const SosCard({super.key, required this.onClose});

  @override
  State<SosCard> createState() => _SosCardState();
}

class _SosCardState extends State<SosCard> with SingleTickerProviderStateMixin {
  /// 자살예방 통합 상담전화 (2024년 1월 1일부터 109로 통합)
  static const String _suicidePreventionCenter = '109';

  /// 정신건강 상담전화
  static const String _mentalHealthCounsel = '1577-0199';

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('통화 연결에 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 태블릿에서 카드가 과도하게 넓어지지 않도록 최대 너비 제한
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          // 부드러운 amber 톤 배경 (소프트 랜딩)
          color: AppColors.sosBackground,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.sosBorder.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phase 1: 공감 메시지 (가장 먼저 표시)
                _buildEmpathyHeader(colorScheme)
                    .animate(controller: _animationController)
                    .fadeIn(duration: const Duration(milliseconds: 400))
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 20),

                // Phase 2: 상세 공감 메시지
                _buildEmpathyMessage(colorScheme)
                    .animate(controller: _animationController)
                    .fadeIn(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 400),
                    )
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),

                // Phase 3: 도움 정보 (순차적으로 표시)
                _buildHelpSection(context, colorScheme)
                    .animate(controller: _animationController)
                    .fadeIn(
                      delay: const Duration(milliseconds: 600),
                      duration: const Duration(milliseconds: 400),
                    )
                    .slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Phase 1: 공감 헤더 (따뜻한 톤)
  Widget _buildEmpathyHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.sosBorder.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: AppColors.warning,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '많이 힘드셨군요',
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '당신의 마음을 들었어요',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Phase 2: 공감 메시지 박스
  Widget _buildEmpathyMessage(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sosBorder.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.spa_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '잠시 쉬어가도 괜찮아요',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '당신은 혼자가 아닙니다. 힘든 시기일수록 누군가와 이야기를 나누는 것이 도움이 됩니다. '
            '전문 상담사가 따뜻하게 당신의 이야기를 들어드릴 준비가 되어 있어요.',
            style: AppTextStyles.body.copyWith(
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Phase 3: 도움 정보 섹션
  Widget _buildHelpSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상담 연락처 안내
        Text(
          '언제든 연락하세요',
          style: AppTextStyles.subtitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // 자살예방 통합 상담전화 (109)
        _buildContactCard(
          context: context,
          icon: Icons.phone_in_talk,
          title: '자살예방 상담전화',
          subtitle: '24시간 무료 상담 (109)',
          phoneNumber: _suicidePreventionCenter,
          color: AppColors.error,
          isEmergency: true,
        ),
        const SizedBox(height: 12),

        // 정신건강 상담센터
        _buildContactCard(
          context: context,
          icon: Icons.psychology,
          title: '정신건강 상담센터',
          subtitle: '전문가 상담',
          phoneNumber: _mentalHealthCounsel,
          color: colorScheme.primary,
          isEmergency: false,
        ),
        const SizedBox(height: 20),

        // 안내 메시지 (부드러운 톤)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '지금 당장 상담이 어려우시다면, 다른 내용으로 마음을 기록해보셔도 괜찮아요.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 버튼들
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onClose,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '다른 내용 작성하기',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _makePhoneCall(_suicidePreventionCenter),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '상담 연결하기',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String phoneNumber,
    required Color color,
    required bool isEmergency,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _makePhoneCall(phoneNumber),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isEmergency
                ? AppColors.error.withValues(alpha: 0.5)
                : colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isEmergency
              ? AppColors.error.withValues(alpha: 0.05)
              : colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isEmergency ? AppColors.error : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isEmergency) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '긴급',
                            style: TextStyle(
                              color: colorScheme.onError,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.phone, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
