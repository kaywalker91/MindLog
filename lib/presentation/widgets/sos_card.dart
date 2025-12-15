import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 안전 필터 차단 시 보여주는 SOS 카드 위젯
class SosCard extends StatefulWidget {
  final VoidCallback onClose;

  const SosCard({
    super.key,
    required this.onClose,
  });

  @override
  State<SosCard> createState() => _SosCardState();
}

class _SosCardState extends State<SosCard> {
  static const String _suicidePreventionCenter = '1577-0199';
  static const String _mentalHealthCounsel = '1644-0199';

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
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
    // 태블릿에서 카드가 과도하게 넓어지지 않도록 최대 너비 제한
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          color: AppColors.error.withValues(alpha: 0.05),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // 헤더 아이콘과 타이틀
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '관심이 필요한 당신에게',
                        style: AppTextStyles.headline.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '전문가의 도움을 받아보세요',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 공감 메시지
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '혹시 지금 힘드신가요?',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '당신은 혼자가 아닙니다. 어려운 시기일수록 전문가의 도움을 받는 것이'
                    ' 용기 있는 선택입니다. 아래의 상담 센터에서 따뜻한 조언과 지지를'
                    ' 받으실 수 있습니다.',
                    style: AppTextStyles.body.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 긴급 연락처
            Text(
              '긴급 상담 연락처',
              style: AppTextStyles.subtitle.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            
            // 자살예방 상담센터
            _buildContactCard(
              icon: Icons.phone_in_talk,
              title: '자살예방 상담센터',
              subtitle: '24시간 무료 상담',
              phoneNumber: _suicidePreventionCenter,
              color: Colors.red.shade500,
              isEmergency: true,
            ),
            const SizedBox(height: 12),

            // 정신건강 상담센터
            _buildContactCard(
              icon: Icons.psychology,
              title: '정신건강 상담센터',
              subtitle: '전문가 상담',
              phoneNumber: _mentalHealthCounsel,
              color: Colors.blue.shade500,
              isEmergency: false,
            ),
            const SizedBox(height: 24),

            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI가 안전상의 이유로 분석을 중단했습니다.'
                      ' 위 연락처는 언제든 도움을 받으실 수 있습니다.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text(
                      '다른 내용 작성하기',
                      style: TextStyle(
                        color: AppColors.error,
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
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '즉시 상담하기',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String phoneNumber,
    required Color color,
    required bool isEmergency,
  }) {
    return InkWell(
      onTap: () => _makePhoneCall(phoneNumber),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isEmergency ? AppColors.error.withValues(alpha: 0.5) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isEmergency 
            ? AppColors.error.withValues(alpha: 0.05) 
            : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
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
                          child: const Text(
                            '긴급',
                            style: TextStyle(
                              color: Colors.white,
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
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.phone,
              size: 20,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
