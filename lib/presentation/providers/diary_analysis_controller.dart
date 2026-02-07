import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/core/constants/notification_messages.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/core/services/analytics_service.dart';
import 'package:mindlog/core/services/emotion_trend_notification_service.dart';
import 'package:mindlog/core/services/emotion_trend_service.dart';
import 'package:mindlog/core/services/notification_service.dart';
import 'package:mindlog/core/services/safety_followup_service.dart';
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
      unawaited(
        AnalyticsService.logDiaryCreated(
          contentLength: diary.content.length,
          aiCharacterId: analysisResult?.aiCharacterId,
        ),
      );
      if (diary.status == DiaryStatus.analyzed && analysisResult != null) {
        final energyLevel =
            analysisResult.energyLevel ?? analysisResult.sentimentScore;
        unawaited(
          AnalyticsService.logDiaryAnalyzed(
            aiCharacterId: analysisResult.aiCharacterId ?? 'default',
            sentimentScore: analysisResult.sentimentScore,
            energyLevel: energyLevel,
          ),
        );
      }
      if (diary.status == DiaryStatus.analyzed ||
          diary.status == DiaryStatus.safetyBlocked) {
        // topKeywordsProvider는 statisticsProvider의 파생이므로 자동 갱신
        _ref.invalidate(statisticsProvider);
      }
      // Phase 2: 분석 후 알림 트리거 (비동기, 실패해도 분석 결과에 영향 없음)
      if (diary.status == DiaryStatus.analyzed && analysisResult != null) {
        unawaited(_triggerPostAnalysisNotifications(analysisResult));
      }
    } on Failure catch (failure) {
      if (failure is SafetyBlockedFailure) {
        state = const DiaryAnalysisSafetyBlocked();
        // Phase 2: 위기 감지 → 24시간 후 안부 확인 팔로업
        unawaited(_scheduleSafetyFollowup());
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

  /// Phase 2: 분석 완료 후 알림 트리거
  ///
  /// 1. 인지 패턴 감지 시 → 다음 날 오전 CBT 알림
  /// 2. 감정 트렌드 분석 → 트렌드 알림
  Future<void> _triggerPostAnalysisNotifications(
    AnalysisResult result,
  ) async {
    try {
      // 1. 인지 패턴 CBT 알림 (cognitivePattern이 있을 때만)
      if (result.cognitivePattern != null) {
        final cbtMessage = NotificationMessages.getCognitivePatternMessage(
          result.cognitivePattern!,
        );
        if (cbtMessage != null) {
          await NotificationService.scheduleNextMorning(
            patternName: result.cognitivePattern!,
            title: cbtMessage.title,
            body: cbtMessage.body,
          );
        }
      }

      // 2. 감정 트렌드 분석 + 알림
      try {
        final stats = await _ref.read(statisticsProvider.future);
        final trendResult = EmotionTrendService.analyzeTrend(
          stats.dailyEmotions,
        );
        if (trendResult != null) {
          await EmotionTrendNotificationService.notifyTrend(trendResult);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[DiaryAnalysis] Emotion trend analysis failed: $e',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[DiaryAnalysis] Post-analysis notification failed: $e',
        );
      }
    }
  }

  /// Phase 2: 위기 감지 → 24시간 후 안부 확인 팔로업
  ///
  /// IMPORTANT: SafetyBlockedFailure/isEmergency 로직은 절대 수정하지 않음.
  /// 읽기 전용으로 팔로업만 예약합니다.
  Future<void> _scheduleSafetyFollowup() async {
    try {
      await SafetyFollowupService.scheduleFollowup(DateTime.now());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DiaryAnalysis] Safety followup scheduling failed: $e');
      }
    }
  }
}

/// 일기 분석 컨트롤러 Provider
final diaryAnalysisControllerProvider =
    StateNotifierProvider.autoDispose<
      DiaryAnalysisNotifier,
      DiaryAnalysisState
    >((ref) {
      return DiaryAnalysisNotifier(ref);
    });
