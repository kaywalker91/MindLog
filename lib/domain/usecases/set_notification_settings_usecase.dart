import '../entities/notification_settings.dart';
import '../repositories/settings_repository.dart';

class SetNotificationSettingsUseCase {
  final SettingsRepository _repository;

  SetNotificationSettingsUseCase(this._repository);

  Future<void> execute(NotificationSettings settings) {
    return _repository.setNotificationSettings(settings);
  }
}
