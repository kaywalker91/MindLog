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
