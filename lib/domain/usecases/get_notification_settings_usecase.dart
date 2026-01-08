import '../entities/notification_settings.dart';
import '../repositories/settings_repository.dart';

class GetNotificationSettingsUseCase {
  final SettingsRepository _repository;

  GetNotificationSettingsUseCase(this._repository);

  Future<NotificationSettings> execute() {
    return _repository.getNotificationSettings();
  }
}
