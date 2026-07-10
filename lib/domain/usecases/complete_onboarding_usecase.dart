import '../repositories/settings_repository.dart';

/// 온보딩 완료 처리 UseCase
///
/// 온보딩 화면 완료/건너뛰기 시 완료 상태를 저장한다.
class CompleteOnboardingUseCase {
  final SettingsRepository _repository;

  CompleteOnboardingUseCase(this._repository);

  Future<void> execute() {
    return _repository.setOnboardingCompleted();
  }
}
