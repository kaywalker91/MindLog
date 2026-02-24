import '../entities/notification_settings.dart';
import '../entities/self_encouragement_message.dart';
import '../repositories/notification_scheduler.dart';
import '../../core/errors/failures.dart';

/// 알림 설정 적용 UseCase
///
/// NotificationScheduler 인터페이스를 통해 알림을 스케줄링합니다.
/// Presentation 레이어가 Core 서비스에 직접 의존하지 않도록 합니다.
class ApplyNotificationSettingsUseCase {
  final NotificationScheduler _scheduler;

  ApplyNotificationSettingsUseCase(this._scheduler);

  /// 알림 설정 적용
  ///
  /// Returns: 순차 모드에서 다음 표시할 메시지 인덱스
  ///
  /// Throws:
  /// - [UnknownFailure] 예기치 않은 오류
  Future<int> execute(
    NotificationSettings settings, {
    List<SelfEncouragementMessage> messages = const [],
    String source = 'user_toggle',
    String? userName,
    double? recentEmotionScore,
  }) async {
    try {
      return await _scheduler.apply(
        settings,
        messages: messages,
        source: source,
        userName: userName,
        recentEmotionScore: recentEmotionScore,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }
}
