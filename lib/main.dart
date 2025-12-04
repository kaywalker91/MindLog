import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/hive_local_datasource.dart';
import 'presentation/screens/diary_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  await dotenv.load(fileName: '.env');

  // Hive 초기화
  await HiveLocalDataSource.initialize();

  // 한국어 날짜 포맷 초기화
  await initializeDateFormatting('ko_KR', null);

  runApp(
    const ProviderScope(
      child: MindLogApp(),
    ),
  );
}

class MindLogApp extends StatelessWidget {
  const MindLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DiaryScreen(),
    );
  }
}
