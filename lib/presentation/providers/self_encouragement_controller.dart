import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/self_encouragement_message.dart';
import 'providers.dart';

/// 개인 응원 메시지 관리 Controller
class SelfEncouragementController
    extends AsyncNotifier<List<SelfEncouragementMessage>> {
  @override
  FutureOr<List<SelfEncouragementMessage>> build() async {
    // UseCase가 displayOrder 순 정렬까지 담당
    return ref.read(getSelfEncouragementMessagesUseCaseProvider).execute();
  }

  double? _currentEmotionScore() =>
      ref.read(todayEmotionProvider).sentimentScore?.toDouble();

  Future<void> _rescheduleCheerMe(
    List<SelfEncouragementMessage> messages, {
    String source = 'message_change',
    double? recentEmotionScore,
  }) async {
    await ref
        .read(notificationSettingsProvider.notifier)
        .rescheduleWithMessages(
          messages,
          source: source,
          recentEmotionScore: recentEmotionScore,
        );
  }

  /// 새 메시지 추가
  ///
  /// 유효성 검사(빈 내용·길이·개수 제한)는 UseCase가 담당하며,
  /// 컨트롤러는 실패를 UI용 bool로 변환하고 낙관적 상태·리스케줄만 오케스트레이션한다.
  Future<bool> addMessage(String content, {String? timeCategory}) async {
    final current = state.valueOrNull ?? [];
    final writtenEmotionScore = _currentEmotionScore();

    final message = SelfEncouragementMessage(
      id: const Uuid().v4(),
      content: content.trim(),
      createdAt: DateTime.now(),
      displayOrder: current.length,
      timeCategory: timeCategory,
      writtenEmotionScore: writtenEmotionScore,
    );

    try {
      await ref
          .read(addSelfEncouragementMessageUseCaseProvider)
          .execute(message);
    } on ValidationFailure catch (e) {
      // 검증 실패는 UI용 bool(false)로 변환. 영속화 오류(CacheFailure 등)는 전파.
      if (kDebugMode) {
        debugPrint('[SelfEncouragement] Add rejected: ${e.message}');
      }
      return false;
    }

    final updated = [...current, message];
    state = AsyncValue.data(updated);
    await _rescheduleCheerMe(
      updated,
      recentEmotionScore: writtenEmotionScore,
      source: 'message_change',
    );

    if (kDebugMode) {
      debugPrint('[SelfEncouragement] Message added: ${message.id}');
    }

    return true;
  }

  /// 메시지 수정
  Future<bool> updateMessage(
    String id,
    String content, {
    String? timeCategory,
  }) async {
    final current = state.valueOrNull ?? [];
    final index = current.indexWhere((m) => m.id == id);
    if (index == -1) return false;

    final currentEmotionScore = _currentEmotionScore();

    final updated = current[index].copyWith(
      content: content.trim(),
      timeCategory: timeCategory,
      writtenEmotionScore:
          current[index].writtenEmotionScore ?? currentEmotionScore,
    );

    try {
      await ref
          .read(updateSelfEncouragementMessageUseCaseProvider)
          .execute(updated);
    } on ValidationFailure catch (e) {
      // 검증 실패는 UI용 bool(false)로 변환. 영속화 오류(CacheFailure 등)는 전파.
      if (kDebugMode) {
        debugPrint('[SelfEncouragement] Update rejected: ${e.message}');
      }
      return false;
    }

    final newList = [...current];
    newList[index] = updated;
    state = AsyncValue.data(newList);
    await _rescheduleCheerMe(
      newList,
      recentEmotionScore: currentEmotionScore,
      source: 'message_change',
    );

    if (kDebugMode) {
      debugPrint('[SelfEncouragement] Message updated: $id');
    }

    return true;
  }

  /// 메시지 삭제
  Future<void> deleteMessage(String id) async {
    final current = state.valueOrNull ?? [];
    final deletedIndex = current.indexWhere((m) => m.id == id);

    await ref
        .read(deleteSelfEncouragementMessageUseCaseProvider)
        .execute(id);

    // displayOrder 재정렬
    final remaining = current.where((m) => m.id != id).toList();
    for (var i = 0; i < remaining.length; i++) {
      remaining[i] = remaining[i].copyWith(displayOrder: i);
    }

    state = AsyncValue.data(remaining);

    // 순차 모드: 삭제 위치에 따라 lastDisplayedIndex 보정
    await _adjustLastDisplayedIndex(deletedIndex, remaining.length);
    await _rescheduleCheerMe(
      remaining,
      recentEmotionScore: _currentEmotionScore(),
      source: 'message_change',
    );

    if (kDebugMode) {
      debugPrint('[SelfEncouragement] Message deleted: $id');
    }
  }

  /// 삭제 위치 기반 lastDisplayedIndex 보정 (순차 모드 전용)
  // Note: bidirectional dependency with NotificationSettingsController
  // — this controller reads/invalidates notificationSettingsProvider
  Future<void> _adjustLastDisplayedIndex(
    int deletedIndex,
    int remainingCount,
  ) async {
    final settings = ref.read(notificationSettingsProvider).valueOrNull;
    if (settings == null ||
        settings.rotationMode != MessageRotationMode.sequential) {
      return;
    }

    final adjusted = NotificationSettings.adjustIndexAfterDeletion(
      settings.lastDisplayedIndex,
      deletedIndex,
      remainingCount,
    );

    if (adjusted != null) {
      final updated = settings.copyWith(lastDisplayedIndex: adjusted);
      final useCase = ref.read(setNotificationSettingsUseCaseProvider);
      await useCase.execute(updated);
      ref.invalidate(notificationSettingsProvider);

      if (kDebugMode) {
        debugPrint(
          '[SelfEncouragement] lastDisplayedIndex adjusted: '
          '${settings.lastDisplayedIndex} -> $adjusted',
        );
      }
    }
  }

  /// 메시지 순서 변경 (드래그 리오더)
  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.valueOrNull ?? [];
    if (oldIndex < 0 ||
        oldIndex >= current.length ||
        newIndex < 0 ||
        newIndex >= current.length) {
      return;
    }

    final reordered = [...current];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // displayOrder 업데이트
    for (var i = 0; i < reordered.length; i++) {
      reordered[i] = reordered[i].copyWith(displayOrder: i);
    }

    // 낙관적 업데이트
    state = AsyncValue.data(reordered);

    // 저장
    final orderedIds = reordered.map((m) => m.id).toList();
    await ref
        .read(reorderSelfEncouragementMessagesUseCaseProvider)
        .execute(orderedIds);
    await _rescheduleCheerMe(
      reordered,
      recentEmotionScore: _currentEmotionScore(),
      source: 'message_reorder',
    );

    if (kDebugMode) {
      debugPrint('[SelfEncouragement] Reordered: $oldIndex -> $newIndex');
    }
  }
}

/// 개인 응원 메시지 Provider
final selfEncouragementProvider =
    AsyncNotifierProvider<
      SelfEncouragementController,
      List<SelfEncouragementMessage>
    >(SelfEncouragementController.new);
