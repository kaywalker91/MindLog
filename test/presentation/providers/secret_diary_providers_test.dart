import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/providers/infra_providers.dart';
import 'package:mindlog/presentation/providers/secret_diary_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/diary_fixtures.dart';
import '../../helpers/mock_fallbacks.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  late ProviderContainer container;
  late MockDiaryRepository mockDiaryRepository;
  late MockSecretPinRepository mockPinRepository;

  setUpAll(() {
    registerMockFallbackValues();
  });

  setUp(() {
    mockDiaryRepository = MockDiaryRepository();
    mockPinRepository = MockSecretPinRepository();

    // Default DiaryRepository stubs
    when(
      () => mockDiaryRepository.getAllDiaries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockDiaryRepository.getTodayDiaries(),
    ).thenAnswer((_) async => []);
    when(
      () => mockDiaryRepository.createDiary(
        any(),
        imagePaths: any(named: 'imagePaths'),
      ),
    ).thenAnswer((_) async => DiaryFixtures.pending());
    when(
      () => mockDiaryRepository.updateDiary(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockDiaryRepository.deleteDiary(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockDiaryRepository.toggleDiaryPin(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockDiaryRepository.deleteAllDiaries(),
    ).thenAnswer((_) async {});
    when(
      () => mockDiaryRepository.setDiarySecret(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockDiaryRepository.getSecretDiaries(),
    ).thenAnswer((_) async => []);

    // Default SecretPinRepository stubs
    when(() => mockPinRepository.hasPin()).thenAnswer((_) async => false);
    when(
      () => mockPinRepository.verifyPin(any()),
    ).thenAnswer((_) async => false);
    when(() => mockPinRepository.setPin(any())).thenAnswer((_) async {});
    when(() => mockPinRepository.deletePin()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(mockDiaryRepository),
        secretPinRepositoryProvider.overrideWithValue(mockPinRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // ──────────────────────────────────────────────
  group('hasPinProvider', () {
    test('PIN 미설정 시 false를 반환해야 한다', () async {
      // Arrange — hasPin returns false (default stub)

      // Act
      final hasPin = await container.read(hasPinProvider.future);

      // Assert
      expect(hasPin, isFalse);
    });

    test('PIN 설정 시 true를 반환해야 한다', () async {
      // Arrange
      when(() => mockPinRepository.hasPin()).thenAnswer((_) async => true);

      // Act
      final hasPin = await container.read(hasPinProvider.future);

      // Assert
      expect(hasPin, isTrue);
    });

    test('PIN 설정 후 삭제 시 invalidate로 갱신되어야 한다', () async {
      // Arrange — PIN 있음
      when(() => mockPinRepository.hasPin()).thenAnswer((_) async => true);
      expect(await container.read(hasPinProvider.future), isTrue);

      // Act — PIN 삭제 후 stub 변경, then invalidate
      when(() => mockPinRepository.hasPin()).thenAnswer((_) async => false);
      container.invalidate(hasPinProvider);

      // Assert — 갱신된 상태 반영
      expect(await container.read(hasPinProvider.future), isFalse);
    });
  });

  // ──────────────────────────────────────────────
  group('secretDiaryListProvider', () {
    test('비밀일기가 없을 때 빈 목록을 반환해야 한다', () async {
      // Arrange - all diaries are isSecret=false by default
      when(
        () => mockDiaryRepository.getAllDiaries(),
      ).thenAnswer((_) async => DiaryFixtures.weekOfDiaries());

      // Act
      final secretDiaries = await container.read(
        secretDiaryListProvider.future,
      );

      // Assert
      expect(secretDiaries, isEmpty);
    });

    test('비밀일기 목록을 올바르게 반환해야 한다', () async {
      // Arrange
      final secretDiary = DiaryFixtures.pending(
        id: 'secret-1',
      ).copyWith(isSecret: true);
      when(
        () => mockDiaryRepository.getSecretDiaries(),
      ).thenAnswer(
        (_) async => [secretDiary],
      );

      // Act
      final secretDiaries = await container.read(
        secretDiaryListProvider.future,
      );

      // Assert
      expect(secretDiaries.length, 1);
      expect(secretDiaries.first.id, 'secret-1');
      expect(secretDiaries.first.isSecret, isTrue);
    });

    test('오류 발생 시 AsyncError 상태여야 한다', () async {
      // Arrange
      when(
        () => mockDiaryRepository.getSecretDiaries(),
      ).thenThrow(Exception('load error'));

      // Act
      Object? caughtError;
      try {
        await container.read(secretDiaryListProvider.future);
      } catch (e) {
        caughtError = e;
      }

      // Assert
      expect(caughtError, isNotNull);
    });

    test('invalidate 후 목록이 갱신되어야 한다', () async {
      // Arrange — 초기에는 비밀일기 없음 (default stub: getSecretDiaries → [])
      expect(await container.read(secretDiaryListProvider.future), isEmpty);

      // Act — 비밀일기 추가 후 stub 변경, then invalidate
      final secretDiary = DiaryFixtures.pending(
        id: 'secret-1',
      ).copyWith(isSecret: true);
      when(
        () => mockDiaryRepository.getSecretDiaries(),
      ).thenAnswer((_) async => [secretDiary]);
      container.invalidate(secretDiaryListProvider);

      // Assert
      final updated = await container.read(secretDiaryListProvider.future);
      expect(updated.length, 1);
      expect(updated.first.isSecret, isTrue);
    });
  });

  // ──────────────────────────────────────────────
  group('UseCase Providers DI 체인', () {
    test('setSecretPinUseCaseProvider가 올바르게 생성되어야 한다', () {
      final useCase = container.read(setSecretPinUseCaseProvider);
      expect(useCase, isNotNull);
    });

    test('verifySecretPinUseCaseProvider가 올바르게 생성되어야 한다', () {
      final useCase = container.read(verifySecretPinUseCaseProvider);
      expect(useCase, isNotNull);
    });

    test('hasSecretPinUseCaseProvider가 올바르게 생성되어야 한다', () {
      final useCase = container.read(hasSecretPinUseCaseProvider);
      expect(useCase, isNotNull);
    });

    test('deleteSecretPinUseCaseProvider가 올바르게 생성되어야 한다', () {
      final useCase = container.read(deleteSecretPinUseCaseProvider);
      expect(useCase, isNotNull);
    });

    test('setDiarySecretUseCaseProvider가 올바르게 생성되어야 한다', () {
      final useCase = container.read(setDiarySecretUseCaseProvider);
      expect(useCase, isNotNull);
    });

    test('getSecretDiariesUseCaseProvider가 올바르게 생성되어야 한다', () {
      final useCase = container.read(getSecretDiariesUseCaseProvider);
      expect(useCase, isNotNull);
    });
  });
}
