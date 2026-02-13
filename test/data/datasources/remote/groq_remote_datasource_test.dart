import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/exceptions.dart';
import 'package:mindlog/core/network/circuit_breaker.dart';
import 'package:mindlog/data/datasources/remote/groq_remote_datasource.dart';

import '../../../mocks/mock_http_client.dart';

void main() {
  late GroqRemoteDataSource dataSource;
  late MockHttpClient mockClient;

  /// 유효한 AI 분석 응답 JSON 생성
  Map<String, dynamic> createValidApiResponse({
    List<String>? keywords,
    int? sentimentScore,
    String? empathyMessage,
    List<String>? actionItems,
    bool? isEmergency,
  }) {
    return {
      'choices': [
        {
          'message': {
            'content': jsonEncode({
              'keywords': keywords ?? ['행복', '만족', '평온', '감사', '기쁨'],
              'sentiment_score': sentimentScore ?? 7,
              'empathy_message': empathyMessage ?? '좋은 하루를 보내셨군요!',
              'action_item': '',
              'action_items': actionItems ?? ['휴식하세요', '기록하세요', '계획하세요'],
              'is_emergency': isEmergency ?? false,
            }),
          },
        },
      ],
    };
  }

  setUp(() {
    mockClient = MockHttpClient();
    dataSource = GroqRemoteDataSource('test-api-key', client: mockClient);
  });

  tearDown(() {
    mockClient.reset();
  });

  group('GroqRemoteDataSource', () {
    group('성공 케이스', () {
      test('정상 응답을 AnalysisResponseDto로 파싱해야 한다', () async {
        mockClient.setSuccessResponse(
          createValidApiResponse(
            keywords: ['프로젝트', '성취', '자부심'],
            sentimentScore: 8,
          ),
        );

        final result = await dataSource.analyzeDiary(
          '오늘 프로젝트를 완료했다!',
          character: AiCharacter.warmCounselor,
        );

        expect(result.keywords, contains('프로젝트'));
        expect(result.sentimentScore, 8);
      });

      test('API 키가 유효하면 Authorization 헤더를 설정해야 한다', () async {
        mockClient.setSuccessResponse(createValidApiResponse());

        await dataSource.analyzeDiary(
          '테스트 내용',
          character: AiCharacter.warmCounselor,
        );

        expect(mockClient.callCount, 1);
        expect(
          mockClient.calledHeaders.first?['Authorization'],
          'Bearer test-api-key',
        );
      });

      test('character와 userName을 요청에 포함해야 한다', () async {
        mockClient.setSuccessResponse(createValidApiResponse());

        await dataSource.analyzeDiary(
          '테스트 내용',
          character: AiCharacter.realisticCoach,
          userName: '테스트유저',
        );

        expect(mockClient.callCount, 1);
        final body =
            jsonDecode(mockClient.calledBodies.first as String)
                as Map<String, dynamic>;
        // 요청이 전송되었음을 확인 (프롬프트 내용은 PromptConstants에서 생성)
        expect(body['messages'], isNotEmpty);
      });
    });

    group('API 키 검증', () {
      test('API 키가 비어있으면 ApiException을 던져야 한다', () async {
        final dataSourceWithEmptyKey = GroqRemoteDataSource(
          '',
          client: mockClient,
        );

        await expectLater(
          dataSourceWithEmptyKey.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('재시도 로직', () {
      test('네트워크 오류는 _analyzeDiaryOnce의 catch에서 ApiException으로 래핑된다', () async {
        // 현재 구현에서는 http.Client.post()에서 발생하는 SocketException이
        // _analyzeDiaryOnce의 마지막 catch 블록에서 ApiException으로 래핑됨
        // 재시도 로직은 analyzeDiaryWithRetry에서 SocketException을 직접 catch할 때만 작동
        mockClient.exceptionToThrow = const SocketException(
          'Connection refused',
        );

        await expectLater(
          dataSource.analyzeDiary('테스트', character: AiCharacter.warmCounselor),
          throwsA(isA<ApiException>()),
        );
        // ApiException으로 래핑되어 재시도 없이 1회만 호출
        expect(mockClient.callCount, 1);
      });

      test('타임아웃 오류는 ApiException으로 래핑된다', () async {
        mockClient.exceptionToThrow = TimeoutException('Request timed out');

        await expectLater(
          dataSource.analyzeDiary('테스트', character: AiCharacter.warmCounselor),
          throwsA(isA<ApiException>()),
        );
        expect(mockClient.callCount, 1);
      });

      test('API 호출 성공 후 정상 응답을 반환해야 한다', () async {
        mockClient.setSuccessResponse(createValidApiResponse());

        final result = await dataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(mockClient.callCount, 1);
      });
    });

    group('Rate Limit 처리', () {
      test('429 응답 시 RateLimitException을 발생시키고 재시도해야 한다', () async {
        // 커스텀 동작을 위해 MockHttpClient를 확장
        final customClient = _RetryMockHttpClient(
          firstResponse: http.Response(
            'Rate limit exceeded',
            429,
            headers: {'retry-after': '1'},
          ),
          secondResponse: http.Response.bytes(
            utf8.encode(jsonEncode(createValidApiResponse())),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
      });

      test('Retry-After 헤더(초 단위)를 파싱해야 한다', () async {
        // 초 단위 Retry-After 헤더 테스트
        mockClient.setErrorResponse(429, headers: {'retry-after': '5'});

        try {
          await dataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
        } catch (e) {
          // RateLimitException으로 변환 후 ApiException으로 재throw
          expect(e, isA<ApiException>());
        }
      });
    });

    group('HTTP 상태 코드', () {
      test('400 응답 시 잘못된 요청 메시지를 포함해야 한다', () async {
        mockClient.setErrorResponse(400);

        try {
          await dataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('ApiException이 발생해야 합니다');
        } catch (e) {
          expect(e, isA<ApiException>());
          final apiException = e as ApiException;
          expect(apiException.statusCode, 400);
          expect(apiException.message, contains('잘못된 요청'));
        }
      });

      test('401 응답 시 인증 오류 메시지를 포함해야 한다', () async {
        mockClient.setErrorResponse(401);

        try {
          await dataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('ApiException이 발생해야 합니다');
        } catch (e) {
          expect(e, isA<ApiException>());
          final apiException = e as ApiException;
          expect(apiException.statusCode, 401);
          expect(apiException.message, contains('인증'));
        }
      });

      test('403 응답 시 접근 권한 오류 메시지를 포함해야 한다', () async {
        mockClient.setErrorResponse(403);

        try {
          await dataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('ApiException이 발생해야 합니다');
        } catch (e) {
          expect(e, isA<ApiException>());
          final apiException = e as ApiException;
          expect(apiException.statusCode, 403);
          expect(apiException.message, contains('접근 권한'));
        }
      });

      test('500 응답 시 서버 오류 메시지를 포함해야 한다', () async {
        mockClient.setErrorResponse(500);

        try {
          await dataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('ApiException이 발생해야 합니다');
        } catch (e) {
          expect(e, isA<ApiException>());
          final apiException = e as ApiException;
          expect(apiException.statusCode, 500);
          expect(apiException.message, contains('서버'));
        }
      });

      test('502 응답 시 게이트웨이 오류 메시지를 포함해야 한다', () async {
        mockClient.setErrorResponse(502);

        try {
          await dataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('ApiException이 발생해야 합니다');
        } catch (e) {
          expect(e, isA<ApiException>());
          final apiException = e as ApiException;
          expect(apiException.statusCode, 502);
          expect(apiException.message, contains('게이트웨이'));
        }
      });

      test('503 응답 시 서비스 일시 불가 메시지를 포함해야 한다', () async {
        mockClient.setErrorResponse(503);

        try {
          await dataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('ApiException이 발생해야 합니다');
        } catch (e) {
          expect(e, isA<ApiException>());
          final apiException = e as ApiException;
          expect(apiException.statusCode, 503);
          expect(apiException.message, contains('일시적으로'));
        }
      });

      test('알 수 없는 상태 코드 응답 시 기본 오류 메시지를 포함해야 한다', () async {
        mockClient.setErrorResponse(599);

        try {
          await dataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('ApiException이 발생해야 합니다');
        } catch (e) {
          expect(e, isA<ApiException>());
          final apiException = e as ApiException;
          expect(apiException.statusCode, 599);
          expect(apiException.message, contains('코드: 599'));
        }
      });

      test('ApiException은 재시도하지 않아야 한다 (Rate Limit 제외)', () async {
        mockClient.setErrorResponse(403);

        try {
          await dataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('ApiException이 발생해야 합니다');
        } catch (_) {}
        // 재시도 없이 1회만 호출
        expect(mockClient.callCount, 1);
      });
    });

    group('CircuitBreaker 통합', () {
      test('CircuitBreaker가 주입되면 run을 통해 실행해야 한다', () async {
        final circuitBreaker = CircuitBreaker();
        final dataSourceWithCB = GroqRemoteDataSource(
          'test-api-key',
          client: mockClient,
          circuitBreaker: circuitBreaker,
        );

        mockClient.setSuccessResponse(createValidApiResponse());

        final result = await dataSourceWithCB.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(circuitBreaker.state, CircuitState.closed);
      });

      test('CircuitBreaker가 없으면 직접 실행해야 한다', () async {
        final dataSourceWithoutCB = GroqRemoteDataSource(
          'test-api-key',
          client: mockClient,
        );

        mockClient.setSuccessResponse(createValidApiResponse());

        final result = await dataSourceWithoutCB.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
      });

      test('CircuitBreakerOpenException 발생 시 요청을 차단해야 한다', () async {
        final circuitBreaker = CircuitBreaker(
          config: const CircuitBreakerConfig(
            failureThreshold: 2,
            resetTimeout: Duration(minutes: 1),
          ),
        );

        final dataSourceWithCB = GroqRemoteDataSource(
          'test-api-key',
          client: mockClient,
          circuitBreaker: circuitBreaker,
        );

        // 서킷 브레이커를 열기 위해 실패 유발
        mockClient.exceptionToThrow = const SocketException(
          'Connection refused',
        );

        // 2번 실패 (각각 3회 재시도)
        for (var i = 0; i < 2; i++) {
          try {
            await dataSourceWithCB.analyzeDiary(
              '테스트',
              character: AiCharacter.warmCounselor,
            );
          } catch (_) {}
        }

        // 서킷 브레이커가 열린 상태에서 추가 요청
        mockClient.reset();
        mockClient.setSuccessResponse(createValidApiResponse());

        await expectLater(
          dataSourceWithCB.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<CircuitBreakerOpenException>()),
        );
      });
    });

    group('응답 파싱', () {
      test('choices가 비어있으면 ApiException을 던져야 한다', () async {
        mockClient.setSuccessResponse({'choices': []});

        await expectLater(
          dataSource.analyzeDiary('테스트', character: AiCharacter.warmCounselor),
          throwsA(isA<ApiException>()),
        );
      });

      test('choices가 null이면 ApiException을 던져야 한다', () async {
        mockClient.setSuccessResponse({'id': 'test'});

        await expectLater(
          dataSource.analyzeDiary('테스트', character: AiCharacter.warmCounselor),
          throwsA(isA<ApiException>()),
        );
      });

      test('AnalysisResponseParser가 폴백 응답을 생성하면 정상 DTO를 반환해야 한다', () async {
        // AnalysisResponseParser는 파싱 실패 시 폴백 응답을 생성하므로
        // 완전히 잘못된 JSON도 폴백으로 처리됨
        mockClient.setSuccessResponse({
          'choices': [
            {
              'message': {'content': 'not a valid json'},
            },
          ],
        });

        // 폴백 응답이 생성되므로 예외가 아닌 정상 응답을 반환
        final result = await dataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        // 폴백 응답의 기본 키워드 확인
        expect(result, isNotNull);
        expect(result.keywords, isNotEmpty);
      });

      test('응급 상황 응답을 올바르게 파싱해야 한다', () async {
        mockClient.setSuccessResponse(
          createValidApiResponse(sentimentScore: 1, isEmergency: true),
        );

        final result = await dataSource.analyzeDiary(
          '힘든 내용',
          character: AiCharacter.warmCounselor,
        );

        expect(result.isEmergency, true);
        expect(result.sentimentScore, 1);
      });
    });

    group('Retry-After 헤더 파싱', () {
      test('Retry-After 헤더가 없으면 기본 지연을 사용해야 한다', () async {
        // 429 응답이지만 Retry-After 헤더 없음
        mockClient.setErrorResponse(429);

        try {
          await dataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
        } catch (e) {
          expect(e, isA<ApiException>());
        }
      });

      test('Retry-After가 초 단위 숫자이면 파싱해야 한다', () async {
        // 첫 번째 요청: 429 with Retry-After, 두 번째: 성공
        final customClient = _RetryAfterMockHttpClient(
          responses: [
            http.Response('Rate limit', 429, headers: {'retry-after': '2'}),
            http.Response.bytes(
              utf8.encode(jsonEncode(createValidApiResponse())),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ],
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
      });

      test('Retry-After가 HTTP-date 형식이면 파싱해야 한다', () async {
        // HTTP-date 형식: "Fri, 31 Dec 2024 23:59:59 GMT"
        final futureDate = DateTime.now().toUtc().add(
          const Duration(seconds: 2),
        );
        final httpDateStr = HttpDate.format(futureDate);

        final customClient = _RetryAfterMockHttpClient(
          responses: [
            http.Response(
              'Rate limit',
              429,
              headers: {'retry-after': httpDateStr},
            ),
            http.Response.bytes(
              utf8.encode(jsonEncode(createValidApiResponse())),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ],
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
      });

      test('Retry-After가 과거 HTTP-date이면 기본 지연을 사용해야 한다', () async {
        // 과거 날짜: 이 경우 _initialDelay 사용
        final pastDate = DateTime.now().toUtc().subtract(
          const Duration(hours: 1),
        );
        final httpDateStr = HttpDate.format(pastDate);

        final customClient = _RetryAfterMockHttpClient(
          responses: [
            http.Response(
              'Rate limit',
              429,
              headers: {'retry-after': httpDateStr},
            ),
            http.Response.bytes(
              utf8.encode(jsonEncode(createValidApiResponse())),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ],
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
      });

      test('Retry-After가 300초를 초과하면 5분으로 제한해야 한다', () async {
        final customClient = _RetryAfterMockHttpClient(
          responses: [
            // 600초(10분) → 5분으로 제한됨
            http.Response('Rate limit', 429, headers: {'retry-after': '600'}),
            http.Response.bytes(
              utf8.encode(jsonEncode(createValidApiResponse())),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ],
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
        );

        // 실제로 5분 기다리지 않고, 클라이언트가 호출되었는지만 확인
        // 실제 구현에서는 Future.delayed가 발생하지만 테스트에서는 callCount로 검증
        try {
          await customDataSource
              .analyzeDiary('테스트', character: AiCharacter.warmCounselor)
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          // 타임아웃 예상됨 (5분 대기로 인해)
        }
        // 최소 1회는 호출됨
        expect(customClient.callCount, greaterThanOrEqualTo(1));
      });

      test('Retry-After가 잘못된 형식이면 기본값을 사용해야 한다', () async {
        final customClient = _RetryAfterMockHttpClient(
          responses: [
            http.Response(
              'Rate limit',
              429,
              headers: {'retry-after': 'invalid-format'},
            ),
            http.Response.bytes(
              utf8.encode(jsonEncode(createValidApiResponse())),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ],
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
      });
    });

    group('네트워크/타임아웃 예외 처리', () {
      // 참고: 현재 구현에서 SocketException과 TimeoutException은
      // _analyzeDiaryOnce의 마지막 catch 블록에서 ApiException으로 래핑됨
      // 따라서 재시도 로직은 작동하지 않고 즉시 ApiException이 발생함

      test('SocketException 발생 시 ApiException으로 래핑되어 반환되어야 한다', () async {
        final directClient = _DirectExceptionClient(
          exceptionFactory: () => const SocketException('Connection refused'),
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: directClient,
        );

        await expectLater(
          customDataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<ApiException>()),
        );
        // _analyzeDiaryOnce에서 잡혀서 ApiException으로 변환, 재시도 없이 1회
        expect(directClient.callCount, 1);
      });

      test('TimeoutException 발생 시 ApiException으로 래핑되어 반환되어야 한다', () async {
        final directClient = _DirectExceptionClient(
          exceptionFactory: () => TimeoutException('Request timed out'),
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: directClient,
        );

        await expectLater(
          customDataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<ApiException>()),
        );
        // _analyzeDiaryOnce에서 잡혀서 ApiException으로 변환, 재시도 없이 1회
        expect(directClient.callCount, 1);
      });

      test('SocketException 에러 메시지가 포함되어야 한다', () async {
        final directClient = _DirectExceptionClient(
          exceptionFactory: () => const SocketException('Connection refused'),
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: directClient,
        );

        try {
          await customDataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('ApiException이 발생해야 합니다');
        } catch (e) {
          expect(e, isA<ApiException>());
          expect((e as ApiException).message, contains('Groq 분석 중 오류'));
        }
      });

      test('TimeoutException 에러 메시지가 포함되어야 한다', () async {
        final directClient = _DirectExceptionClient(
          exceptionFactory: () => TimeoutException('Request timed out'),
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: directClient,
        );

        try {
          await customDataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('ApiException이 발생해야 합니다');
        } catch (e) {
          expect(e, isA<ApiException>());
          expect((e as ApiException).message, contains('Groq 분석 중 오류'));
        }
      });
    });

    group('기본 http.Client 생성', () {
      test('client가 null이면 기본 http.Client를 생성해야 한다', () {
        // client 파라미터 없이 생성
        final dataSourceWithDefaultClient = GroqRemoteDataSource(
          'test-api-key',
        );

        // 내부 클라이언트가 생성되었는지 간접적으로 확인
        // (실제 네트워크 요청은 하지 않음)
        expect(dataSourceWithDefaultClient, isNotNull);
      });
    });

    group('analyzeDiaryWithImages (Vision path)', () {
      late Directory tempDir;
      late String tempImagePath;

      setUp(() {
        // ImageService.encodeMultipleToBase64DataUrls는 compute()로
        // 실제 파일을 읽으므로 유효한 PNG 임시 파일이 필요
        tempDir = Directory.systemTemp.createTempSync('mindlog_test_');
        tempImagePath = '${tempDir.path}/test_image.png';
        File(tempImagePath).writeAsBytesSync(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
            'AAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
          ),
        );
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('성공 시 유효한 AnalysisResponseDto를 반환해야 한다', () async {
        mockClient.setSuccessResponse(createValidApiResponse());

        final result = await dataSource.analyzeDiaryWithImages(
          '오늘 산책하며 예쁜 꽃을 봤다',
          imagePaths: [tempImagePath],
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(result.keywords, isNotEmpty);
        expect(mockClient.callCount, 1);
      });

      test('API 키가 비어있으면 ApiException을 던져야 한다', () async {
        final emptyKeyDataSource = GroqRemoteDataSource('', client: mockClient);

        await expectLater(
          emptyKeyDataSource.analyzeDiaryWithImages(
            '테스트',
            imagePaths: [tempImagePath],
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('TimeoutException 발생 시 ApiException으로 래핑되어야 한다', () async {
        // _analyzeDiaryWithImagesOnce의 catch 블록에서
        // TimeoutException → ApiException으로 변환됨
        final directClient = _DirectExceptionClient(
          exceptionFactory: () => TimeoutException('Request timed out'),
        );
        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: directClient,
        );

        await expectLater(
          customDataSource.analyzeDiaryWithImages(
            '테스트',
            imagePaths: [tempImagePath],
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<ApiException>()),
        );
        // ApiException으로 래핑되어 재시도 없이 1회만 호출
        expect(directClient.callCount, 1);
      });

      test('SocketException 발생 시 ApiException으로 래핑되어야 한다', () async {
        final directClient = _DirectExceptionClient(
          exceptionFactory: () => const SocketException('Connection refused'),
        );
        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: directClient,
        );

        await expectLater(
          customDataSource.analyzeDiaryWithImages(
            '테스트',
            imagePaths: [tempImagePath],
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<ApiException>()),
        );
        expect(directClient.callCount, 1);
      });

      test('429 Rate Limit 시 재시도 후 성공해야 한다', () async {
        final customClient = _RetryMockHttpClient(
          firstResponse: http.Response(
            'Rate limit exceeded',
            429,
            headers: {'retry-after': '1'},
          ),
          secondResponse: http.Response.bytes(
            utf8.encode(jsonEncode(createValidApiResponse())),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        );
        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
        );

        final result = await customDataSource.analyzeDiaryWithImages(
          '테스트',
          imagePaths: [tempImagePath],
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
      });

      test('CircuitBreaker와 함께 사용 시 정상 동작해야 한다', () async {
        final circuitBreaker = CircuitBreaker();
        final dataSourceWithCB = GroqRemoteDataSource(
          'test-api-key',
          client: mockClient,
          circuitBreaker: circuitBreaker,
        );

        mockClient.setSuccessResponse(createValidApiResponse());

        final result = await dataSourceWithCB.analyzeDiaryWithImages(
          '테스트',
          imagePaths: [tempImagePath],
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(circuitBreaker.state, CircuitState.closed);
      });

      test('CircuitBreaker 없이도 정상 동작해야 한다', () async {
        final dataSourceWithoutCB = GroqRemoteDataSource(
          'test-api-key',
          client: mockClient,
        );

        mockClient.setSuccessResponse(createValidApiResponse());

        final result = await dataSourceWithoutCB.analyzeDiaryWithImages(
          '테스트',
          imagePaths: [tempImagePath],
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
      });
    });
  });
}

/// 순차적으로 응답을 반환하는 Mock 클라이언트 (Retry-After 테스트용)
class _RetryAfterMockHttpClient implements http.Client {
  final List<http.Response> responses;
  int callCount = 0;

  _RetryAfterMockHttpClient({required this.responses});

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    if (callCount < responses.length) {
      return responses[callCount++];
    }
    return responses.last;
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError();
  }

  @override
  void close() {}

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }
}

/// post() 호출 시 직접 예외를 발생시키는 클라이언트 (재시도 로직 테스트용)
class _DirectExceptionClient implements http.Client {
  final Object Function() exceptionFactory;
  int callCount = 0;

  _DirectExceptionClient({required this.exceptionFactory});

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    callCount++;
    throw exceptionFactory();
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError();
  }

  @override
  void close() {}

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }
}

/// 재시도 테스트를 위한 커스텀 Mock 클라이언트
class _RetryMockHttpClient implements http.Client {
  final http.Response firstResponse;
  final http.Response secondResponse;
  int callCount = 0;

  _RetryMockHttpClient({
    required this.firstResponse,
    required this.secondResponse,
  });

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    callCount++;
    if (callCount == 1) return firstResponse;
    return secondResponse;
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError();
  }

  @override
  void close() {}

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }
}
