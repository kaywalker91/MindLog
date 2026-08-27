import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindlog/core/constants/app_constants.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/diary_draft.dart';
import 'package:mindlog/presentation/providers/providers.dart';

/// 초안 복원 상태
sealed class DiaryDraftState {
  const DiaryDraftState();
}

/// 복원 조회 중 — 이 동안 autosave는 잠긴다.
class DiaryDraftLoading extends DiaryDraftState {
  const DiaryDraftLoading();
}

/// 복원할 초안 없음 (배너 미표시)
class DiaryDraftAbsent extends DiaryDraftState {
  const DiaryDraftAbsent();
}

/// 초안을 복원함 — 화면은 폼에 값을 반영하고 배너를 띄운다.
class DiaryDraftRestored extends DiaryDraftState {
  final DiaryDraft draft;

  const DiaryDraftRestored(this.draft);
}

/// 일기 초안의 복원과 자동 저장을 관리한다.
class DiaryDraftController extends StateNotifier<DiaryDraftState> {
  final Ref _ref;

  Timer? _debounceTimer;
  Future<void> _operationTail = Future<void>.value();
  int _revision = 0;
  bool _discarding = false;

  DiaryDraftController(this._ref) : super(const DiaryDraftLoading());

  /// 화면 진입 시 초안을 한 번 복원한다.
  Future<void> restore() async {
    if (state is! DiaryDraftLoading) {
      return;
    }

    final restoreRevision = _revision;
    try {
      final draft = await _ref.read(getDiaryDraftUseCaseProvider).execute();
      if (!mounted || restoreRevision != _revision) {
        return;
      }

      state = draft == null
          ? const DiaryDraftAbsent()
          : DiaryDraftRestored(draft);
    } on Failure catch (failure) {
      _logFailure('초안 복원', failure);
      if (mounted && restoreRevision == _revision) {
        // 복원 실패가 새 일기 작성을 계속 잠그지 않도록 한다.
        state = const DiaryDraftAbsent();
      }
    }
  }

  /// 변경된 값을 디바운스한 뒤 저장한다.
  void onChanged({
    required String content,
    required DateTime entryDate,
    List<String>? imagePaths,
  }) {
    if (!_canSave) {
      return;
    }

    _cancelDebounce();
    final revision = ++_revision;
    final snapshot = _DiaryDraftSnapshot(
      content: content,
      entryDate: entryDate,
      imagePaths: imagePaths,
    );

    _debounceTimer = Timer(AppConstants.diaryDraftDebounce, () {
      _debounceTimer = null;
      if (!mounted || _discarding || revision != _revision) {
        return;
      }
      unawaited(_enqueueSave(snapshot, revision));
    });
  }

  /// 대기 중인 디바운스를 취소하고 전달받은 값을 즉시 저장한다.
  Future<void> flush({
    required String content,
    required DateTime entryDate,
    List<String>? imagePaths,
  }) {
    if (!_canSave) {
      return Future<void>.value();
    }

    _cancelDebounce();
    final revision = ++_revision;
    final snapshot = _DiaryDraftSnapshot(
      content: content,
      entryDate: entryDate,
      imagePaths: imagePaths,
    );
    return _enqueueSave(snapshot, revision);
  }

  /// 대기 및 진행 중 저장 뒤에 초안 폐기를 직렬화한다.
  Future<void> discard() {
    _cancelDebounce();
    _discarding = true;
    final discardRevision = ++_revision;
    final useCase = _ref.read(clearDiaryDraftUseCaseProvider);

    final operation = _operationTail
        .then((_) async {
          var cleared = false;
          try {
            await useCase.execute();
            cleared = true;
          } on Failure catch (failure) {
            _logFailure('초안 폐기', failure);
          }

          if (cleared && mounted && discardRevision == _revision) {
            state = const DiaryDraftAbsent();
          }
        })
        .whenComplete(() {
          if (discardRevision == _revision) {
            _discarding = false;
          }
        });

    _operationTail = operation;
    return operation;
  }

  /// 저장된 초안은 유지한 채 복원 배너만 닫는다.
  void dismissBanner() {
    if (mounted) {
      state = const DiaryDraftAbsent();
    }
  }

  bool get _canSave => mounted && state is! DiaryDraftLoading && !_discarding;

  Future<void> _enqueueSave(_DiaryDraftSnapshot snapshot, int revision) {
    final useCase = _ref.read(saveDiaryDraftUseCaseProvider);
    final operation = _operationTail.then((_) async {
      if (!mounted || _discarding || revision != _revision) {
        return;
      }

      try {
        await useCase.execute(
          snapshot.content,
          entryDate: snapshot.entryDate,
          imagePaths: snapshot.imagePaths,
        );
      } on Failure catch (failure) {
        _logFailure('초안 저장', failure);
      }
    });

    _operationTail = operation;
    return operation;
  }

  void _cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void _logFailure(String operation, Failure failure) {
    if (kDebugMode) {
      debugPrint('[DiaryDraft] $operation 실패: ${failure.displayMessage}');
    }
  }

  @override
  void dispose() {
    _cancelDebounce();
    _revision++;
    super.dispose();
  }
}

class _DiaryDraftSnapshot {
  final String content;
  final DateTime entryDate;
  final List<String>? imagePaths;

  _DiaryDraftSnapshot({
    required this.content,
    required this.entryDate,
    List<String>? imagePaths,
  }) : imagePaths = imagePaths == null
           ? null
           : List<String>.unmodifiable(imagePaths);
}

final diaryDraftControllerProvider =
    StateNotifierProvider.autoDispose<DiaryDraftController, DiaryDraftState>(
      (ref) => DiaryDraftController(ref),
    );
