import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/diary.dart';
import '../../core/errors/failures.dart';
import 'providers.dart';

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
  Future<void> analyzeDiary(String content) async {
    state = const DiaryAnalysisLoading();

    try {
      final useCase = _ref.read(analyzeDiaryUseCaseProvider);
      final diary = await useCase.execute(content);
      state = DiaryAnalysisSuccess(diary);
      if (diary.status == DiaryStatus.analyzed ||
          diary.status == DiaryStatus.safetyBlocked) {
        _ref.invalidate(statisticsProvider);
        _ref.invalidate(topKeywordsProvider);
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

/// 일기 목록 Provider
final diaryListProvider = FutureProvider.autoDispose<List<Diary>>((ref) async {
  final repository = ref.watch(diaryRepositoryProvider);
  return repository.getAllDiaries();
});

/// 오늘 일기 목록 Provider
final todayDiariesProvider = FutureProvider.autoDispose<List<Diary>>((ref) async {
  final repository = ref.watch(diaryRepositoryProvider);
  return repository.getTodayDiaries();
});
