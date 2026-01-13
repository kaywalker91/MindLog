class NotificationSettings {
  const NotificationSettings({
    required this.isReminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.isMindcareTopicEnabled,
  });

  final bool isReminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool isMindcareTopicEnabled;

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
  }) {
    return NotificationSettings(
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isMindcareTopicEnabled:
          isMindcareTopicEnabled ?? this.isMindcareTopicEnabled,
    );
  }

  factory NotificationSettings.defaults() {
    return const NotificationSettings(
      isReminderEnabled: defaultReminderEnabled,
      reminderHour: defaultReminderHour,
      reminderMinute: defaultReminderMinute,
      isMindcareTopicEnabled: defaultMindcareTopicEnabled,
    );
  }
}
