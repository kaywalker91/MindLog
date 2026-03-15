import 'package:freezed_annotation/freezed_annotation.dart';

import 'self_encouragement_message.dart';

part 'notification_settings.freezed.dart';

@Freezed(copyWith: false)
class NotificationSettings with _$NotificationSettings {
  const NotificationSettings._();

  const factory NotificationSettings({
    required bool isReminderEnabled,
    required int reminderHour,
    required int reminderMinute,
    required bool isMindcareTopicEnabled,

    /// 메시지 로테이션 모드 (random: 랜덤, sequential: 순차)
    @Default(MessageRotationMode.random) MessageRotationMode rotationMode,

    /// 마지막으로 표시된 메시지 인덱스 (순차 모드용)
    @Default(0) int lastDisplayedIndex,

    /// 주간 감정 인사이트 알림 활성화 (매주 일요일 20:00)
    @Default(false) bool isWeeklyInsightEnabled,
  }) = _NotificationSettings;

  // 연구 기반: 17:00-20:00 참여율 최고, 19:00은 직장인 퇴근 후 여유 시간
  static const int defaultReminderHour = 19;
  static const int defaultReminderMinute = 0;
  static const bool defaultReminderEnabled = false;
  static const bool defaultMindcareTopicEnabled = false;
  static const bool defaultWeeklyInsightEnabled = false;

  NotificationSettings copyWith({
    bool? isReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? isMindcareTopicEnabled,
    MessageRotationMode? rotationMode,
    int? lastDisplayedIndex,
    bool? isWeeklyInsightEnabled,
  }) {
    return NotificationSettings(
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      reminderHour: (reminderHour ?? this.reminderHour).clamp(0, 23),
      reminderMinute: (reminderMinute ?? this.reminderMinute).clamp(0, 59),
      isMindcareTopicEnabled:
          isMindcareTopicEnabled ?? this.isMindcareTopicEnabled,
      rotationMode: rotationMode ?? this.rotationMode,
      lastDisplayedIndex: lastDisplayedIndex ?? this.lastDisplayedIndex,
      isWeeklyInsightEnabled:
          isWeeklyInsightEnabled ?? this.isWeeklyInsightEnabled,
    );
  }

  factory NotificationSettings.defaults() {
    return const NotificationSettings(
      isReminderEnabled: defaultReminderEnabled,
      reminderHour: defaultReminderHour,
      reminderMinute: defaultReminderMinute,
      isMindcareTopicEnabled: defaultMindcareTopicEnabled,
      rotationMode: MessageRotationMode.random,
      lastDisplayedIndex: 0,
      isWeeklyInsightEnabled: defaultWeeklyInsightEnabled,
    );
  }

  /// 순차 모드에서 현재 인덱스 계산 (modulo wrap-around)
  static int currentIndex(int lastDisplayed, int totalCount) {
    if (totalCount == 0) return 0;
    return lastDisplayed % totalCount;
  }

  /// 순차 모드에서 다음 인덱스 계산
  static int nextIndex(int current, int totalCount) {
    if (totalCount == 0) return 0;
    return (current + 1) % totalCount;
  }

  /// 메시지 삭제 후 lastDisplayedIndex 보정
  ///
  /// [lastDisplayed] 현재 lastDisplayedIndex
  /// [deletedIndex] 삭제된 메시지의 인덱스
  /// [remainingCount] 삭제 후 남은 메시지 수
  /// Returns: 보정된 인덱스, 또는 변경 불필요 시 null
  static int? adjustIndexAfterDeletion(
    int lastDisplayed,
    int deletedIndex,
    int remainingCount,
  ) {
    if (deletedIndex < 0) return null;
    if (remainingCount == 0) {
      return lastDisplayed != 0 ? 0 : null;
    }
    if (deletedIndex > lastDisplayed) return null; // 변경 불필요
    // Wraps pointer to end of list when deletedIndex == lastDisplayed == 0
    // (playlist-style wrap-around behavior)
    final adjusted = (lastDisplayed - 1 + remainingCount) % remainingCount;
    return adjusted != lastDisplayed ? adjusted : null;
  }
}
