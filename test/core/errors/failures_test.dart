import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';

void main() {
  group('Failure 타입들', () {
    group('NetworkFailure', () {
      test('기본 displayMessage를 반환한다', () {
        const failure = NetworkFailure();
        expect(failure.displayMessage, '네트워크 연결을 확인해주세요.');
      });

      test('커스텀 메시지를 반환한다', () {
        const failure = NetworkFailure(message: 'WiFi 연결 끊김');
        expect(failure.displayMessage, 'WiFi 연결 끊김');
      });
    });

    group('ApiFailure', () {
      test('기본 displayMessage를 반환한다', () {
        const failure = ApiFailure();
        expect(failure.displayMessage, 'API 호출 중 오류가 발생했습니다.');
      });

      test('상태 코드를 저장한다', () {
        const failure = ApiFailure(message: 'Not Found', statusCode: 404);
        expect(failure.statusCode, 404);
        expect(failure.displayMessage, 'Not Found');
      });
    });

    group('CacheFailure', () {
      test('기본 displayMessage를 반환한다', () {
        const failure = CacheFailure();
        expect(failure.displayMessage, '데이터 저장 중 오류가 발생했습니다.');
      });
    });

    group('ServerFailure', () {
      test('기본 displayMessage를 반환한다', () {
        const failure = ServerFailure();
        expect(failure.displayMessage, '서버 오류가 발생했습니다.');
      });
    });

    group('DataNotFoundFailure', () {
      test('기본 displayMessage를 반환한다', () {
        const failure = DataNotFoundFailure();
        expect(failure.displayMessage, '데이터를 찾을 수 없습니다.');
      });

      test('커스텀 메시지를 반환한다', () {
        const failure = DataNotFoundFailure(message: '일기를 찾을 수 없습니다');
        expect(failure.displayMessage, '일기를 찾을 수 없습니다');
      });
    });

    group('ValidationFailure', () {
      test('전달받은 메시지를 반환한다', () {
        const failure = ValidationFailure(message: '내용을 입력해주세요');
        expect(failure.displayMessage, '내용을 입력해주세요');
      });
    });

    group('SafetyBlockedFailure', () {
      test('기본 displayMessage를 반환한다', () {
        const failure = SafetyBlockedFailure();
        expect(failure.displayMessage, '안전상의 이유로 분석이 중단되었습니다.');
      });
    });

    group('UnknownFailure', () {
      test('기본 displayMessage를 반환한다', () {
        const failure = UnknownFailure();
        expect(failure.displayMessage, '알 수 없는 오류가 발생했습니다.');
      });

      test('커스텀 메시지를 반환한다', () {
        const failure = UnknownFailure(message: '예상치 못한 오류');
        expect(failure.displayMessage, '예상치 못한 오류');
      });
    });
  });

  group('Failure 패턴 매칭', () {
    test('sealed class로 exhaustive 패턴 매칭이 가능하다', () {
      const Failure failure = NetworkFailure();

      final message = switch (failure) {
        NetworkFailure() => 'network',
        ApiFailure() => 'api',
        CacheFailure() => 'cache',
        ServerFailure() => 'server',
        DataNotFoundFailure() => 'not_found',
        ValidationFailure() => 'validation',
        SafetyBlockedFailure() => 'safety',
        ImageProcessingFailure() => 'image_processing',
        UnknownFailure() => 'unknown',
      };

      expect(message, 'network');
    });

    test('Factory 생성자로 생성해도 올바른 타입이다', () {
      const Failure failure = Failure.network(message: 'test');

      expect(failure, isA<NetworkFailure>());
      expect(failure.displayMessage, 'test');
    });
  });
}
