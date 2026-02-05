import 'self_encouragement_message.dart';

class NotificationSettings {
  const NotificationSettings({
    required this.isReminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.isMindcareTopicEnabled,
    this.rotationMode = MessageRotationMode.random,
    this.lastDisplayedIndex = 0,
  });

  final bool isReminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool isMindcareTopicEnabled;

  /// 메시지 로테이션 모드 (random: 랜덤, sequential: 순차)
  final MessageRotationMode rotationMode;

  /// 마지막으로 표시된 메시지 인덱스 (순차 모드용)
  final int lastDisplayedIndex;

  // 연구 기반: 17:00-20:00 참여율 최고, 19:00은 직장인 퇴근 후 여유 시간
  static const int defaultReminderHour = 19;
  static const int defaultReminderMinute = 0;
  static const bool defaultReminderEnabled = false;
  static const bool defaultMindcareTopicEnabled = false;

  NotificationSettings copyWith({
    bool? isReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? isMindcareTopicEnabled,
    MessageRotationMode? rotationMode,
    int? lastDisplayedIndex,
  }) {
    return NotificationSettings(
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isMindcareTopicEnabled:
          isMindcareTopicEnabled ?? this.isMindcareTopicEnabled,
      rotationMode: rotationMode ?? this.rotationMode,
      lastDisplayedIndex: lastDisplayedIndex ?? this.lastDisplayedIndex,
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
    );
  }
}
