import 'package:intl/intl.dart';

/// 날짜 포맷팅 유틸리티
class DateFormatter {
  DateFormatter._();

  /// 전체 날짜 및 시간 포맷 (예: 2024년 1월 15일 오후 3:30)
  static String formatFullDateTime(DateTime dateTime) {
    return DateFormat('yyyy년 M월 d일 a h:mm', 'ko_KR').format(dateTime);
  }

  /// 날짜만 포맷 (예: 2024년 1월 15일)
  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy년 M월 d일', 'ko_KR').format(dateTime);
  }

  /// 짧은 날짜 포맷 (예: 1월 15일)
  static String formatShortDate(DateTime dateTime) {
    return DateFormat('M월 d일', 'ko_KR').format(dateTime);
  }

  /// 시간만 포맷 (예: 오후 3:30)
  static String formatTime(DateTime dateTime) {
    return DateFormat('a h:mm', 'ko_KR').format(dateTime);
  }

  // === 호출부 실측 패턴 1:1 API (출력 문자열 보존) ===

  static final DateFormat _detailFormatter = DateFormat(
    'yyyy년 MM월 dd일 (E) a hh:mm',
    'ko_KR',
  );
  static final DateFormat _listFormatter = DateFormat('MM월 dd일 (E)', 'ko_KR');
  static final DateFormat _chartShortFormatter = DateFormat('M/d');
  static final DateFormat _chartTooltipFormatter = DateFormat('M월 d일');

  /// 상세 화면 날짜·시간 (예: 2024년 01월 15일 (월) 오후 03:30)
  /// diary_detail_screen 전용 — 요일·제로패딩 포함
  static String formatDetailDateTime(DateTime dateTime) {
    return _detailFormatter.format(dateTime);
  }

  /// 목록 카드 날짜 (예: 01월 15일 (월))
  /// diary_item_card 전용
  static String formatListDate(DateTime dateTime) {
    return _listFormatter.format(dateTime);
  }

  /// 차트 축 짧은 날짜 (예: 1/15)
  static String formatChartShort(DateTime dateTime) {
    return _chartShortFormatter.format(dateTime);
  }

  /// 차트 툴팁 날짜 (예: 1월 15일)
  static String formatChartTooltip(DateTime dateTime) {
    return _chartTooltipFormatter.format(dateTime);
  }

  /// 개인 응원 메시지 상대 작성일
  /// (예: 오늘 작성 / 어제 작성 / 3일 전 작성 / 1월 1일 작성)
  ///
  /// [now] 주입 시 상대 계산이 결정론적 — 테스트/자정 경계 재현용.
  /// 계산은 difference 기반(캘린더 일자 아님)으로 message_card 기존 동작을 보존한다.
  static String formatRelativeWritten(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(date);

    if (diff.inDays == 0) {
      return '오늘 작성';
    } else if (diff.inDays == 1) {
      return '어제 작성';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전 작성';
    } else {
      return '${date.month}월 ${date.day}일 작성';
    }
  }

  /// 상대적 시간 표시 (예: 방금 전, 5분 전, 어제)
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 2) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return formatShortDate(dateTime);
    }
  }

  /// 오늘 날짜인지 확인
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }
}
