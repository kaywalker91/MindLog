import 'package:mocktail/mocktail.dart';
import 'package:mindlog/domain/repositories/diary_repository.dart';
import 'package:mindlog/domain/repositories/secret_pin_repository.dart';
import 'package:mindlog/domain/repositories/settings_repository.dart';
import 'package:mindlog/domain/repositories/statistics_repository.dart';

class MockDiaryRepository extends Mock implements DiaryRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockSettingsRepositoryWithMessages extends Mock
    implements SettingsRepository {}

class MockSecretPinRepository extends Mock implements SecretPinRepository {}

class MockStatisticsRepository extends Mock implements StatisticsRepository {}
