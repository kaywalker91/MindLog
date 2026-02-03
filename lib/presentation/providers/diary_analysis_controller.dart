import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/core/services/analytics_service.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/presentation/providers/providers.dart';

/// 일기 분석 상태
sealed class DiaryAnalysisState {
  const DiaryAnalysisState();
}

/// 초기 상태 (입력 대기)
class DiaryAnalysisInitial extends DiaryAnalysisState {
  const DiaryAnalysisInitial();
}

/// 분석 중
class DiaryAnalysisLoading extends DiaryAnalysisState {
  const DiaryAnalysisLoading();
}

/// 분석 성공
class DiaryAnalysisSuccess extends DiaryAnalysisState {
  final Diary diary;
  const DiaryAnalysisSuccess(this.diary);
}

/// 분석 실패
class DiaryAnalysisError extends DiaryAnalysisState {
  final Failure failure;
  const DiaryAnalysisError(this.failure);
}

/// 안전 필터에 의해 차단됨
class DiaryAnalysisSafetyBlocked extends DiaryAnalysisState {
  const DiaryAnalysisSafetyBlocked();
}

/// 일기 분석 컨트롤러 Notifier
class DiaryAnalysisNotifier extends StateNotifier<DiaryAnalysisState> {
  final Ref _ref;

  DiaryAnalysisNotifier(this._ref) : super(const DiaryAnalysisInitial());

  /// 일기 분석 실행
  ///
  /// [content] 일기 텍스트 내용
  /// [imagePaths] 첨부된 이미지 경로 목록 (선택)
  Future<void> analyzeDiary(String content, {List<String>? imagePaths}) async {
    state = const DiaryAnalysisLoading();

    try {
      final useCase = _ref.read(analyzeDiaryUseCaseProvider);
      final diary = await useCase.execute(content, imagePaths: imagePaths);
      if (diary.analysisResult == null &&
          diary.status != DiaryStatus.safetyBlocked) {
        state = const DiaryAnalysisError(
          Failure.unknown(message: '분석 결과를 가져오지 못했습니다.'),
        );
        return;
      }
      state = DiaryAnalysisSuccess(diary);
      final analysisResult = diary.analysisResult;
      unawaited(AnalyticsService.logDiaryCreated(
        contentLength: diary.content.length,
        aiCharacterId: analysisResult?.aiCharacterId,
      ));
      if (diary.status == DiaryStatus.analyzed && analysisResult != null) {
        final energyLevel =
            analysisResult.energyLevel ?? analysisResult.sentimentScore;
        unawaited(AnalyticsService.logDiaryAnalyzed(
          aiCharacterId: analysisResult.aiCharacterId ?? 'default',
          sentimentScore: analysisResult.sentimentScore,
          energyLevel: energyLevel,
        ));
      }
      if (diary.status == DiaryStatus.analyzed ||
          diary.status == DiaryStatus.safetyBlocked) {
        // topKeywordsProvider는 statisticsProvider의 파생이므로 자동 갱신
        _ref.invalidate(statisticsProvider);
      }
    } on Failure catch (failure) {
      if (failure is SafetyBlockedFailure) {
        state = const DiaryAnalysisSafetyBlocked();
      } else {
        state = DiaryAnalysisError(failure);
      }
    } catch (e) {
      state = DiaryAnalysisError(Failure.unknown(message: e.toString()));
    }
  }

  /// 상태 초기화 (새 일기 작성)
  void reset() {
    state = const DiaryAnalysisInitial();
  }
}

/// 일기 분석 컨트롤러 Provider
final diaryAnalysisControllerProvider =
    StateNotifierProvider.autoDispose<DiaryAnalysisNotifier, DiaryAnalysisState>((ref) {
  return DiaryAnalysisNotifier(ref);
});
