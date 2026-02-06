import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/self_encouragement_message.dart';
import '../../domain/repositories/settings_repository.dart';
import 'providers.dart';

/// 개인 응원 메시지 관리 Controller
class SelfEncouragementController
    extends AsyncNotifier<List<SelfEncouragementMessage>> {
  @override
  FutureOr<List<SelfEncouragementMessage>> build() async {
    final repository = ref.read(settingsRepositoryProvider);
    final messages = await repository.getSelfEncouragementMessages();
    // displayOrder 순으로 정렬
    messages.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return messages;
  }

  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  /// 새 메시지 추가
  Future<bool> addMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      if (kDebugMode) {
        debugPrint('[SelfEncouragement] Empty message rejected');
      }
      return false;
    }

    if (trimmed.length > SelfEncouragementMessage.maxContentLength) {
      if (kDebugMode) {
        debugPrint('[SelfEncouragement] Message too long: ${trimmed.length}');
      }
      return false;
    }

    final current = state.valueOrNull ?? [];
    if (current.length >= SelfEncouragementMessage.maxMessageCount) {
      if (kDebugMode) {
        debugPrint('[SelfEncouragement] Max message count reached');
      }
      return false;
    }

    final message = SelfEncouragementMessage(
      id: const Uuid().v4(),
      content: trimmed,
      createdAt: DateTime.now(),
      displayOrder: current.length,
    );

    await _repository.addSelfEncouragementMessage(message);

    final updated = [...current, message];
    state = AsyncValue.data(updated);

    if (kDebugMode) {
      debugPrint('[SelfEncouragement] Message added: ${message.id}');
    }

    return true;
  }

  /// 메시지 수정
  Future<bool> updateMessage(String id, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    if (trimmed.length > SelfEncouragementMessage.maxContentLength) {
      return false;
    }

    final current = state.valueOrNull ?? [];
    final index = current.indexWhere((m) => m.id == id);
    if (index == -1) return false;

    final updated = current[index].copyWith(content: trimmed);
    await _repository.updateSelfEncouragementMessage(updated);

    final newList = [...current];
    newList[index] = updated;
    state = AsyncValue.data(newList);

    if (kDebugMode) {
      debugPrint('[SelfEncouragement] Message updated: $id');
    }

    return true;
  }

  /// 메시지 삭제
  Future<void> deleteMessage(String id) async {
    final current = state.valueOrNull ?? [];
    final deletedIndex = current.indexWhere((m) => m.id == id);

    await _repository.deleteSelfEncouragementMessage(id);

    // displayOrder 재정렬
    final remaining =
        current.where((m) => m.id != id).toList();
    for (var i = 0; i < remaining.length; i++) {
      remaining[i] = remaining[i].copyWith(displayOrder: i);
    }

    state = AsyncValue.data(remaining);

    // 순차 모드: 삭제 위치에 따라 lastDisplayedIndex 보정
    await _adjustLastDisplayedIndex(deletedIndex, remaining.length);

    if (kDebugMode) {
      debugPrint('[SelfEncouragement] Message deleted: $id');
    }
  }

  /// 삭제 위치 기반 lastDisplayedIndex 보정 (순차 모드 전용)
  Future<void> _adjustLastDisplayedIndex(
    int deletedIndex,
    int remainingCount,
  ) async {
    if (deletedIndex < 0) return;

    final settings = ref.read(notificationSettingsProvider).valueOrNull;
    if (settings == null ||
        settings.rotationMode != MessageRotationMode.sequential) {
      return;
    }

    final last = settings.lastDisplayedIndex;
    int adjusted;

    if (remainingCount == 0) {
      adjusted = 0;
    } else if (deletedIndex <= last) {
      // 삭제 위치가 현재 인덱스 이하 → 1 감소 (wrap-around 처리)
      adjusted = (last - 1 + remainingCount) % remainingCount;
    } else {
      return; // 삭제 위치가 현재 인덱스 이후 → 변경 불필요
    }

    if (adjusted != last) {
      final updated = settings.copyWith(lastDisplayedIndex: adjusted);
      final useCase = ref.read(setNotificationSettingsUseCaseProvider);
      await useCase.execute(updated);
      ref.invalidate(notificationSettingsProvider);

      if (kDebugMode) {
        debugPrint(
          '[SelfEncouragement] lastDisplayedIndex adjusted: $last -> $adjusted',
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
    await _repository.reorderSelfEncouragementMessages(orderedIds);

    if (kDebugMode) {
      debugPrint('[SelfEncouragement] Reordered: $oldIndex -> $newIndex');
    }
  }
}

/// 개인 응원 메시지 Provider
final selfEncouragementProvider = AsyncNotifierProvider<
    SelfEncouragementController,
    List<SelfEncouragementMessage>>(
  SelfEncouragementController.new,
);
