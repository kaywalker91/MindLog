import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/constants/app_constants.dart';
import 'package:mindlog/core/constants/prompt_constants.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/core/utils/clock.dart';
import 'package:mindlog/data/datasources/remote/groq_remote_datasource.dart';
import 'package:mindlog/data/repositories/diary_repository_impl.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/usecases/analyze_diary_usecase.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/debug_print_helpers.dart';
import '../../mocks/mock_datasources.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const content = '오늘 사진을 찍으며 산책했다. image_url과 base64는 공부한 용어다.';
  const character = AiCharacter.warmCounselor;
  final photoBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
    'AAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
  );
  late Directory directory;
  late List<String> photos;
  late MockSqliteLocalDataSource local;
  late MockClient client;
  late DiaryRepositoryImpl repository;
  late List<http.Request> requests;
  late int responseStatus;
  late bool emergency;
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  void resetPrompt() {
    PromptConstants.setClock(FixedClock(DateTime(2026, 10, 18, 15)));
    PromptConstants.setRandom(Random(7));
  }

  setUp(() async {
    muteDebugPrint();
    resetPrompt();
    directory = await Directory.systemTemp.createTemp('diary_text_only_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return directory.path;
          }
          throw UnsupportedError(call.method);
        });
    photos = [];
    for (var i = 0; i < 5; i++) {
      final file = File('${directory.path}/private_photo_$i.png');
      await file.writeAsBytes(photoBytes);
      photos.add(file.path);
    }
    local = MockSqliteLocalDataSource();
    requests = [];
    responseStatus = 200;
    emergency = false;
    client = MockClient((request) async {
      requests.add(request);
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'keywords': ['산책', '기록', '평온', '휴식', '만족'],
                    'sentiment_score': 7,
                    'empathy_message': '차분한 하루를 보내셨군요.',
                    'action_item': '잠시 쉬어 보세요.',
                    'is_emergency': emergency,
                  }),
                },
              },
            ],
          }),
        ),
        responseStatus,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    repository = DiaryRepositoryImpl(
      localDataSource: local,
      remoteDataSource: GroqRemoteDataSource('test-key', client: client),
    );
  });

  tearDown(() async {
    client.close();
    await directory.delete(recursive: true);
    PromptConstants.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    restoreDebugPrint();
  });

  for (final count in [1, 5]) {
    test('작성 UseCase가 사진 $count장을 앱 폴더에 복사하고 글만 분석한다', () async {
      final settings = MockSettingsRepository();
      when(
        () => settings.getSelectedAiCharacter(),
      ).thenAnswer((_) async => character);
      when(() => settings.getUserName()).thenAnswer((_) async => null);
      final useCase = AnalyzeDiaryUseCase(repository, settings);

      final result = await useCase.execute(
        content,
        imagePaths: photos.take(count).toList(),
      );

      expect(result.status, DiaryStatus.analyzed);
      expect(result.imagePaths, hasLength(count));
      for (var i = 0; i < count; i++) {
        final stored = result.imagePaths![i];
        expect(stored, isNot(photos[i]));
        expect(stored, startsWith('${directory.path}/diary_images/'));
        expect(await File(stored).readAsBytes(), photoBytes);
        expect(await File(photos[i]).readAsBytes(), photoBytes);
        expect(requests.single.body, isNot(contains(stored)));
      }
      final messages =
          (jsonDecode(requests.single.body) as Map<String, dynamic>)['messages']
              as List<dynamic>;
      expect(
        messages.every(
          (dynamic m) => (m as Map<String, dynamic>)['content'] is String,
        ),
        isTrue,
      );
      expect(
        (await repository.getDiaryById(result.id))!.imagePaths,
        result.imagePaths,
      );
    });
  }

  for (final count in [0, 1, 5]) {
    test('사진 $count장도 최종 HTTP 요청은 글만 포함하고 사진은 보존한다', () async {
      final attached = photos.take(count).toList();
      final diary = await repository.createDiary(content, imagePaths: attached);
      final expectedMessages = [
        {
          'role': 'system',
          'content': PromptConstants.systemInstructionFor(character),
        },
        {
          'role': 'user',
          'content': PromptConstants.createAnalysisPrompt(
            content,
            character: character,
            userName: '서연',
          ),
        },
      ];
      resetPrompt();

      final result = await repository.analyzeDiary(
        diary.id,
        character: character,
        userName: '서연',
      );

      expect(result.status, DiaryStatus.analyzed);
      expect(requests, hasLength(1));
      final request = requests.single;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(
        request.url.toString(),
        'https://api.groq.com/openai/v1/chat/completions',
      );
      expect(body['model'], AppConstants.groqModel);
      // Exact message equality also checks that no photo count or metadata was added.
      expect(body['messages'], expectedMessages);
      expect(
        body.keys,
        unorderedEquals([
          'model',
          'messages',
          'temperature',
          'max_completion_tokens',
          'reasoning_effort',
          'include_reasoning',
          'response_format',
        ]),
      );
      for (final photo in attached) {
        expect(request.body, isNot(contains(photo)));
        expect(request.body, isNot(contains(base64Encode(photoBytes))));
        expect(await File(photo).readAsBytes(), photoBytes);
      }
      expect((await repository.getDiaryById(diary.id))!.imagePaths, attached);
    });
  }

  test('사진이 달라도 동일 글은 기존 텍스트 캐시를 재사용한다', () async {
    final withoutPhotos = await repository.createDiary(content);
    final withPhotos = await repository.createDiary(
      content,
      imagePaths: photos.reversed.toList(),
    );
    await repository.analyzeDiary(withoutPhotos.id, character: character);
    await repository.analyzeDiary(withPhotos.id, character: character);

    expect(requests, hasLength(1));
    expect(local.groqCacheSize, 1);
    expect(
      (await repository.getDiaryById(withPhotos.id))!.imagePaths,
      photos.reversed.toList(),
    );
  });

  test('텍스트 분석 실패 후 사진을 보존하고 같은 저장 일기를 글로 재시도한다', () async {
    final diary = await repository.createDiary(content, imagePaths: photos);
    responseStatus = 503;
    await expectLater(
      repository.analyzeDiary(diary.id, character: character),
      throwsA(isA<ApiFailure>().having((e) => e.statusCode, 'statusCode', 503)),
    );
    final failed = (await repository.getDiaryById(diary.id))!;
    expect(failed.status, DiaryStatus.failed);
    expect(failed.imagePaths, photos);
    expect(local.groqCacheSize, 0);
    for (final photo in photos) {
      expect(await File(photo).readAsBytes(), photoBytes);
    }
    responseStatus = 200;
    final result = await repository.analyzeDiary(
      diary.id,
      character: character,
    );
    expect(result.status, DiaryStatus.analyzed);
    expect(requests, hasLength(2));
    expect(
      (jsonDecode(requests.last.body) as Map<String, dynamic>)['model'],
      AppConstants.groqModel,
    );
  });

  test('저장된 사진 파일이 없어도 텍스트 분석은 파일을 읽지 않는다', () async {
    final diary = await repository.createDiary(
      content,
      imagePaths: ['${directory.path}/missing.png'],
    );
    final result = await repository.analyzeDiary(
      diary.id,
      character: character,
    );
    expect(result.status, DiaryStatus.analyzed);
    expect(requests, hasLength(1));
  });

  test('사진 첨부 일기의 emergency 응답도 캐시하지 않는다', () async {
    emergency = true;
    final diary = await repository.createDiary(content, imagePaths: photos);
    await repository.analyzeDiary(diary.id, character: character);
    await repository.analyzeDiary(diary.id, character: character);
    expect(requests, hasLength(2));
    expect(local.groqCacheSize, 0);
  });

  test('기존 사진과 분석 결과는 열람만으로 변경하거나 다시 요청하지 않는다', () async {
    final result = AnalysisResult(
      keywords: const ['기존'],
      sentimentScore: 8,
      empathyMessage: '기존 사진 분석',
      actionItem: '산책',
      analyzedAt: DateTime(2026, 8, 1),
    );
    final saved = Diary(
      id: 'legacy',
      content: content,
      createdAt: DateTime(2026, 8, 1),
      status: DiaryStatus.analyzed,
      imagePaths: photos,
      analysisResult: result,
    );
    local.addDiary(saved);
    expect(await repository.getDiaryById(saved.id), saved);
    expect(requests, isEmpty);
    for (final photo in photos) {
      expect(await File(photo).readAsBytes(), photoBytes);
    }
  });
  test('기존 비전 캐시는 보존하되 새 텍스트 분석에는 재사용하지 않는다', () async {
    // Recorded v1.4.64 Vision key for this content, character and image path.
    const legacyKey =
        '5444fdd9f4a6257d8c4af6f95e65bb48cc126f6cf51762b57990010399674040';
    final legacyJson = jsonEncode({
      'keywords': ['과거'],
      'sentiment_score': 2,
      'empathy_message': '과거 사진 분석',
      'action_item': '기존 결과',
      'is_emergency': false,
    });
    await local.putGroqCachedResponse(legacyKey, legacyJson);
    final diary = await repository.createDiary(
      '예전에 사진과 함께 분석했던 일기입니다.',
      imagePaths: ['/legacy/photo.png'],
    );
    final result = await repository.analyzeDiary(
      diary.id,
      character: character,
    );
    expect(requests, hasLength(1));
    expect(result.analysisResult!.sentimentScore, 7);
    expect(await local.getGroqCachedResponse(legacyKey), legacyJson);
    expect(local.groqCacheSize, 2);
  });
}
