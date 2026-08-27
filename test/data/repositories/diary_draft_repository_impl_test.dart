import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/exceptions.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/data/repositories/diary_draft_repository_impl.dart';
import 'package:mindlog/domain/entities/diary_draft.dart';

import '../../mocks/mock_datasources.dart';

void main() {
  late DiaryDraftRepositoryImpl repository;
  late MockPreferencesLocalDataSource mockDataSource;

  final sampleDraft = DiaryDraft(
    content: '123456789',
    entryDate: DateTime(2026, 8, 20),
    updatedAt: DateTime(2026, 8, 20, 10),
  );

  setUp(() {
    mockDataSource = MockPreferencesLocalDataSource();
    repository = DiaryDraftRepositoryImpl(mockDataSource);
  });

  tearDown(() {
    mockDataSource.reset();
  });

  group('DiaryDraftRepositoryImpl', () {
    group('saveDraft / getDraft 왕복', () {
      test('9자 저장 후 getDraft 결과가 동일한 content여야 한다', () async {
        expect(sampleDraft.content.length, 9);

        await repository.saveDraft(sampleDraft);
        final loaded = await repository.getDraft();

        expect(loaded, isNotNull);
        expect(loaded!.content, sampleDraft.content);
        expect(loaded.entryDate, sampleDraft.entryDate);
        expect(loaded.updatedAt, sampleDraft.updatedAt);
      });

      test('저장된 초안이 없으면 null을 반환해야 한다', () async {
        final result = await repository.getDraft();

        expect(result, isNull);
      });

      test('imagePaths가 없는 초안은 그대로 반환해야 한다', () async {
        await repository.saveDraft(sampleDraft);

        final loaded = await repository.getDraft();

        expect(loaded, isNotNull);
        expect(loaded!.imagePaths, isNull);
        expect(loaded.content, sampleDraft.content);
      });
    });

    group('clearDraft', () {
      test('저장 후 삭제하면 getDraft가 null이어야 한다', () async {
        await repository.saveDraft(sampleDraft);
        expect(await repository.getDraft(), isNotNull);

        await repository.clearDraft();

        expect(await repository.getDraft(), isNull);
      });

      test('초안이 없어도 성공해야 한다', () async {
        await repository.clearDraft();

        expect(await repository.getDraft(), isNull);
      });
    });

    group('죽은 이미지 경로 필터링', () {
      late Directory tempDir;
      late File liveFile;
      late String deadPath;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('diary_draft_repo_');
        liveFile = File('${tempDir.path}/live.jpg');
        await liveFile.writeAsString('live-image-bytes');
        deadPath = '${tempDir.path}/dead_missing.jpg';
        expect(liveFile.existsSync(), isTrue);
        expect(File(deadPath).existsSync(), isFalse);
      });

      tearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      test('존재하지 않는 이미지 경로는 제외하고 살아있는 경로만 남겨야 한다', () async {
        final draft = DiaryDraft(
          content: '사진이 있는 초안입니다',
          entryDate: DateTime(2026, 8, 20),
          updatedAt: DateTime(2026, 8, 20, 10),
          imagePaths: [liveFile.path, deadPath],
        );
        await mockDataSource.setDiaryDraft(draft);

        final result = await repository.getDraft();

        expect(result, isNotNull);
        expect(result!.imagePaths, [liveFile.path]);
        expect(result.imagePaths, isNot(contains(deadPath)));
      });

      test('이미지 경로가 모두 없으면 imagePaths를 null로 정규화해야 한다', () async {
        final draft = DiaryDraft(
          content: '죽은 경로만 있는 초안입니다',
          entryDate: DateTime(2026, 8, 20),
          updatedAt: DateTime(2026, 8, 20, 10),
          imagePaths: [deadPath],
        );
        await mockDataSource.setDiaryDraft(draft);

        final result = await repository.getDraft();

        expect(result, isNotNull);
        expect(result!.content, draft.content);
        expect(result.imagePaths, isNull);
      });

      test('경로 필터링이 저장소를 다시 쓰지 않아야 한다', () async {
        final originalPaths = [liveFile.path, deadPath];
        final draft = DiaryDraft(
          content: '필터링은 읽기 전용이어야 한다',
          entryDate: DateTime(2026, 8, 20),
          updatedAt: DateTime(2026, 8, 20, 10),
          imagePaths: originalPaths,
        );
        await mockDataSource.setDiaryDraft(draft);

        final result = await repository.getDraft();
        final stored = await mockDataSource.getDiaryDraft();

        expect(result!.imagePaths, [liveFile.path]);
        expect(stored, isNotNull);
        expect(stored!.imagePaths, originalPaths);
      });
    });

    group('예외 → Failure 변환', () {
      test('조회 중 Exception은 Failure로 변환되고 raw Exception이 누출되면 안 된다', () async {
        mockDataSource.shouldThrowOnGet = true;

        try {
          await repository.getDraft();
          fail('Failure가 발생해야 한다');
        } on Failure catch (failure) {
          expect(failure, isA<CacheFailure>());
        } catch (e) {
          fail('raw Exception이 누출되면 안 된다: $e');
        }
      });

      test('저장 중 Exception은 Failure로 변환되고 raw Exception이 누출되면 안 된다', () async {
        mockDataSource.shouldThrowOnSet = true;

        try {
          await repository.saveDraft(sampleDraft);
          fail('Failure가 발생해야 한다');
        } on Failure catch (failure) {
          expect(failure, isA<CacheFailure>());
        } catch (e) {
          fail('raw Exception이 누출되면 안 된다: $e');
        }
      });

      test('삭제 중 Exception은 Failure로 변환되고 raw Exception이 누출되면 안 된다', () async {
        mockDataSource.shouldThrowOnSet = true;

        try {
          await repository.clearDraft();
          fail('Failure가 발생해야 한다');
        } on Failure catch (failure) {
          expect(failure, isA<CacheFailure>());
        } catch (e) {
          fail('raw Exception이 누출되면 안 된다: $e');
        }
      });

      test('조회 Failure는 CacheException이 아니어야 한다', () async {
        mockDataSource.shouldThrowOnGet = true;

        await expectLater(
          repository.getDraft(),
          throwsA(allOf(isA<Failure>(), isNot(isA<CacheException>()))),
        );
      });
    });
  });
}
