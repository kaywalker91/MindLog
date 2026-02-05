import 'dart:math';

import '../../entities/notification_settings.dart';
import '../../entities/self_encouragement_message.dart';
import '../../repositories/settings_repository.dart';
import '../../../core/errors/failures.dart';

/// 다음 표시할 응원 메시지 선택 UseCase
class GetNextSelfEncouragementMessageUseCase {
  final SettingsRepository _repository;
  final Random _random;

  GetNextSelfEncouragementMessageUseCase(
    this._repository, [
    Random? random,
  ]) : _random = random ?? Random();

  /// 알림에 표시할 다음 메시지 선택
  ///
  /// - 메시지가 없으면 null 반환
  /// - random 모드: 랜덤 선택
  /// - sequential 모드: 순차 선택 (마지막 인덱스 다음)
  ///
  /// Throws:
  /// - [CacheFailure] 로컬 저장소 읽기 실패
  /// - [UnknownFailure] 예기치 않은 오류
  Future<SelfEncouragementMessage?> execute(
    NotificationSettings settings,
  ) async {
    try {
      final messages = await _repository.getSelfEncouragementMessages();

      if (messages.isEmpty) {
        return null;
      }

      // displayOrder 순으로 정렬
      messages.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      switch (settings.rotationMode) {
        case MessageRotationMode.random:
          return messages[_random.nextInt(messages.length)];

        case MessageRotationMode.sequential:
          // 다음 인덱스 계산 (순환)
          final nextIndex =
              (settings.lastDisplayedIndex + 1) % messages.length;
          return messages[nextIndex];
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  /// 순차 모드에서 다음 인덱스 계산
  int getNextIndex(int currentIndex, int totalCount) {
    if (totalCount == 0) return 0;
    return (currentIndex + 1) % totalCount;
  }
}
