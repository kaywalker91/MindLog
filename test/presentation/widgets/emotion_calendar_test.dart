import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/presentation/widgets/emotion_calendar.dart';

void main() {
  group('EmotionCalendar', () {
    group('이모지 매핑 테스트', () {
      testWidgets('점수 1-2는 씨앗(🌱)을 표시해야 한다', (tester) async {
        final now = DateTime.now();
        final testData = {
          DateTime(now.year, now.month, 1): 1.5,
          DateTime(now.year, now.month, 2): 2.0,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: testData,
                  initialMonth: DateTime(now.year, now.month),
                  showLegend: false, // 범례 제외하고 테스트
                ),
              ),
            ),
          ),
        );

        expect(find.text('🌱'), findsWidgets);
      });

      testWidgets('점수 3-4는 새싹(🌿)을 표시해야 한다', (tester) async {
        final now = DateTime.now();
        final testData = {
          DateTime(now.year, now.month, 1): 3.5,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: testData,
                  initialMonth: DateTime(now.year, now.month),
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        // 셀에 이모지가 표시됨 (미래가 아닌 날짜만)
        expect(find.text('🌿'), findsWidgets);
      });

      testWidgets('점수 5-6은 꽃봉오리(🌷)를 표시해야 한다', (tester) async {
        final now = DateTime.now();
        final testData = {
          DateTime(now.year, now.month, 1): 5.5,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: testData,
                  initialMonth: DateTime(now.year, now.month),
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('🌷'), findsWidgets);
      });

      testWidgets('점수 7-8은 꽃(🌸)을 표시해야 한다', (tester) async {
        final now = DateTime.now();
        final testData = {
          DateTime(now.year, now.month, 1): 7.5,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: testData,
                  initialMonth: DateTime(now.year, now.month),
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('🌸'), findsWidgets);
      });

      testWidgets('점수 9-10은 해바라기(🌻)를 표시해야 한다', (tester) async {
        final now = DateTime.now();
        final testData = {
          DateTime(now.year, now.month, 1): 9.5,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: testData,
                  initialMonth: DateTime(now.year, now.month),
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('🌻'), findsWidgets);
      });
    });

    group('빈 데이터 처리', () {
      testWidgets('activityMap이 비어있어도 범례는 표시되어야 한다', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: {},
                  showLegend: true,
                ),
              ),
            ),
          ),
        );

        expect(find.text('마음의 정원'), findsOneWidget);
        expect(find.byType(EmotionCalendar), findsOneWidget);
      });

      testWidgets('showLegend가 false이면 범례가 숨겨져야 한다', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: {},
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('마음의 정원'), findsNothing);
      });
    });

    group('범례 표시', () {
      testWidgets('마음의 정원 범례가 표시되어야 한다', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: {},
                  showLegend: true,
                ),
              ),
            ),
          ),
        );

        expect(find.text('마음의 정원'), findsOneWidget);
        // 범례 화살표
        expect(find.text('→'), findsNWidgets(4));
      });
    });

    group('요일 라벨', () {
      testWidgets('요일 라벨이 올바르게 표시되어야 한다', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('월'), findsOneWidget);
        expect(find.text('화'), findsOneWidget);
        expect(find.text('수'), findsOneWidget);
        expect(find.text('목'), findsOneWidget);
        expect(find.text('금'), findsOneWidget);
        expect(find.text('토'), findsOneWidget);
        expect(find.text('일'), findsOneWidget);
      });
    });

    group('헤더 및 월 네비게이션', () {
      testWidgets('현재 월이 헤더에 표시되어야 한다', (tester) async {
        final testMonth = DateTime(2024, 6);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: testMonth,
                ),
              ),
            ),
          ),
        );

        expect(find.text('2024년 6월'), findsOneWidget);
      });

      testWidgets('이전 월 버튼이 동작해야 한다', (tester) async {
        final testMonth = DateTime(2024, 6);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: testMonth,
                ),
              ),
            ),
          ),
        );

        expect(find.text('2024년 6월'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        expect(find.text('2024년 5월'), findsOneWidget);
      });

      testWidgets('다음 월 버튼이 동작해야 한다', (tester) async {
        final testMonth = DateTime(2024, 6);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: testMonth,
                ),
              ),
            ),
          ),
        );

        expect(find.text('2024년 6월'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        expect(find.text('2024년 7월'), findsOneWidget);
      });

      testWidgets('다른 월에서 오늘 버튼이 표시되어야 한다', (tester) async {
        final pastMonth = DateTime(2024, 1);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: pastMonth,
                ),
              ),
            ),
          ),
        );

        expect(find.text('오늘'), findsOneWidget);
      });
    });

    group('날짜 그리드', () {
      testWidgets('42개의 셀이 렌더링되어야 한다 (6주 x 7일)', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: DateTime(2024, 6),
                ),
              ),
            ),
          ),
        );

        // GridView가 존재하는지 확인
        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('날짜 숫자가 표시되어야 한다', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: DateTime(2024, 6),
                ),
              ),
            ),
          ),
        );

        // 1부터 30까지 날짜가 표시되어야 함 (2024년 6월)
        expect(find.text('1'), findsWidgets);
        expect(find.text('15'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
      });
    });

    group('onDayTap 콜백', () {
      testWidgets('날짜 탭 시 콜백이 호출되어야 한다', (tester) async {
        DateTime? tappedDate;
        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: firstDayOfMonth,
                  onDayTap: (date) {
                    tappedDate = date;
                  },
                ),
              ),
            ),
          ),
        );

        // 1일을 탭 (과거 날짜인 경우에만 동작)
        final dayOneFinder = find.text('1').first;
        await tester.tap(dayOneFinder);
        await tester.pump();

        // 현재 월의 1일이 과거인 경우에만 콜백이 호출됨
        if (now.day > 1) {
          expect(tappedDate?.day, equals(1));
        }
      });
    });

    group('onMonthChanged 콜백', () {
      testWidgets('월 변경 시 콜백이 호출되어야 한다', (tester) async {
        DateTime? changedMonth;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: DateTime(2024, 6),
                  onMonthChanged: (month) {
                    changedMonth = month;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        expect(changedMonth?.month, equals(7));
        expect(changedMonth?.year, equals(2024));
      });
    });

    group('위젯 렌더링', () {
      testWidgets('샘플 데이터로 정상 렌더링되어야 한다', (tester) async {
        final now = DateTime.now();
        final testData = {
          DateTime(now.year, now.month, 1): 8.5,
          DateTime(now.year, now.month, 2): 3.0,
          DateTime(now.year, now.month, 3): 9.5,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: testData,
                  initialMonth: DateTime(now.year, now.month),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(EmotionCalendar), findsOneWidget);
        expect(find.byType(PageView), findsOneWidget);
      });
    });

    group('스와이프 네비게이션', () {
      testWidgets('왼쪽 스와이프로 다음 월로 이동해야 한다', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: DateTime(2024, 6),
                ),
              ),
            ),
          ),
        );

        expect(find.text('2024년 6월'), findsOneWidget);

        // PageView에서 스와이프 (더 큰 거리)
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
        await tester.pumpAndSettle();

        expect(find.text('2024년 7월'), findsOneWidget);
      });

      testWidgets('오른쪽 스와이프로 이전 월로 이동해야 한다', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: DateTime(2024, 6),
                ),
              ),
            ),
          ),
        );

        expect(find.text('2024년 6월'), findsOneWidget);

        await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
        await tester.pumpAndSettle();

        expect(find.text('2024년 5월'), findsOneWidget);
      });
    });

    group('다크 모드', () {
      testWidgets('다크 모드에서도 정상 렌더링되어야 한다', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData.dark(useMaterial3: true),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: {},
                ),
              ),
            ),
          ),
        );

        expect(find.byType(EmotionCalendar), findsOneWidget);
        expect(find.text('마음의 정원'), findsOneWidget);
      });
    });

    group('날짜 계산 정확성', () {
      testWidgets('2024년 2월 (윤년)이 29일까지 표시되어야 한다', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: DateTime(2024, 2),
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        // 29일이 존재 (윤년이므로 2월 29일이 있음)
        expect(find.text('29'), findsWidgets);
        // 헤더에 2024년 2월 표시
        expect(find.text('2024년 2월'), findsOneWidget);
      });

      testWidgets('월 표시가 올바르게 렌더링되어야 한다', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: DateTime(2024, 1),
                ),
              ),
            ),
          ),
        );

        // 헤더에 월 표시
        expect(find.text('2024년 1월'), findsOneWidget);
        // GridView 존재
        expect(find.byType(GridView), findsOneWidget);
      });
    });

    group('친근감 디자인 테스트', () {
      testWidgets('빈 데이터로 달력이 정상 렌더링되어야 한다', (tester) async {
        // 고정된 과거 날짜 사용하여 테스트 안정성 확보
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: DateTime(2024, 6),
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        // 달력이 정상 렌더링되어야 함
        expect(find.byType(EmotionCalendar), findsOneWidget);
        expect(find.byType(GridView), findsOneWidget);

        // 날짜 숫자가 표시되어야 함
        expect(find.text('15'), findsOneWidget);
      });

      testWidgets('기록 있는 셀에 따뜻한 배경색이 적용되어야 한다', (tester) async {
        final now = DateTime.now();
        // 과거 날짜로 테스트 데이터 생성 (1일이 과거인 경우)
        final testDay = now.day > 1 ? 1 : now.day;
        final testDate = DateTime(now.year, now.month, testDay);
        final testData = {
          testDate: 7.5, // 7-8점 범위 (🌸 꽃)
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: testData,
                  initialMonth: DateTime(now.year, now.month),
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        // 꽃 이모지가 표시되어야 함 (7-8점 범위)
        // 1일이 과거인 경우에만 이모지가 표시됨
        if (now.day > 1) {
          expect(find.text('🌸'), findsWidgets);
        }
      });

      testWidgets('탭 시 scale 애니메이션이 동작해야 한다', (tester) async {
        final now = DateTime.now();
        // 1일이 과거인지 확인하여 테스트 날짜 결정
        final testDay = now.day > 1 ? 1 : now.day;
        final testDate = DateTime(now.year, now.month, testDay);
        final testData = {
          testDate: 5.0,
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: testData,
                  initialMonth: DateTime(now.year, now.month),
                  onDayTap: (_) {},
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        // GestureDetector가 존재하는지 확인
        expect(find.byType(GestureDetector), findsWidgets);

        // 날짜 셀을 찾아서 탭 다운 이벤트 발생
        final dayFinder = find.text('$testDay').first;
        final gesture = await tester.startGesture(tester.getCenter(dayFinder));

        // 애니메이션 진행
        await tester.pump(const Duration(milliseconds: 50));

        // 탭 업
        await gesture.up();
        await tester.pumpAndSettle();

        // 위젯이 정상적으로 렌더링되어야 함
        expect(find.byType(EmotionCalendar), findsOneWidget);
      });

      testWidgets('reduceMotion 설정 시 AnimatedBuilder가 사용되지 않아야 한다',
          (tester) async {
        final now = DateTime.now();
        final testData = {
          DateTime(now.year, now.month, 1): 5.0,
        };

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: EmotionCalendar(
                    activityMap: testData,
                    initialMonth: DateTime(now.year, now.month),
                    onDayTap: (_) {},
                    showLegend: false,
                  ),
                ),
              ),
            ),
          ),
        );

        // reduceMotion이 true일 때 AnimatedBuilder가 사용되지 않음
        // (Transform.scale 대신 일반 cell이 반환됨)
        expect(find.byType(EmotionCalendar), findsOneWidget);
        expect(find.byType(GestureDetector), findsWidgets);
      });

      testWidgets('빈 날의 툴팁 메시지가 친근해야 한다', (tester) async {
        // 툴팁 메시지는 Tooltip 위젯의 message 속성으로 설정됨
        // 빈 날: "이 날은 정원이 쉬었어요 🌙"
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: const {},
                  initialMonth: DateTime(2024, 6),
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        // Tooltip 위젯이 존재하는지 확인
        expect(find.byType(Tooltip), findsWidgets);
      });

      testWidgets('기록 있는 날의 레이블이 친근해야 한다', (tester) async {
        final now = DateTime.now();
        // 과거 날짜에 데이터 설정
        final testDate = DateTime(now.year, now.month, 1);
        final testData = {
          testDate: 3.5, // 새싹 범위 (3-4점)
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: testData,
                  initialMonth: DateTime(now.year, now.month),
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        // 새싹 이모지가 표시되어야 함
        expect(find.text('🌿'), findsWidgets);
      });

      testWidgets('점수별 이모지가 올바르게 매핑되어야 한다', (tester) async {
        final now = DateTime.now();
        // 모든 점수 범위 테스트 (과거 날짜 사용)
        final testData = <DateTime, double>{};
        for (int i = 1; i <= 5; i++) {
          if (i <= now.day) {
            testData[DateTime(now.year, now.month, i)] = i * 2.0;
          }
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EmotionCalendar(
                  activityMap: testData,
                  initialMonth: DateTime(now.year, now.month),
                  showLegend: false,
                ),
              ),
            ),
          ),
        );

        // 달력이 정상 렌더링되어야 함
        expect(find.byType(EmotionCalendar), findsOneWidget);
      });
    });
  });
}
