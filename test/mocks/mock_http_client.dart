import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Mock HTTP Client for testing GroqRemoteDataSource
class MockHttpClient implements http.Client {
  // 응답/예외 제어 변수
  http.Response? mockResponse;
  Exception? exceptionToThrow;
  List<Exception>? exceptionsSequence;
  int _exceptionIndex = 0;

  // 호출 추적
  int callCount = 0;
  final List<Uri> calledUris = [];
  final List<Map<String, String>?> calledHeaders = [];
  final List<Object?> calledBodies = [];

  /// 상태 초기화
  void reset() {
    mockResponse = null;
    exceptionToThrow = null;
    exceptionsSequence = null;
    _exceptionIndex = 0;
    callCount = 0;
    calledUris.clear();
    calledHeaders.clear();
    calledBodies.clear();
  }

  /// 성공 응답 설정 헬퍼 (UTF-8 인코딩 사용)
  void setSuccessResponse(Map<String, dynamic> body, {int statusCode = 200}) {
    final bytes = utf8.encode(jsonEncode(body));
    mockResponse = http.Response.bytes(
      bytes,
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  /// 에러 응답 설정 헬퍼
  void setErrorResponse(
    int statusCode, {
    String? body,
    Map<String, String>? headers,
  }) {
    mockResponse = http.Response(
      body ?? '',
      statusCode,
      headers: headers ?? {},
    );
  }

  /// 순차적 예외 설정 (재시도 테스트용)
  void setExceptionsSequence(List<Exception> exceptions) {
    exceptionsSequence = exceptions;
    _exceptionIndex = 0;
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    callCount++;
    calledUris.add(url);
    calledHeaders.add(headers);
    calledBodies.add(body);

    // 순차적 예외 처리
    if (exceptionsSequence != null &&
        _exceptionIndex < exceptionsSequence!.length) {
      throw exceptionsSequence![_exceptionIndex++];
    }

    // 단일 예외 처리
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }

    return mockResponse ?? http.Response('{}', 200);
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError('get is not implemented');
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError('head is not implemented');
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError('put is not implemented');
  }

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError('patch is not implemented');
  }

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError('delete is not implemented');
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError('read is not implemented');
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError('send is not implemented');
  }

  @override
  void close() {}

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) {
    throw UnimplementedError('readBytes is not implemented');
  }
}
