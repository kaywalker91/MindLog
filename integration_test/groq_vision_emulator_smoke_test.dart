import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/core/errors/exceptions.dart';
import 'package:mindlog/data/datasources/remote/groq_remote_datasource.dart';
import 'package:path_provider/path_provider.dart';

/// 에뮬레이터 실기 Groq Vision API 스모크 테스트
///
/// 실행:
///   GROQ_API_KEY=xxx fvm flutter test integration_test/groq_vision_emulator_smoke_test.dart \
///     -d emulator-5554 --dart-define=GROQ_API_KEY=xxx
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const apiKey = String.fromEnvironment('GROQ_API_KEY');
  const diaryText = '오늘 산책하며 예쁜 풍경을 사진으로 남겼다. 마음이 조금 편안해졌다.';

  late GroqRemoteDataSource dataSource;
  late List<String> allImagePaths;

  setUpAll(() async {
    if (apiKey.isEmpty) {
      throw StateError('GROQ_API_KEY dart-define가 필요합니다.');
    }
    dataSource = GroqRemoteDataSource(apiKey);

    final dir = await getTemporaryDirectory();
    final imageDir = Directory('${dir.path}/vision_smoke');
    if (await imageDir.exists()) {
      await imageDir.delete(recursive: true);
    }
    await imageDir.create(recursive: true);

    allImagePaths = [];
    for (var i = 0; i < 4; i++) {
      final response = await http.get(
        Uri.parse('https://picsum.photos/2400/1800?random=$i'),
      );
      if (response.statusCode != 200) {
        throw StateError('테스트 이미지 다운로드 실패: photo_$i (${response.statusCode})');
      }
      final path = '${imageDir.path}/photo_$i.jpg';
      await File(path).writeAsBytes(response.bodyBytes);
      allImagePaths.add(path);
    }
  });

  Future<Map<String, dynamic>> runVisionCase({
    required String label,
    required int attachedCount,
  }) async {
    // 앱 정책: 저장은 N장, Vision API 전송은 대표 1장 (datasource 클램프)
    final paths = allImagePaths.sublist(0, attachedCount);
    final started = DateTime.now();
    try {
      final result = await dataSource.analyzeDiaryWithImages(
        diaryText,
        imagePaths: paths,
        character: AiCharacter.warmCounselor,
      );
      return {
        'label': label,
        'attachedCount': attachedCount,
        'apiImageCount': 1,
        'status': 'success',
        'elapsedMs': DateTime.now().difference(started).inMilliseconds,
        'keywords': result.keywords.take(3).join(', '),
        'sentiment': result.sentimentScore,
      };
    } on ApiException catch (e) {
      return {
        'label': label,
        'attachedCount': attachedCount,
        'status': 'api_error',
        'statusCode': e.statusCode,
        'message': e.message,
        'elapsedMs': DateTime.now().difference(started).inMilliseconds,
      };
    } catch (e) {
      return {
        'label': label,
        'attachedCount': attachedCount,
        'status': 'error',
        'message': e.toString(),
        'elapsedMs': DateTime.now().difference(started).inMilliseconds,
      };
    }
  }

  testWidgets('Groq Vision — 1/2/4장 에뮬레이터 실측', (tester) async {
    final results = <Map<String, dynamic>>[];

    results.add(await runVisionCase(label: '1장', attachedCount: 1));
    await Future<void>.delayed(const Duration(seconds: 35));

    results.add(await runVisionCase(label: '2장(클램프1)', attachedCount: 2));
    await Future<void>.delayed(const Duration(seconds: 35));

    results.add(await runVisionCase(label: '4장(클램프1)', attachedCount: 4));

    // ignore: avoid_print
    print('\n===== GROQ VISION EMULATOR SMOKE RESULTS =====');
    for (final r in results) {
      // ignore: avoid_print
      print(r);
    }
    // ignore: avoid_print
    print('==============================================\n');

    final failures = results.where((r) => r['status'] != 'success').toList();
    expect(failures, isEmpty, reason: 'Vision 실패: $failures');
  });
}
