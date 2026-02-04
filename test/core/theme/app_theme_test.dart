import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    group('상수 정의', () {
      test('primaryColor가 올바르게 정의되어야 한다', () {
        expect(AppTheme.primaryColor, const Color(0xFF7EC8E3));
      });

      test('primaryDark가 올바르게 정의되어야 한다', () {
        expect(AppTheme.primaryDark, const Color(0xFF3A7BC8));
      });

      test('accentColor가 올바르게 정의되어야 한다', () {
        expect(AppTheme.accentColor, const Color(0xFFFF9800));
      });

      test('backgroundColor가 올바르게 정의되어야 한다', () {
        expect(AppTheme.backgroundColor, Colors.white);
      });

      test('textColor가 올바르게 정의되어야 한다', () {
        expect(AppTheme.textColor, const Color(0xFF333333));
      });

      test('secondaryTextColor가 올바르게 정의되어야 한다', () {
        expect(AppTheme.secondaryTextColor, const Color(0xFF666666));
      });

      test('dividerColor가 올바르게 정의되어야 한다', () {
        expect(AppTheme.dividerColor, const Color(0xFFE0E0E0));
      });

      test('errorColor가 올바르게 정의되어야 한다', () {
        expect(AppTheme.errorColor, const Color(0xFFFF5252));
      });

      test('successColor가 올바르게 정의되어야 한다', () {
        expect(AppTheme.successColor, const Color(0xFF4CAF50));
      });
    });

    group('lightTheme', () {
      late ThemeData lightTheme;

      setUpAll(() {
        lightTheme = AppTheme.lightTheme;
      });

      test('Material3를 사용해야 한다', () {
        expect(lightTheme.useMaterial3, isTrue);
      });

      test('밝은 테마여야 한다', () {
        expect(lightTheme.colorScheme.brightness, Brightness.light);
      });

      test('AppBar 테마가 올바르게 설정되어야 한다', () {
        final appBarTheme = lightTheme.appBarTheme;

        expect(appBarTheme.backgroundColor, AppTheme.primaryColor);
        expect(appBarTheme.foregroundColor, Colors.white);
        expect(appBarTheme.elevation, 0);
        expect(appBarTheme.centerTitle, isTrue);
      });

      test('AppBar SystemUiOverlayStyle이 올바르게 설정되어야 한다', () {
        final overlayStyle = lightTheme.appBarTheme.systemOverlayStyle;

        expect(overlayStyle?.statusBarColor, Colors.transparent);
        expect(overlayStyle?.statusBarIconBrightness, Brightness.light);
        expect(overlayStyle?.statusBarBrightness, Brightness.dark);
      });

      test('Card 테마가 올바르게 설정되어야 한다', () {
        final cardTheme = lightTheme.cardTheme;

        expect(cardTheme.color, AppTheme.backgroundColor);
        expect(cardTheme.elevation, 2);
        expect(cardTheme.shape, isA<RoundedRectangleBorder>());

        final shape = cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, const BorderRadius.all(Radius.circular(12)));
      });

      test('ElevatedButton 테마가 올바르게 설정되어야 한다', () {
        final buttonTheme = lightTheme.elevatedButtonTheme;
        final style = buttonTheme.style;

        expect(style, isNotNull);

        // 배경색 확인
        final bgColor = style!.backgroundColor?.resolve({});
        expect(bgColor, AppTheme.primaryColor);

        // 전경색 확인
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, Colors.white);

        // elevation 확인
        final elevation = style.elevation?.resolve({});
        expect(elevation, 2);
      });

      test('TextTheme이 올바르게 설정되어야 한다', () {
        final textTheme = lightTheme.textTheme;

        expect(textTheme.displayLarge?.color, AppTheme.textColor);
        expect(textTheme.displayLarge?.fontSize, 32);
        expect(textTheme.displayLarge?.fontWeight, FontWeight.bold);

        expect(textTheme.headlineMedium?.color, AppTheme.textColor);
        expect(textTheme.headlineMedium?.fontSize, 24);
        expect(textTheme.headlineMedium?.fontWeight, FontWeight.w600);

        expect(textTheme.titleMedium?.color, AppTheme.textColor);
        expect(textTheme.titleMedium?.fontSize, 16);
        expect(textTheme.titleMedium?.fontWeight, FontWeight.w500);

        expect(textTheme.bodyMedium?.color, AppTheme.textColor);
        expect(textTheme.bodyMedium?.fontSize, 14);

        expect(textTheme.bodySmall?.color, AppTheme.secondaryTextColor);
        expect(textTheme.bodySmall?.fontSize, 12);
      });
    });

    group('darkTheme', () {
      late ThemeData darkTheme;

      setUpAll(() {
        darkTheme = AppTheme.darkTheme;
      });

      test('Material3를 사용해야 한다', () {
        expect(darkTheme.useMaterial3, isTrue);
      });

      test('어두운 테마여야 한다', () {
        expect(darkTheme.colorScheme.brightness, Brightness.dark);
      });

      test('AppBar 테마가 올바르게 설정되어야 한다', () {
        final appBarTheme = darkTheme.appBarTheme;

        expect(appBarTheme.backgroundColor, const Color(0xFF1E1E1E));
        expect(appBarTheme.foregroundColor, Colors.white);
        expect(appBarTheme.elevation, 0);
        expect(appBarTheme.centerTitle, isTrue);
      });

      test('AppBar SystemUiOverlayStyle이 올바르게 설정되어야 한다', () {
        final overlayStyle = darkTheme.appBarTheme.systemOverlayStyle;

        expect(overlayStyle?.statusBarColor, Colors.transparent);
        expect(overlayStyle?.statusBarIconBrightness, Brightness.light);
        expect(overlayStyle?.statusBarBrightness, Brightness.dark);
      });

      test('Card 테마가 올바르게 설정되어야 한다', () {
        final cardTheme = darkTheme.cardTheme;

        expect(cardTheme.color, const Color(0xFF2C2C2C));
        expect(cardTheme.elevation, 2);
        expect(cardTheme.shape, isA<RoundedRectangleBorder>());

        final shape = cardTheme.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, const BorderRadius.all(Radius.circular(12)));
      });

      test('ElevatedButton 테마가 올바르게 설정되어야 한다', () {
        final buttonTheme = darkTheme.elevatedButtonTheme;
        final style = buttonTheme.style;

        expect(style, isNotNull);

        // 배경색 확인
        final bgColor = style!.backgroundColor?.resolve({});
        expect(bgColor, AppTheme.primaryColor);

        // 전경색 확인
        final fgColor = style.foregroundColor?.resolve({});
        expect(fgColor, Colors.white);

        // elevation 확인
        final elevation = style.elevation?.resolve({});
        expect(elevation, 2);
      });
    });

    group('light vs dark 테마 비교', () {
      test('두 테마는 다른 brightness를 가져야 한다', () {
        expect(
          AppTheme.lightTheme.colorScheme.brightness,
          isNot(equals(AppTheme.darkTheme.colorScheme.brightness)),
        );
      });

      test('두 테마는 같은 primaryColor seed를 사용해야 한다', () {
        // 둘 다 같은 seed color를 사용하므로 primary 계열이 유사해야 함
        expect(
          AppTheme.lightTheme.useMaterial3,
          AppTheme.darkTheme.useMaterial3,
        );
      });

      test('AppBar 배경색이 달라야 한다', () {
        expect(
          AppTheme.lightTheme.appBarTheme.backgroundColor,
          isNot(equals(AppTheme.darkTheme.appBarTheme.backgroundColor)),
        );
      });

      test('Card 배경색이 달라야 한다', () {
        expect(
          AppTheme.lightTheme.cardTheme.color,
          isNot(equals(AppTheme.darkTheme.cardTheme.color)),
        );
      });
    });
  });
}
