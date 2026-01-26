import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/statistics.dart';

/// UI State Provider 중앙화
/// 화면 간 공유되는 UI 상태를 한 곳에서 관리

/// 메인 화면 탭 인덱스 Provider
/// - 0: 일기 목록
/// - 1: 통계
/// - 2: 설정
final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

/// 통계 화면 기간 선택 Provider
final selectedStatisticsPeriodProvider =
    StateProvider<StatisticsPeriod>((ref) => StatisticsPeriod.week);
