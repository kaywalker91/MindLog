import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/notification_messages.dart';
import 'package:mindlog/core/services/fcm_service.dart';

/// 결정론적 테스트를 위한 Mock Random
class MockRandom implements Random {
  int _counter = 0;

  @override
  int nextInt(int max) => _counter++ % max;

  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => true;
}

void main() {
  setUp(() {
    FCMService.resetForTesting();
    NotificationMessages.resetForTesting();
  });

  tearDown(() {
    FCMService.resetForTesting();
    NotificationMessages.resetForTesting();
  });

  group('FCMService', () {
    group('buildPersonalizedMessage', () {
      group('감정 데이터가 있을 때', () {
        test('감정 기반 메시지를 선택해야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => 5.0;
          NotificationMessages.setRandom(MockRandom());

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '서버 제목',
            serverBody: '서버 본문',
          );

          // Assert: 서버 메시지가 아닌 감정 기반 메시지 사용
          expect(result.title, isNot('서버 제목'));
          expect(result.body, isNot('서버 본문'));
          expect(result.title, isNotEmpty);
          expect(result.body, isNotEmpty);
        });

        test('낮은 감정 점수(1-3)에서 공감/위로 메시지를 선택해야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => 2.0; // low
          NotificationMessages.setRandom(MockRandom());

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '서버 제목',
            serverBody: '서버 본문',
          );

          // Assert: 낮은 감정 시 공감/위로 메시지 풀에서 선택 (80% 가중치)
          // MockRandom으로 결정론적이므로 첫 번째 항목 선택됨
          expect(result.body, isNotEmpty);
          // 공감 메시지 풀 또는 시간대별 메시지 풀에 포함되어야 함
          // 이름이 null이므로 {name} 패턴 제거된 메시지와 비교
          final allPossibleBodies = [
            ...NotificationMessages.empathyBodies,
            ...NotificationMessages.getBodiesForSlot(
              NotificationMessages.getCurrentTimeSlot(),
            ),
          ].toList();
          expect(allPossibleBodies, contains(result.body));
        });

        test('높은 감정 점수(7-10)에서 격려/긍정 메시지를 선택해야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => 8.0; // high
          NotificationMessages.setRandom(MockRandom());

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '서버 제목',
            serverBody: '서버 본문',
          );

          // Assert: 높은 감정 시 격려/긍정 메시지 풀에서 선택 (60% 가중치)
          expect(result.body, isNotEmpty);
          // 이름이 null이므로 {name} 패턴 제거된 메시지와 비교
          final allPossibleBodies = [
            ...NotificationMessages.encouragementBodies,
            ...NotificationMessages.getBodiesForSlot(
              NotificationMessages.getCurrentTimeSlot(),
            ),
          ].toList();
          expect(allPossibleBodies, contains(result.body));
        });

        test('보통 감정 점수(4-6)에서 균형 메시지를 선택해야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => 5.0; // medium
          NotificationMessages.setRandom(MockRandom());

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '서버 제목',
            serverBody: '서버 본문',
          );

          // Assert: 보통 감정 시 모든 메시지 풀에서 균등 선택
          expect(result.body, isNotEmpty);
          // 이름이 null이므로 {name} 패턴 제거된 메시지와 비교
          final allPossibleBodies = [
            ...NotificationMessages.mindcareBodies,
            ...NotificationMessages.getBodiesForSlot(
              NotificationMessages.getCurrentTimeSlot(),
            ),
          ].toList();
          expect(allPossibleBodies, contains(result.body));
        });

        test('메시지에 {name} 패턴이 포함되지 않아야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => 5.0;
          NotificationMessages.setRandom(MockRandom());

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '서버 제목',
            serverBody: '서버 본문',
          );

          // Assert: 마음케어 메시지에 {name} 템플릿이 없어야 함
          expect(result.title, isNotEmpty);
          expect(result.body, isNotEmpty);
          expect(result.title, isNot(contains('{name}')));
          expect(result.body, isNot(contains('{name}')));
        });
      });

      group('감정 데이터가 없을 때', () {
        test('서버 메시지를 그대로 사용해야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => null;

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '오늘의 마음 케어',
            serverBody: '오늘도 당신을 응원해요',
          );

          // Assert: 서버 메시지 사용
          expect(result.title, '오늘의 마음 케어');
          expect(result.body, '오늘도 당신을 응원해요');
        });

        test('서버 메시지가 null이면 기본값을 사용해야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => null;
          NotificationMessages.setRandom(MockRandom());

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: null,
            serverBody: null,
          );

          // Assert: title은 'MindLog', body는 랜덤 마음케어 메시지 (빈 문자열 아님)
          expect(result.title, 'MindLog');
          expect(result.body, isNotEmpty);
          expect(NotificationMessages.mindcareBodies, contains(result.body));
        });

        test('서버 메시지가 빈 문자열이면 기본값을 사용해야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => null;
          NotificationMessages.setRandom(MockRandom());

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '',
            serverBody: '',
          );

          // Assert: 빈 문자열도 기본값으로 대체
          expect(result.title, 'MindLog');
          expect(result.body, isNotEmpty);
          expect(NotificationMessages.mindcareBodies, contains(result.body));
        });

        test('서버 title만 빈 문자열이면 title만 기본값을 사용해야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => null;

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '',
            serverBody: '서버 본문 유지',
          );

          // Assert
          expect(result.title, 'MindLog');
          expect(result.body, '서버 본문 유지');
        });

        test('서버 body만 빈 문자열이면 body만 기본값을 사용해야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => null;
          NotificationMessages.setRandom(MockRandom());

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '서버 제목 유지',
            serverBody: '',
          );

          // Assert
          expect(result.title, '서버 제목 유지');
          expect(result.body, isNotEmpty);
          expect(NotificationMessages.mindcareBodies, contains(result.body));
        });
      });

      group('경계값 테스트', () {
        test('감정 점수 3.0은 low로 분류되어야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => 3.0;
          NotificationMessages.setRandom(MockRandom());

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '서버 제목',
            serverBody: '서버 본문',
          );

          // Assert: 감정 레벨 확인
          expect(NotificationMessages.getEmotionLevel(3.0), EmotionLevel.low);
          expect(result.body, isNotEmpty);
        });

        test('감정 점수 3.1은 medium으로 분류되어야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => 3.1;
          NotificationMessages.setRandom(MockRandom());

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '서버 제목',
            serverBody: '서버 본문',
          );

          // Assert: 감정 레벨 확인
          expect(
            NotificationMessages.getEmotionLevel(3.1),
            EmotionLevel.medium,
          );
          expect(result.body, isNotEmpty);
        });

        test('감정 점수 6.0은 medium으로 분류되어야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => 6.0;

          // Assert: 감정 레벨 확인
          expect(
            NotificationMessages.getEmotionLevel(6.0),
            EmotionLevel.medium,
          );
        });

        test('감정 점수 6.1은 high로 분류되어야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => 6.1;

          // Assert: 감정 레벨 확인
          expect(NotificationMessages.getEmotionLevel(6.1), EmotionLevel.high);
        });
      });

      group('결정론적 동작', () {
        test('같은 조건에서 같은 메시지를 반환해야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => 5.0;

          NotificationMessages.setRandom(MockRandom());
          final first = await FCMService.buildPersonalizedMessage(
            serverTitle: '서버 제목',
            serverBody: '서버 본문',
          );

          NotificationMessages.setRandom(MockRandom());
          final second = await FCMService.buildPersonalizedMessage(
            serverTitle: '서버 제목',
            serverBody: '서버 본문',
          );

          // Assert: 같은 결과
          expect(first.title, equals(second.title));
          expect(first.body, equals(second.body));
        });
      });

      group('시간대별 메시지', () {
        test('현재 시간대에 맞는 제목을 선택해야 한다', () async {
          // Arrange
          FCMService.emotionScoreProvider = () async => 5.0;
          NotificationMessages.setRandom(MockRandom());

          // Act
          final result = await FCMService.buildPersonalizedMessage(
            serverTitle: '서버 제목',
            serverBody: '서버 본문',
          );

          // Assert: 현재 시간대 제목 목록에 포함
          final currentSlot = NotificationMessages.getCurrentTimeSlot();
          final titles = NotificationMessages.getTitlesForSlot(currentSlot);
          expect(titles, contains(result.title));
        });
      });
    });

    group('resetForTesting', () {
      test('모든 테스트 주입을 초기화해야 한다', () {
        // Arrange
        FCMService.emotionScoreProvider = () async => 5.0;

        // Act
        FCMService.resetForTesting();

        // Assert
        expect(FCMService.emotionScoreProvider, isNull);
        expect(FCMService.fcmToken, isNull);
      });
    });
  });
}
