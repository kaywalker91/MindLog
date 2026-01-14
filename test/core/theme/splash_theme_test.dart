import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/theme/app_colors.dart';
import 'package:mindlog/core/theme/splash_theme.dart';

void main() {
  group('SplashTheme', () {
    group('상수 정의', () {
      test('primaryColor가 AppColors.statsPrimary와 같아야 한다', () {
        expect(SplashTheme.primaryColor, AppColors.statsPrimary);
      });

      test('secondaryColor가 AppColors.statsSecondary와 같아야 한다', () {
        expect(SplashTheme.secondaryColor, AppColors.statsSecondary);
      });

      test('backgroundColor가 AppColors.statsBackground와 같아야 한다', () {
        expect(SplashTheme.backgroundColor, AppColors.statsBackground);
      });

      test('textColor가 AppColors.statsTextPrimary와 같아야 한다', () {
        expect(SplashTheme.textColor, AppColors.statsTextPrimary);
      });

      test('secondaryTextColor가 AppColors.statsTextSecondary와 같아야 한다', () {
        expect(SplashTheme.secondaryTextColor, AppColors.statsTextSecondary);
      });
    });

    group('createSplashTheme', () {
      late ThemeData splashTheme;

      setUpAll(() {
        splashTheme = SplashTheme.createSplashTheme();
      });

      test('Material3를 사용해야 한다', () {
        expect(splashTheme.useMaterial3, isTrue);
      });

      test('밝은 테마여야 한다', () {
        expect(splashTheme.colorScheme.brightness, Brightness.light);
      });

      test('ColorScheme primary가 올바르게 설정되어야 한다', () {
        expect(splashTheme.colorScheme.primary, SplashTheme.primaryColor);
      });

      test('ColorScheme secondary가 올바르게 설정되어야 한다', () {
        expect(splashTheme.colorScheme.secondary, SplashTheme.secondaryColor);
      });

      test('ColorScheme surface가 올바르게 설정되어야 한다', () {
        expect(splashTheme.colorScheme.surface, SplashTheme.backgroundColor);
      });

      test('ColorScheme onSurface가 올바르게 설정되어야 한다', () {
        expect(splashTheme.colorScheme.onSurface, SplashTheme.textColor);
      });

      test('호출할 때마다 새로운 ThemeData 인스턴스를 반환해야 한다', () {
        final theme1 = SplashTheme.createSplashTheme();
        final theme2 = SplashTheme.createSplashTheme();

        // 동일한 값이지만 다른 인스턴스
        expect(identical(theme1, theme2), isFalse);
        expect(theme1.colorScheme.primary, theme2.colorScheme.primary);
      });
    });
  });
}
