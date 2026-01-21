/// 앱 내 발생 가능한 실패 유형 기본 클래스
sealed class Failure {
  final String? message;

  const Failure({this.message});

  /// 네트워크 연결 실패
  const factory Failure.network({String? message}) = NetworkFailure;

  /// API 호출 실패
  const factory Failure.api({String? message, int? statusCode}) = ApiFailure;

  /// 캐시(로컬 데이터베이스) 실패
  const factory Failure.cache({String? message}) = CacheFailure;

  /// 서버 관련 실패
  const factory Failure.server({String? message}) = ServerFailure;

  /// 데이터를 찾지 못했을 때
  const factory Failure.dataNotFound({String? message}) = DataNotFoundFailure;

  /// 입력 유효성 검사 실패
  const factory Failure.validation({required String message}) = ValidationFailure;

  /// 안전 필터 트리거 (자해/자살 관련 콘텐츠 감지)
  const factory Failure.safetyBlocked() = SafetyBlockedFailure;

  /// 이미지 처리 실패
  const factory Failure.imageProcessing({String? message}) = ImageProcessingFailure;

  /// 알 수 없는 오류
  const factory Failure.unknown({String? message}) = UnknownFailure;

  String get displayMessage;
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message});

  @override
  String get displayMessage => message ?? '네트워크 연결을 확인해주세요.';
}

class ApiFailure extends Failure {
  final int? statusCode;

  const ApiFailure({super.message, this.statusCode});

  @override
  String get displayMessage => message ?? 'API 호출 중 오류가 발생했습니다.';
}

class CacheFailure extends Failure {
  const CacheFailure({super.message});

  @override
  String get displayMessage => message ?? '데이터 저장 중 오류가 발생했습니다.';
}

class ServerFailure extends Failure {
  const ServerFailure({super.message});

  @override
  String get displayMessage => message ?? '서버 오류가 발생했습니다.';
}

class DataNotFoundFailure extends Failure {
  const DataNotFoundFailure({super.message});

  @override
  String get displayMessage => message ?? '데이터를 찾을 수 없습니다.';
}

class ValidationFailure extends Failure {
  const ValidationFailure({required String message}) : super(message: message);

  @override
  String get displayMessage => message ?? '입력 유효성 검사에 실패했습니다.';
}

class SafetyBlockedFailure extends Failure {
  const SafetyBlockedFailure({super.message});

  @override
  String get displayMessage => message ?? '안전상의 이유로 분석이 중단되었습니다.';
}

class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure({super.message});

  @override
  String get displayMessage => message ?? '이미지 처리 중 오류가 발생했습니다.';
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message});

  @override
  String get displayMessage => message ?? '알 수 없는 오류가 발생했습니다.';
}
