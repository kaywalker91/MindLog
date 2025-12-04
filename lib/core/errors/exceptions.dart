/// 네트워크 관련 예외
class NetworkException implements Exception {
  final String? message;
  NetworkException([this.message]);

  @override
  String toString() => 'NetworkException: $message';
}

/// API 관련 예외
class ApiException implements Exception {
  final String? message;
  final int? statusCode;
  ApiException({this.message, this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// 데이터베이스 관련 예외
class DatabaseException implements Exception {
  final String? message;
  DatabaseException([this.message]);

  @override
  String toString() => 'DatabaseException: $message';
}

/// 안전 필터 관련 예외 (Safety block)
class SafetyBlockException implements Exception {
  final String? message;
  SafetyBlockException([this.message]);

  @override
  String toString() => 'SafetyBlockException: Content blocked for safety reasons';
}
