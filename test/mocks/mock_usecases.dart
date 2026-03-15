import 'package:mocktail/mocktail.dart';
import 'package:mindlog/domain/usecases/analyze_diary_usecase.dart';
import 'package:mindlog/domain/usecases/get_notification_settings_usecase.dart';
import 'package:mindlog/domain/usecases/get_selected_ai_character_usecase.dart';
import 'package:mindlog/domain/usecases/get_statistics_usecase.dart';
import 'package:mindlog/domain/usecases/set_notification_settings_usecase.dart';
import 'package:mindlog/domain/usecases/set_selected_ai_character_usecase.dart';
import 'package:mindlog/domain/usecases/validate_diary_content_usecase.dart';

class MockAnalyzeDiaryUseCase extends Mock implements AnalyzeDiaryUseCase {}

class MockGetNotificationSettingsUseCase extends Mock
    implements GetNotificationSettingsUseCase {}

class MockSetNotificationSettingsUseCase extends Mock
    implements SetNotificationSettingsUseCase {}

class MockGetSelectedAiCharacterUseCase extends Mock
    implements GetSelectedAiCharacterUseCase {}

class MockSetSelectedAiCharacterUseCase extends Mock
    implements SetSelectedAiCharacterUseCase {}

class MockGetStatisticsUseCase extends Mock implements GetStatisticsUseCase {}

class MockValidateDiaryContentUseCase extends Mock
    implements ValidateDiaryContentUseCase {}
