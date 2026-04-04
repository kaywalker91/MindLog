import 'dart:math';

import '../../entities/notification_settings.dart';
import '../../entities/self_encouragement_message.dart';
import '../../repositories/settings_repository.dart';
import '../../../core/errors/failures.dart';

/// 다음 표시할 응원 메시지 선택 UseCase
class GetNextSelfEncouragementMessageUseCase {
  final SettingsRepository _repository;
  final Random _random;

  GetNextSelfEncouragementMessageUseCase(this._repository, [Random? random])
    : _random = random ?? Random();

  /// 알림에 표시할 다음 메시지 선택
  ///
  /// - 메시지가 없으면 null 반환
  /// - random 모드: 랜덤 선택
  /// - sequential 모드: 순차 선택 (마지막 인덱스 다음)
  /// - emotionAware 모드: 최근 감정 점수와 같은 레벨의 메시지 우선 선택
  /// - timeAware 모드: 현재 시간대(아침/오후/저녁)에 맞는 메시지 우선 선택
  ///
  /// [currentEmotionScore] emotionAware 모드에서 사용할 최근 감정 점수 (1-10)
  /// [now] 시간 주입용 (null이면 DateTime.now() 사용, 테스트 용도)
  ///
  /// Throws:
  /// - [CacheFailure] 로컬 저장소 읽기 실패
  /// - [UnknownFailure] 예기치 않은 오류
  Future<SelfEncouragementMessage?> execute(
    NotificationSettings settings, {
    double? currentEmotionScore,
    DateTime? now,
  }) async {
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
          final nextIndex = NotificationSettings.nextIndex(
            settings.lastDisplayedIndex,
            messages.length,
          );
          return messages[nextIndex];

        case MessageRotationMode.emotionAware:
          if (currentEmotionScore == null) {
            return messages[_random.nextInt(messages.length)];
          }
          final currentLevel = _emotionLevel(currentEmotionScore);
          final filtered = messages
              .where(
                (m) =>
                    m.writtenEmotionScore != null &&
                    _emotionLevel(m.writtenEmotionScore!) == currentLevel,
              )
              .toList();
          final pool = filtered.isEmpty ? messages : filtered;
          return pool[_random.nextInt(pool.length)];

        case MessageRotationMode.timeAware:
          final currentHour = (now ?? DateTime.now()).hour;
          final category = _timeCategory(currentHour);
          final timeFiltered = messages
              .where((m) => m.timeCategory == category)
              .toList();
          final timePool = timeFiltered.isEmpty ? messages : timeFiltered;
          return timePool[_random.nextInt(timePool.length)];
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  /// 시간(0-23)을 시간대 카테고리 문자열로 변환
  /// morning: 5~11, afternoon: 12~17, evening: 18~23, 0~4
  String _timeCategory(int hour) {
    if (hour >= 5 && hour <= 11) return 'morning';
    if (hour >= 12 && hour <= 17) return 'afternoon';
    return 'evening';
  }

  /// 감정 점수(1-10)를 레벨로 변환
  /// 0: low (≤3), 1: medium (4-6), 2: high (>6)
  int _emotionLevel(double score) {
    if (score <= 3) return 0;
    if (score <= 6) return 1;
    return 2;
  }

  /// 순차 모드에서 다음 인덱스 계산
  /// [NotificationSettings.nextIndex]에 위임
  int getNextIndex(int currentIndex, int totalCount) {
    return NotificationSettings.nextIndex(currentIndex, totalCount);
  }
}
