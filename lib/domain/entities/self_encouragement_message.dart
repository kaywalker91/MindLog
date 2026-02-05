/// 사용자가 직접 작성한 응원 메시지 엔티티
class SelfEncouragementMessage {
  const SelfEncouragementMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.displayOrder,
  });

  /// 고유 식별자 (UUID)
  final String id;

  /// 메시지 내용 (최대 100자)
  final String content;

  /// 생성 일시
  final DateTime createdAt;

  /// 표시 순서 (순차 모드용, 0부터 시작)
  final int displayOrder;

  /// 최대 메시지 길이
  static const int maxContentLength = 100;

  /// 최대 등록 가능 메시지 수
  static const int maxMessageCount = 10;

  SelfEncouragementMessage copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    int? displayOrder,
  }) {
    return SelfEncouragementMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  factory SelfEncouragementMessage.fromJson(Map<String, dynamic> json) {
    return SelfEncouragementMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      displayOrder: json['displayOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'displayOrder': displayOrder,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelfEncouragementMessage &&
        other.id == id &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.displayOrder == displayOrder;
  }

  @override
  int get hashCode {
    return Object.hash(id, content, createdAt, displayOrder);
  }

  @override
  String toString() {
    return 'SelfEncouragementMessage(id: $id, content: $content, displayOrder: $displayOrder)';
  }
}

/// 메시지 로테이션 모드
enum MessageRotationMode {
  /// 랜덤 선택
  random,

  /// 순차 선택 (displayOrder 순)
  sequential,
}
