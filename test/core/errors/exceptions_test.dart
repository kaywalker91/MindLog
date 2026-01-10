import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/exceptions.dart';

void main() {
  group('NetworkException', () {
    test('메시지 없이 생성할 수 있다', () {
      final exception = NetworkException();
      expect(exception.message, isNull);
    });

    test('메시지와 함께 생성할 수 있다', () {
      final exception = NetworkException('연결 실패');
      expect(exception.message, '연결 실패');
    });

    test('toString이 올바른 형식을 반환한다', () {
      final exception = NetworkException('test');
      expect(exception.toString(), 'NetworkException: test');
    });
  });

  group('ApiException', () {
    test('메시지와 상태 코드 없이 생성할 수 있다', () {
      final exception = ApiException();
      expect(exception.message, isNull);
      expect(exception.statusCode, isNull);
    });

    test('메시지와 상태 코드와 함께 생성할 수 있다', () {
      final exception = ApiException(message: 'Not Found', statusCode: 404);
      expect(exception.message, 'Not Found');
      expect(exception.statusCode, 404);
    });

    test('toString이 올바른 형식을 반환한다', () {
      final exception = ApiException(message: 'Error', statusCode: 500);
      expect(exception.toString(), 'ApiException: Error (status: 500)');
    });
  });

  group('CacheException', () {
    test('메시지 없이 생성할 수 있다', () {
      final exception = CacheException();
      expect(exception.message, isNull);
    });

    test('메시지와 함께 생성할 수 있다', () {
      final exception = CacheException('저장 실패');
      expect(exception.message, '저장 실패');
    });

    test('toString이 올바른 형식을 반환한다', () {
      final exception = CacheException('test');
      expect(exception.toString(), 'CacheException: test');
    });
  });

  group('DataNotFoundException', () {
    test('메시지 없이 생성할 수 있다', () {
      final exception = DataNotFoundException();
      expect(exception.message, isNull);
    });

    test('메시지와 함께 생성할 수 있다', () {
      final exception = DataNotFoundException('일기를 찾을 수 없습니다');
      expect(exception.message, '일기를 찾을 수 없습니다');
    });

    test('toString이 올바른 형식을 반환한다', () {
      final exception = DataNotFoundException('test');
      expect(exception.toString(), 'DataNotFoundException: test');
    });
  });

  group('SafetyBlockException', () {
    test('메시지 없이 생성할 수 있다', () {
      final exception = SafetyBlockException();
      expect(exception.message, isNull);
    });

    test('메시지와 함께 생성할 수 있다', () {
      final exception = SafetyBlockException('유해 콘텐츠 감지');
      expect(exception.message, '유해 콘텐츠 감지');
    });

    test('toString은 항상 고정된 메시지를 반환한다', () {
      final exception = SafetyBlockException('custom');
      expect(
        exception.toString(),
        'SafetyBlockException: Content blocked for safety reasons',
      );
    });
  });
}
