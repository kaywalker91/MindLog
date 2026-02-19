import '../../../core/errors/failures.dart';
import '../../repositories/diary_repository.dart';
import '../../repositories/secret_pin_repository.dart';

/// PIN 초기화 + 비밀일기 전체 해제 유스케이스
///
/// 실행 순서:
/// 1. 비밀일기 목록 조회
/// 2. 모든 비밀일기 isSecret = false 로 업데이트
/// 3. PIN 삭제
class DeleteSecretPinUseCase {
  final SecretPinRepository _pinRepository;
  final DiaryRepository _diaryRepository;

  DeleteSecretPinUseCase(this._pinRepository, this._diaryRepository);

  Future<void> execute() async {
    try {
      // 비밀일기 전체 해제
      final secretDiaries = await _diaryRepository.getSecretDiaries();
      for (final diary in secretDiaries) {
        await _diaryRepository.setDiarySecret(diary.id, false);
      }

      // PIN 삭제
      await _pinRepository.deletePin();
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }
}
