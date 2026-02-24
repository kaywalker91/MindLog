import '../../domain/entities/notification_settings.dart';
import '../../domain/entities/self_encouragement_message.dart';
import '../../domain/repositories/notification_scheduler.dart';
import 'notification_settings_service.dart';

/// NotificationScheduler 구현체
///
/// NotificationSettingsService의 정적 메서드를 인스턴스 인터페이스로 래핑합니다.
class NotificationSchedulerImpl implements NotificationScheduler {
  const NotificationSchedulerImpl();

  @override
  Future<int> apply(
    NotificationSettings settings, {
    List<SelfEncouragementMessage> messages = const [],
    String source = 'user_toggle',
    String? userName,
    double? recentEmotionScore,
  }) {
    return NotificationSettingsService.applySettings(
      settings,
      messages: messages,
      source: source,
      userName: userName,
      recentEmotionScore: recentEmotionScore,
    );
  }
}
