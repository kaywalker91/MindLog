import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/diary.dart';
import 'providers.dart';

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
}

/// 일기 목록 Provider
final diaryListControllerProvider =
    AsyncNotifierProvider<DiaryListController, List<Diary>>(() {
  return DiaryListController();
});
