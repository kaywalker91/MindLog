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

  static const int defaultReminderHour = 21;
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
