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

  http.Response createSuccessResponse() {
    return http.Response.bytes(
      utf8.encode(jsonEncode(createValidApiResponse())),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  setUp(() {
    mockClient = MockHttpClient();
    dataSource = GroqRemoteDataSource(
      'test-api-key',
      client: mockClient,
      sleep: _noOpSleep,
    );
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
      test('SocketException 발생 시 3회 재시도 후 NetworkException을 반환해야 한다', () async {
        mockClient.exceptionToThrow = const SocketException(
          'Connection refused',
        );

        await expectLater(
          dataSource.analyzeDiary('테스트', character: AiCharacter.warmCounselor),
          throwsA(isA<NetworkException>()),
        );
        expect(mockClient.callCount, 3);
      });

      test(
        'TimeoutException 발생 시 3회 재시도 후 NetworkException을 반환해야 한다',
        () async {
          mockClient.exceptionToThrow = TimeoutException('Request timed out');

          await expectLater(
            dataSource.analyzeDiary(
              '테스트',
              character: AiCharacter.warmCounselor,
            ),
            throwsA(isA<NetworkException>()),
          );
          expect(mockClient.callCount, 3);
        },
      );

      test('두 번의 SocketException 후 성공하면 분석 결과를 반환해야 한다', () async {
        final customClient = _SequenceClient(
          steps: [
            const SocketException('Connection refused'),
            const SocketException('Connection refused'),
            createSuccessResponse(),
          ],
        );
        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
          sleep: _noOpSleep,
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 3);
      });

      test('한 번의 TimeoutException 후 성공하면 분석 결과를 반환해야 한다', () async {
        final customClient = _SequenceClient(
          steps: [
            TimeoutException('Request timed out'),
            createSuccessResponse(),
          ],
        );
        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
          sleep: _noOpSleep,
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
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
          sleep: _noOpSleep,
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
      });

      test('Retry-After 헤더(초 단위)를 파싱해야 한다', () async {
        final delays = <Duration>[];
        final customClient = _RetryAfterMockHttpClient(
          responses: [
            http.Response('Rate limit', 429, headers: {'retry-after': '5'}),
            createSuccessResponse(),
          ],
        );
        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
          sleep: (duration) async {
            delays.add(duration);
          },
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
        expect(delays, [const Duration(seconds: 5)]);
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
          sleep: _noOpSleep,
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
        mockClient.setErrorResponse(429);
        final delays = <Duration>[];
        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: mockClient,
          sleep: (duration) async {
            delays.add(duration);
          },
        );

        await expectLater(
          customDataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          ),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 429),
          ),
        );
        expect(mockClient.callCount, 3);
        expect(delays, [
          const Duration(seconds: 1),
          const Duration(seconds: 2),
        ]);
      });

      test('Retry-After가 초 단위 숫자이면 파싱해야 한다', () async {
        final delays = <Duration>[];
        final customClient = _RetryAfterMockHttpClient(
          responses: [
            http.Response('Rate limit', 429, headers: {'retry-after': '2'}),
            createSuccessResponse(),
          ],
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
          sleep: (duration) async {
            delays.add(duration);
          },
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
        expect(delays, [const Duration(seconds: 2)]);
      });

      test('Retry-After가 HTTP-date 형식이면 파싱해야 한다', () async {
        final delays = <Duration>[];
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
            createSuccessResponse(),
          ],
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
          sleep: (duration) async {
            delays.add(duration);
          },
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
        expect(delays, hasLength(1));
        expect(delays.single.inMilliseconds, inInclusiveRange(1000, 2500));
      });

      test('Retry-After가 과거 HTTP-date이면 기본 지연을 사용해야 한다', () async {
        final delays = <Duration>[];
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
            createSuccessResponse(),
          ],
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
          sleep: (duration) async {
            delays.add(duration);
          },
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
        expect(delays, [const Duration(seconds: 1)]);
      });

      test('Retry-After가 300초를 초과하면 5분으로 제한해야 한다', () async {
        final delays = <Duration>[];
        final customClient = _RetryAfterMockHttpClient(
          responses: [
            http.Response('Rate limit', 429, headers: {'retry-after': '600'}),
            createSuccessResponse(),
          ],
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
          sleep: (duration) async {
            delays.add(duration);
          },
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
        expect(delays, [const Duration(minutes: 5)]);
      });

      test('Retry-After가 잘못된 형식이면 기본값을 사용해야 한다', () async {
        final delays = <Duration>[];
        final customClient = _RetryAfterMockHttpClient(
          responses: [
            http.Response(
              'Rate limit',
              429,
              headers: {'retry-after': 'invalid-format'},
            ),
            createSuccessResponse(),
          ],
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
          sleep: (duration) async {
            delays.add(duration);
          },
        );

        final result = await customDataSource.analyzeDiary(
          '테스트',
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
        expect(delays, [const Duration(seconds: 1)]);
      });
    });

    group('네트워크/타임아웃 예외 처리', () {
      test('SocketException 발생 시 최종 NetworkException 메시지를 유지해야 한다', () async {
        final directClient = _DirectExceptionClient(
          exceptionFactory: () => const SocketException('Connection refused'),
        );
        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: directClient,
          sleep: _noOpSleep,
        );

        try {
          await customDataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('NetworkException이 발생해야 합니다');
        } catch (e) {
          expect(e, isA<NetworkException>());
          expect((e as NetworkException).message, contains('네트워크 연결에 실패했습니다.'));
          expect(directClient.callCount, 3);
        }
      });

      test('TimeoutException 발생 시 최종 NetworkException 메시지를 유지해야 한다', () async {
        final directClient = _DirectExceptionClient(
          exceptionFactory: () => TimeoutException('Request timed out'),
        );

        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: directClient,
          sleep: _noOpSleep,
        );

        try {
          await customDataSource.analyzeDiary(
            '테스트',
            character: AiCharacter.warmCounselor,
          );
          fail('NetworkException이 발생해야 합니다');
        } catch (e) {
          expect(e, isA<NetworkException>());
          expect((e as NetworkException).message, contains('요청 시간이 초과되었습니다.'));
          expect(directClient.callCount, 3);
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

      test('Vision 요청에 reasoning_effort none을 포함해야 한다', () async {
        // qwen3.6-27b 기본 thinking 모드가 completion 예산을 소진해
        // json_validate_failed(400)이 발생하는 회귀 방지
        mockClient.setSuccessResponse(createValidApiResponse());

        await dataSource.analyzeDiaryWithImages(
          '오늘 산책하며 예쁜 꽃을 봤다',
          imagePaths: [tempImagePath],
          character: AiCharacter.warmCounselor,
        );

        final body =
            jsonDecode(mockClient.calledBodies.first as String)
                as Map<String, dynamic>;
        expect(body['reasoning_effort'], 'none');
        expect(body['response_format'], {'type': 'json_object'});
      });

      test('이미지가 4장이어도 Vision 요청에는 최대 3장만 포함해야 한다', () async {
        // qwen3.6-27b는 요청당 이미지 3장 제한 — 초과 시 400
        mockClient.setSuccessResponse(createValidApiResponse());
        final extraPaths = List.generate(4, (i) {
          final path = '${tempDir.path}/test_image_$i.png';
          File(path).writeAsBytesSync(File(tempImagePath).readAsBytesSync());
          return path;
        });

        await dataSource.analyzeDiaryWithImages(
          '오늘 산책하며 사진을 많이 찍었다',
          imagePaths: extraPaths,
          character: AiCharacter.warmCounselor,
        );

        final body =
            jsonDecode(mockClient.calledBodies.first as String)
                as Map<String, dynamic>;
        final userContent =
            ((body['messages'] as List)[1] as Map<String, dynamic>)['content']
                as List;
        final imageParts = userContent.whereType<Map<String, dynamic>>().where(
          (part) => part['type'] == 'image_url',
        );
        expect(
          imageParts.length,
          GroqRemoteDataSource.maxImagesPerVisionRequest,
        );
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

      test(
        'TimeoutException 발생 시 3회 재시도 후 NetworkException을 반환해야 한다',
        () async {
          final directClient = _DirectExceptionClient(
            exceptionFactory: () => TimeoutException('Request timed out'),
          );
          final customDataSource = GroqRemoteDataSource(
            'test-api-key',
            client: directClient,
            sleep: _noOpSleep,
          );

          await expectLater(
            customDataSource.analyzeDiaryWithImages(
              '테스트',
              imagePaths: [tempImagePath],
              character: AiCharacter.warmCounselor,
            ),
            throwsA(isA<NetworkException>()),
          );
          expect(directClient.callCount, 3);
        },
      );

      test('SocketException 발생 시 3회 재시도 후 NetworkException을 반환해야 한다', () async {
        final directClient = _DirectExceptionClient(
          exceptionFactory: () => const SocketException('Connection refused'),
        );
        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: directClient,
          sleep: _noOpSleep,
        );

        await expectLater(
          customDataSource.analyzeDiaryWithImages(
            '테스트',
            imagePaths: [tempImagePath],
            character: AiCharacter.warmCounselor,
          ),
          throwsA(isA<NetworkException>()),
        );
        expect(directClient.callCount, 3);
      });

      test('두 번의 SocketException 후 성공하면 이미지 분석 결과를 반환해야 한다', () async {
        final customClient = _SequenceClient(
          steps: [
            const SocketException('Connection refused'),
            const SocketException('Connection refused'),
            createSuccessResponse(),
          ],
        );
        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
          sleep: _noOpSleep,
        );

        final result = await customDataSource.analyzeDiaryWithImages(
          '테스트',
          imagePaths: [tempImagePath],
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 3);
      });

      test('한 번의 TimeoutException 후 성공하면 이미지 분석 결과를 반환해야 한다', () async {
        final customClient = _SequenceClient(
          steps: [
            TimeoutException('Request timed out'),
            createSuccessResponse(),
          ],
        );
        final customDataSource = GroqRemoteDataSource(
          'test-api-key',
          client: customClient,
          sleep: _noOpSleep,
        );

        final result = await customDataSource.analyzeDiaryWithImages(
          '테스트',
          imagePaths: [tempImagePath],
          character: AiCharacter.warmCounselor,
        );

        expect(result, isNotNull);
        expect(customClient.callCount, 2);
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
          sleep: _noOpSleep,
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

Future<void> _noOpSleep(Duration duration) async {}

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

class _SequenceClient implements http.Client {
  final List<Object> steps;
  int callCount = 0;

  _SequenceClient({required this.steps});

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final index = callCount < steps.length ? callCount : steps.length - 1;
    callCount++;

    final step = steps[index];
    if (step is http.Response) {
      return step;
    }
    if (step is Exception) {
      throw step;
    }
    if (step is Error) {
      throw step;
    }
    throw StateError('Unsupported step type: ${step.runtimeType}');
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
