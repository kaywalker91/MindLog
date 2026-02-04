import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/diary.dart';

void main() {
  group('Diary', () {
    test('기본 생성자로 객체를 생성할 수 있어야 한다', () {
      final diary = Diary(
        id: 'test-id',
        content: '오늘 좋은 하루였다.',
        createdAt: DateTime(2024, 1, 15, 12, 0),
      );

      expect(diary.id, 'test-id');
      expect(diary.content, '오늘 좋은 하루였다.');
      expect(diary.status, DiaryStatus.pending);
      expect(diary.isPinned, false);
      expect(diary.analysisResult, isNull);
    });

    test('copyWith로 필드를 복사할 수 있어야 한다', () {
      final original = Diary(
        id: 'test-id',
        content: '원본 내용',
        createdAt: DateTime(2024, 1, 15),
        status: DiaryStatus.pending,
      );

      final copied = original.copyWith(
        content: '수정된 내용',
        status: DiaryStatus.analyzed,
      );

      expect(copied.id, original.id);
      expect(copied.content, '수정된 내용');
      expect(copied.status, DiaryStatus.analyzed);
    });

    test(
      'copyWith의 clearAnalysisResult로 analysisResult를 null로 설정할 수 있어야 한다',
      () {
        final original = Diary(
          id: 'test-id',
          content: '원본 내용',
          createdAt: DateTime(2024, 1, 15),
          analysisResult: AnalysisResult(
            keywords: ['테스트'],
            analyzedAt: DateTime(2024, 1, 15),
          ),
        );

        final cleared = original.copyWith(clearAnalysisResult: true);

        expect(cleared.analysisResult, isNull);
      },
    );

    test('fromJson/toJson으로 직렬화할 수 있어야 한다', () {
      final json = {
        'id': 'json-test',
        'content': 'JSON 테스트 내용',
        'createdAt': '2024-01-15T12:00:00.000',
        'status': 'analyzed',
        'isPinned': true,
        'analysisResult': null,
      };

      final diary = Diary.fromJson(json);
      expect(diary.id, 'json-test');
      expect(diary.content, 'JSON 테스트 내용');
      expect(diary.isPinned, true);

      final serialized = diary.toJson();
      expect(serialized['id'], 'json-test');
      expect(serialized['content'], 'JSON 테스트 내용');
    });
  });

  group('EmotionCategory', () {
    test('기본 생성자로 객체를 생성할 수 있어야 한다', () {
      const category = EmotionCategory(primary: '기쁨', secondary: '만족');

      expect(category.primary, '기쁨');
      expect(category.secondary, '만족');
    });

    test('fromJson/toJson으로 직렬화할 수 있어야 한다', () {
      final json = {'primary': '슬픔', 'secondary': '실망'};

      final category = EmotionCategory.fromJson(json);
      expect(category.primary, '슬픔');
      expect(category.secondary, '실망');

      final serialized = category.toJson();
      expect(serialized['primary'], '슬픔');
      expect(serialized['secondary'], '실망');
    });
  });

  group('EmotionTrigger', () {
    test('기본 생성자로 객체를 생성할 수 있어야 한다', () {
      const trigger = EmotionTrigger(category: '업무', description: '프로젝트 완료');

      expect(trigger.category, '업무');
      expect(trigger.description, '프로젝트 완료');
    });

    test('fromJson/toJson으로 직렬화할 수 있어야 한다', () {
      final json = {'category': '관계', 'description': '친구와의 대화'};

      final trigger = EmotionTrigger.fromJson(json);
      expect(trigger.category, '관계');
      expect(trigger.description, '친구와의 대화');

      final serialized = trigger.toJson();
      expect(serialized['category'], '관계');
      expect(serialized['description'], '친구와의 대화');
    });
  });

  group('AnalysisResult', () {
    test('기본 생성자로 객체를 생성할 수 있어야 한다', () {
      final result = AnalysisResult(
        keywords: ['행복', '만족'],
        sentimentScore: 8,
        empathyMessage: '좋은 하루였네요!',
        actionItems: ['휴식하기', '기록하기'],
        analyzedAt: DateTime(2024, 1, 15, 12, 0),
      );

      expect(result.keywords, ['행복', '만족']);
      expect(result.sentimentScore, 8);
      expect(result.isEmergency, false);
    });

    test('fromJson/toJson으로 직렬화할 수 있어야 한다', () {
      final json = {
        'keywords': ['테스트', '키워드'],
        'sentimentScore': 7,
        'empathyMessage': '테스트 메시지',
        'actionItem': '액션',
        'actionItems': ['액션1', '액션2'],
        'analyzedAt': '2024-01-15T12:00:00.000',
        'isActionCompleted': false,
        'isEmergency': false,
      };

      final result = AnalysisResult.fromJson(json);
      expect(result.keywords, ['테스트', '키워드']);
      expect(result.sentimentScore, 7);

      final serialized = result.toJson();
      expect(serialized['keywords'], ['테스트', '키워드']);
    });

    test('copyWith로 필드를 복사할 수 있어야 한다', () {
      final original = AnalysisResult(
        keywords: ['원본'],
        sentimentScore: 5,
        empathyMessage: '원본 메시지',
        analyzedAt: DateTime(2024, 1, 15),
        aiCharacterId: 'warmCounselor',
      );

      final copied = original.copyWith(
        sentimentScore: 8,
        clearAiCharacterId: true,
      );

      expect(copied.keywords, original.keywords);
      expect(copied.sentimentScore, 8);
      expect(copied.aiCharacterId, isNull);
    });

    group('displayActionItems', () {
      test('actionItems가 있으면 그대로 반환해야 한다', () {
        final result = AnalysisResult(
          actionItems: ['액션1', '액션2', '액션3'],
          analyzedAt: DateTime(2024, 1, 15),
        );

        expect(result.displayActionItems, ['액션1', '액션2', '액션3']);
      });

      test('actionItems가 JSON 배열 문자열이면 파싱해야 한다', () {
        final result = AnalysisResult(
          actionItems: ['["파싱된1", "파싱된2"]'],
          analyzedAt: DateTime(2024, 1, 15),
        );

        expect(result.displayActionItems, ['파싱된1', '파싱된2']);
      });

      test('actionItems가 비어있고 actionItem이 있으면 actionItem을 반환해야 한다', () {
        final result = AnalysisResult(
          actionItem: '단일 액션',
          actionItems: [],
          analyzedAt: DateTime(2024, 1, 15),
        );

        expect(result.displayActionItems, ['단일 액션']);
      });

      test('actionItem이 JSON 배열 문자열이면 파싱해야 한다', () {
        final result = AnalysisResult(
          actionItem: '["JSON에서1", "JSON에서2"]',
          actionItems: [],
          analyzedAt: DateTime(2024, 1, 15),
        );

        expect(result.displayActionItems, ['JSON에서1', 'JSON에서2']);
      });

      test('actionItems와 actionItem 모두 비어있으면 빈 배열을 반환해야 한다', () {
        final result = AnalysisResult(
          actionItem: '',
          actionItems: [],
          analyzedAt: DateTime(2024, 1, 15),
        );

        expect(result.displayActionItems, isEmpty);
      });

      test('잘못된 JSON 형식의 actionItems는 그대로 반환해야 한다', () {
        final result = AnalysisResult(
          actionItems: ['[잘못된 JSON'],
          analyzedAt: DateTime(2024, 1, 15),
        );

        expect(result.displayActionItems, ['[잘못된 JSON']);
      });

      test('잘못된 JSON 형식의 actionItem은 그대로 반환해야 한다', () {
        final result = AnalysisResult(
          actionItem: '[잘못된 JSON',
          actionItems: [],
          analyzedAt: DateTime(2024, 1, 15),
        );

        expect(result.displayActionItems, ['[잘못된 JSON']);
      });
    });
  });

  group('DiaryStatus', () {
    test('모든 상태 값이 올바르게 정의되어야 한다', () {
      expect(DiaryStatus.values.length, 4);
      expect(DiaryStatus.values, contains(DiaryStatus.pending));
      expect(DiaryStatus.values, contains(DiaryStatus.analyzed));
      expect(DiaryStatus.values, contains(DiaryStatus.failed));
      expect(DiaryStatus.values, contains(DiaryStatus.safetyBlocked));
    });
  });
}
