import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/constants/app_constants.dart';
import 'package:mindlog/data/datasources/local/sqlite_local_datasource.dart';
import 'package:mindlog/data/datasources/remote/groq_remote_datasource.dart';
import 'package:mindlog/data/repositories/diary_repository_impl.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/usecases/analyze_diary_usecase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../test/mocks/mock_repositories.dart';

/// Native SQLite + photo storage + final HTTP request contract.
/// Run only on a disposable test device; no API key or external photo service needed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('0/1/5 photos stay local while the diary text is analyzed', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final temp = await getTemporaryDirectory();
      final source = await Directory(temp.path).createTemp('photo_text_smoke_');
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
      );
      final database = await openDatabase(
        inMemoryDatabasePath,
        version: 8,
        onCreate: SqliteLocalDataSource.onCreate,
      );
      SqliteLocalDataSource.testDatabase = database;
      final local = SqliteLocalDataSource();
      final copied = <String>{};
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': jsonEncode({
                      'keywords': ['산책', '휴식', '평온', '기록', '만족'],
                      'sentiment_score': 7,
                      'empathy_message': '편안한 하루였군요.',
                      'action_item': '잠시 쉬어 보세요.',
                      'is_emergency': false,
                    }),
                  },
                },
              ],
            }),
          ),
          200,
        );
      });
      try {
        final settings = MockSettingsRepository();
        when(
          () => settings.getSelectedAiCharacter(),
        ).thenAnswer((_) async => AiCharacter.warmCounselor);
        when(() => settings.getUserName()).thenAnswer((_) async => null);
        final repository = DiaryRepositoryImpl(
          localDataSource: local,
          remoteDataSource: GroqRemoteDataSource(
            'synthetic-test-key',
            client: client,
          ),
        );
        final useCase = AnalyzeDiaryUseCase(repository, settings);
        for (final count in [0, 1, 5]) {
          await local
              .clearGroqCache(); // This isolated database must exercise a real cache miss.
          final paths = <String>[];
          for (var i = 0; i < count; i++) {
            final file = File('${source.path}/photo_$i.png');
            await file.writeAsBytes(bytes);
            paths.add(file.path);
          }
          final result = await useCase.execute(
            '오늘 산책하며 사진을 남겼다. 마음이 편안해졌다.',
            imagePaths: paths,
          );
          copied.addAll(result.imagePaths ?? const []);
          expect(result.status, DiaryStatus.analyzed);
          expect(result.imagePaths ?? const [], hasLength(count));
          final persisted = (await repository.getDiaryById(result.id))!;
          expect(persisted.imagePaths ?? const [], hasLength(count));
          expect(persisted.analysisResult, isNotNull);
          final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
          expect(body['model'], AppConstants.groqModel);
          expect(
            (body['messages'] as List).every(
              (dynamic m) => (m as Map<String, dynamic>)['content'] is String,
            ),
            isTrue,
          );
          for (final path in persisted.imagePaths ?? const <String>[]) {
            expect(await File(path).readAsBytes(), bytes);
            expect(requests.last.body, isNot(contains(path)));
          }
          expect(requests.last.body, isNot(contains(base64Encode(bytes))));
        }
        expect(requests, hasLength(3));
      } finally {
        // Never open, clear, or delete the application's real database.
        for (final diary in await local.getAllDiaries()) {
          copied.addAll(diary.imagePaths ?? const []);
        }
        for (final path in copied) {
          final file = File(path);
          if (await file.exists()) await file.delete();
          final folder = file.parent;
          if (await folder.exists() && await folder.list().isEmpty) {
            await folder.delete();
          }
        }
        SqliteLocalDataSource.testDatabase = null;
        await database.close();
        client.close();
        await source.delete(recursive: true);
      }
    });
  });
}
