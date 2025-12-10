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

/// 캐시(로컬 데이터베이스) 관련 예외
class CacheException implements Exception {
  final String? message;
  CacheException([this.message]);

  @override
  String toString() => 'CacheException: $message';
}

/// 안전 필터 관련 예외 (Safety block)
class SafetyBlockException implements Exception {
  final String? message;
  SafetyBlockException([this.message]);

  @override
  String toString() => 'SafetyBlockException: Content blocked for safety reasons';
}
