import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/diary.dart';
import '../providers/diary_list_controller.dart';
import 'diary_screen.dart';
import 'diary_detail_screen.dart';

/// 일기 목록 화면 (메인)
class DiaryListScreen extends ConsumerStatefulWidget {
  const DiaryListScreen({super.key});

  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 데이터 로드
    // Future.microtask(() => ref.read(diaryListControllerProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final diaryListState = ref.watch(diaryListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 설정 화면 이동
            },
          ),
        ],
      ),
      body: diaryListState.when(
        data: (diaries) => _buildList(diaries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류 발생: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 일기 작성 화면으로 이동
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DiaryScreen()),
          );
          // 작성 후 돌아오면 목록 새로고침
          ref.read(diaryListControllerProvider.notifier).refresh();
        },
        label: const Text('오늘 기록하기'),
        icon: const Icon(Icons.edit),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildList(List<Diary> diaries) {
    if (diaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '작성된 일기가 없습니다.\n오늘의 마음을 기록해보세요!',
              style: AppTextStyles.body.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        return ref.read(diaryListControllerProvider.notifier).refresh();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: diaries.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final diary = diaries[index];
          return _buildDiaryItem(diary);
        },
      ),
    );
  }

  Widget _buildDiaryItem(Diary diary) {
    final dateFormatter = DateFormat('MM월 dd일 (E)', 'ko_KR');
    
    // 감정 점수에 따른 이모지 및 색상
    String emoji = '📝';
    Color color = Colors.grey.shade100;
    
    if (diary.status == DiaryStatus.analyzed && diary.analysisResult != null) {
      final score = diary.analysisResult!.sentimentScore;
      if (score <= 3) {
        emoji = '😢';
        color = Colors.red.withValues(alpha: 0.1);
      } else if (score <= 5) {
        emoji = '😔';
        color = Colors.orange.withValues(alpha: 0.1);
      } else if (score <= 7) {
        emoji = '😐';
        color = Colors.yellow.withValues(alpha: 0.1);
      } else if (score <= 8) {
        emoji = '🙂';
        color = Colors.green.withValues(alpha: 0.1);
      } else {
        emoji = '😊';
        color = Colors.blue.withValues(alpha: 0.1);
      }
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DiaryDetailScreen(diary: diary),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            // 날짜 및 감정 아이콘
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // 내용 요약
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormatter.format(diary.createdAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    diary.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body,
                  ),
                  if (diary.analysisResult?.keywords.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: diary.analysisResult!.keywords.take(2).map((k) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#$k',
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
