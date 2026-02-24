import '../entities/notification_settings.dart';
import '../entities/self_encouragement_message.dart';

/// 알림 스케줄링 추상 인터페이스
///
/// Domain 레이어가 알림 스케줄링 인프라에 의존하지 않도록
/// 역전시키는 포트(Port) 인터페이스.
abstract class NotificationScheduler {
  /// 알림 설정을 적용하고 알림을 스케줄링
  ///
  /// Returns: 순차 모드에서 다음 표시할 메시지 인덱스 (다른 모드에서는 현재값 유지)
  Future<int> apply(
    NotificationSettings settings, {
    List<SelfEncouragementMessage> messages = const [],
    String source = 'user_toggle',
    String? userName,
    double? recentEmotionScore,
  });
}
