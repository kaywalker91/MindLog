import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/presentation/providers/providers.dart';

/// 일기 목록 상태 관리 컨트롤러
class DiaryListController extends AsyncNotifier<List<Diary>> {
  @override
  FutureOr<List<Diary>> build() async {
    return _fetchDiaries();
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
}

/// 일기 목록 Provider
final diaryListControllerProvider =
    AsyncNotifierProvider<DiaryListController, List<Diary>>(() {
  return DiaryListController();
});
