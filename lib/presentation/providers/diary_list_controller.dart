import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/presentation/providers/providers.dart';

/// 일기 목록 상태 관리 컨트롤러
class DiaryListController extends AsyncNotifier<List<Diary>> {
  /// 삭제 대기 중인 일기 (Undo용)
  final Map<String, _PendingDeletion> _pendingDeletions = {};

  @override
  FutureOr<List<Diary>> build() async {
    ref.onDispose(_cancelAllPendingDeletions);
    return _fetchDiaries();
  }

  /// 모든 대기 중인 삭제 타이머 정리
  void _cancelAllPendingDeletions() {
    for (final pending in _pendingDeletions.values) {
      pending.timer.cancel();
    }
    _pendingDeletions.clear();
  }

  Future<List<Diary>> _fetchDiaries() async {
    final repository = ref.read(diaryRepositoryProvider);
    return await repository.getAllDiaries();
  }

  /// 목록 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDiaries());
  }

  /// 일기 상단 고정 토글
  Future<void> togglePin(String diaryId, bool isPinned) async {
    final previousState = state;
    if (previousState.value == null) return;

    // 낙관적 업데이트 (Optimistic Update)
    final updatedList = previousState.value!.map((diary) {
      if (diary.id == diaryId) {
        return diary.copyWith(isPinned: isPinned);
      }
      return diary;
    }).toList();

    // 정렬 유지: 고정된 일기 우선, 그 다음 최신순
    updatedList.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    state = AsyncValue.data(updatedList);

    try {
      final repository = ref.read(diaryRepositoryProvider);
      await repository.toggleDiaryPin(diaryId, isPinned);
    } catch (e) {
      // 실패 시 롤백
      state = previousState;
    }
  }

  /// 소프트 삭제 — 리스트에서 즉시 제거, 5초 후 실제 삭제
  void softDelete(Diary diary) {
    final currentList = state.value;
    if (currentList == null) return;

    // 기존 대기 중인 삭제가 있으면 즉시 실행
    _pendingDeletions[diary.id]?.timer.cancel();

    // 리스트에서 제거
    final updatedList = currentList.where((d) => d.id != diary.id).toList();
    state = AsyncValue.data(updatedList);

    // 5초 후 실제 삭제 실행
    final timer = Timer(const Duration(seconds: 5), () {
      _executeDeletion(diary.id);
    });

    _pendingDeletions[diary.id] = _PendingDeletion(diary: diary, timer: timer);
  }

  /// Undo — 삭제 취소, 리스트 복원
  void cancelDelete(String diaryId) {
    final pending = _pendingDeletions.remove(diaryId);
    if (pending == null) return;

    pending.timer.cancel();

    final currentList = state.value ?? [];
    final restoredList = [...currentList, pending.diary];

    // 정렬 유지
    restoredList.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    state = AsyncValue.data(restoredList);
  }

  Future<void> _executeDeletion(String diaryId) async {
    final pending = _pendingDeletions.remove(diaryId);
    if (pending == null) return;

    try {
      final repository = ref.read(diaryRepositoryProvider);
      await repository.deleteDiary(diaryId);
      // 통계 갱신 (topKeywordsProvider는 statisticsProvider의 파생이므로 자동 갱신)
      ref.invalidate(statisticsProvider);
    } catch (_) {
      // 삭제 실패 시 리스트 복원 (pending은 이미 제거되었으므로 직접 복원)
      final currentList = state.value ?? [];
      final restoredList = [...currentList, pending.diary];

      // 정렬 유지: 고정된 일기 우선, 그 다음 최신순
      restoredList.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      state = AsyncValue.data(restoredList);
    }
  }

  /// 즉시 삭제 — 확인 다이얼로그 후 호출 (Undo 없음)
  Future<void> deleteImmediately(String diaryId) async {
    final currentList = state.value;
    if (currentList == null) return;

    // 리스트에서 제거 (낙관적 업데이트)
    final updatedList = currentList.where((d) => d.id != diaryId).toList();
    state = AsyncValue.data(updatedList);

    final repository = ref.read(diaryRepositoryProvider);
    await repository.deleteDiary(diaryId);
    // 통계 갱신 (topKeywordsProvider는 statisticsProvider의 파생이므로 자동 갱신)
    ref.invalidate(statisticsProvider);
  }
}

class _PendingDeletion {
  final Diary diary;
  final Timer timer;

  _PendingDeletion({required this.diary, required this.timer});
}

/// 일기 목록 Provider
final diaryListControllerProvider =
    AsyncNotifierProvider<DiaryListController, List<Diary>>(() {
      return DiaryListController();
    });
