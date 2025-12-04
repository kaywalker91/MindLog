import 'package:hive/hive.dart';
import '../../domain/entities/diary.dart';

part 'diary_dto.g.dart';

/// Hive 데이터베이스용 일기 DTO
@HiveType(typeId: 0)
class DiaryDto extends HiveObject {
  /// 고유 식별자 (문자열 ID)
  @HiveField(0)
  late String diaryId;

  /// 일기 내용
  @HiveField(1)
  late String content;

  /// 작성 시간
  @HiveField(2)
  late DateTime createdAt;

  /// 분석 상태
  @HiveField(3)
  late int statusIndex;

  // === 분석 결과 (분석 완료 시에만 값이 있음) ===

  /// 감정 키워드 (콤마로 구분)
  @HiveField(4)
  String? keywords;

  /// 감정 점수
  @HiveField(5)
  int? sentimentScore;

  /// 공감 메시지
  @HiveField(6)
  String? empathyMessage;

  /// 추천 행동
  @HiveField(7)
  String? actionItem;

  /// 분석 시간
  @HiveField(8)
  DateTime? analyzedAt;

  /// 추천 행동 완료 여부
  @HiveField(9)
  bool isActionCompleted = false;

  DiaryDto();

  /// 상태 인덱스에 따른 DiaryStatus 반환
  DiaryStatus get status => DiaryStatus.values[statusIndex];
  set status(DiaryStatus value) => statusIndex = value.index;
}

// === 변환 확장 메서드 ===

extension DiaryDtoX on DiaryDto {
  /// DTO → Entity 변환
  Diary toEntity() {
    AnalysisResult? analysisResult;

    if (status == DiaryStatus.analyzed &&
        keywords != null &&
        sentimentScore != null &&
        empathyMessage != null &&
        actionItem != null &&
        analyzedAt != null) {
      analysisResult = AnalysisResult(
        keywords: keywords!.split(',').map((e) => e.trim()).toList(),
        sentimentScore: sentimentScore!,
        empathyMessage: empathyMessage!,
        actionItem: actionItem!,
        analyzedAt: analyzedAt!,
        isActionCompleted: isActionCompleted,
      );
    }

    return Diary(
      id: diaryId,
      content: content,
      createdAt: createdAt,
      status: status,
      analysisResult: analysisResult,
    );
  }
}

extension DiaryX on Diary {
  /// Entity → DTO 변환
  DiaryDto toDto() {
    final dto = DiaryDto()
      ..diaryId = id
      ..content = content
      ..createdAt = createdAt
      ..status = status;

    if (analysisResult != null) {
      dto
        ..keywords = analysisResult!.keywords.join(',')
        ..sentimentScore = analysisResult!.sentimentScore
        ..empathyMessage = analysisResult!.empathyMessage
        ..actionItem = analysisResult!.actionItem
        ..analyzedAt = analysisResult!.analyzedAt
        ..isActionCompleted = analysisResult!.isActionCompleted;
    }

    return dto;
  }
}
