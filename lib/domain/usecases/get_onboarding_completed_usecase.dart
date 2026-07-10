import '../repositories/settings_repository.dart';

/// 온보딩 완료 여부 조회 UseCase
///
/// splash 화면이 첫 진입 여부를 판단하는 데 사용한다.
class GetOnboardingCompletedUseCase {
  final SettingsRepository _repository;

  GetOnboardingCompletedUseCase(this._repository);

  Future<bool> execute() {
    return _repository.isOnboardingCompleted();
  }
}
