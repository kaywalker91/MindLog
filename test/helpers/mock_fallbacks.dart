import 'package:mocktail/mocktail.dart';
import 'package:mindlog/core/constants/ai_character.dart';
import 'package:mindlog/domain/entities/diary.dart';
import 'package:mindlog/domain/entities/notification_settings.dart';
import 'package:mindlog/domain/entities/self_encouragement_message.dart';
import 'package:mindlog/domain/entities/statistics.dart';

/// 모든 mocktail 테스트에서 setUpAll()에 호출하는 fallback 등록 함수
///
/// any()를 비-primitive 타입에 사용하기 전에 반드시 호출해야 한다.
void registerMockFallbackValues() {
  registerFallbackValue(_FakeDiary());
  registerFallbackValue(AiCharacter.warmCounselor);
  registerFallbackValue(NotificationSettings.defaults());
  registerFallbackValue(_FakeSelfEncouragementMessage());
  registerFallbackValue(StatisticsPeriod.week);
}

class _FakeDiary extends Fake implements Diary {}

class _FakeSelfEncouragementMessage extends Fake
    implements SelfEncouragementMessage {}
