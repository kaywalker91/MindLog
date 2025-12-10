import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/diary.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/result_card.dart';

/// 일기 상세 조회 화면
class DiaryDetailScreen extends StatelessWidget {
  final Diary diary;

  const DiaryDetailScreen({super.key, required this.diary});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy년 MM월 dd일 (E) a hh:mm', 'ko_KR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 상세'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 날짜 표시
              Text(
                dateFormatter.format(diary.createdAt),
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
                Text(
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
                    padding: EdgeInsets.all(20.0),
                    child: Text('아직 분석되지 않은 일기입니다.'),
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
