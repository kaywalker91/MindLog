import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'diary_list_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

/// 현재 선택된 탭 인덱스 Provider
final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

/// 메인 화면 (BottomNavigationBar 포함)
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          DiaryListScreen(),
          StatisticsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 12 : 16,
            0,
            isCompact ? 12 : 16,
            isCompact ? 8 : 12,
          ),
          child: _buildNavigationBar(
            context,
            selectedIndex: selectedIndex,
            onSelected: (index) {
              ref.read(selectedTabIndexProvider.notifier).state = index;
            },
            isCompact: isCompact,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar(
    BuildContext context, {
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    required bool isCompact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final unselectedColor =
        colorScheme.onSurface.withValues(alpha: 0.65);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surface,
            AppColors.statsBackground,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.statsPrimary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.statsPrimary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              final isSelected = states.contains(MaterialState.selected);
              return AppTextStyles.label.copyWith(
                color: isSelected
                    ? AppColors.statsPrimaryDark
                    : unselectedColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              );
            }),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              final isSelected = states.contains(MaterialState.selected);
              return IconThemeData(
                color: isSelected
                    ? AppColors.statsPrimaryDark
                    : unselectedColor,
                size: isSelected ? 26 : 24,
              );
            }),
          ),
          child: NavigationBar(
            height: isCompact ? 58 : 64,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            backgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.statsPrimary.withValues(alpha: 0.18),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.book_outlined),
                selectedIcon: Icon(Icons.book_rounded),
                label: '일기',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics_rounded),
                label: '통계',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: '설정',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
