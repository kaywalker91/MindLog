import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../../domain/entities/diary.dart';
import '../widgets/result_card.dart';
import '../widgets/mindlog_app_bar.dart';
import '../widgets/sos_card.dart';

/// 일기 상세 조회 화면
class DiaryDetailScreen extends StatelessWidget {
  // DateFormat 인스턴스 재사용 (생성 비용 최적화)
  static final DateFormat _dateFormatter =
      DateFormat('yyyy년 MM월 dd일 (E) a hh:mm', 'ko_KR');

  final Diary diary;

  const DiaryDetailScreen({super.key, required this.diary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MindlogAppBar(
        title: Text('일기 상세'),
      ),
      body: SafeArea(
        bottom: false, // 하단은 수동으로 처리
        child: SingleChildScrollView(
          padding: ResponsiveUtils.scrollPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 날짜 표시
              Text(
                _dateFormatter.format(diary.createdAt),
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 원본 일기 내용
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  diary.content,
                  style: AppTextStyles.body.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 32),

              // 분석 결과 (있을 경우에만)
              if (diary.status == DiaryStatus.analyzed &&
                  diary.analysisResult != null) ...[
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'AI 마음 분석 리포트',
                  style: AppTextStyles.headline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // 기존 ResultCard 재사용
                // onNewDiary 콜백은 상세 화면에서는 필요 없으므로 빈 함수 전달하거나 숨김 처리 필요
                // 하지만 ResultCard 구조상 필수이므로, 상세 화면에서는 '목록으로' 등의 동작으로 대체 가능
                // 여기서는 단순히 pop
                ResultCard(
                  diary: diary,
                  onNewDiary: () => Navigator.of(context).pop(),
                ),
              ] else if (diary.status == DiaryStatus.pending) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('아직 분석되지 않은 일기입니다.'),
                  ),
                ),
              ] else if (diary.status == DiaryStatus.safetyBlocked) ...[
                const Divider(),
                const SizedBox(height: 16),
                SosCard(onClose: () => Navigator.of(context).pop()),
              ] else if (diary.status == DiaryStatus.failed) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('분석에 실패한 일기입니다.\n네트워크 상태를 확인해주세요.'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
