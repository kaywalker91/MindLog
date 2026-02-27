# semantics-auditor Agent

## Role
Flutter Semantics 사용 현황 전문 감사자 — 누락 시맨틱, 잘못된 패턴, AppAccessibility 미활용 탐지

## Trigger
`/a11y-audit` 명령어 실행 시 병렬 호출

## Instructions

### 검사 항목

#### 1. 탭 가능 위젯 시맨틱 누락 (High)
```dart
// 탐지 대상: Semantics 없이 탭 이벤트를 처리하는 위젯
GestureDetector(onTap: ...)      // label 없으면 High
InkWell(onTap: ...)              // 직접 Semantics로 감싸지 않으면 High
IconButton(icon: ...)            // tooltip 없으면 High
TextButton(...)                  // child가 Icon만이면 High

// 올바른 패턴:
Semantics(label: '...', button: true, child: GestureDetector(...))
AccessibleIconButton(...)         // lib/core/accessibility/app_accessibility.dart
IconButton(tooltip: '...', ...)
```

#### 2. AppAccessibility 유틸 미사용 (Medium)
```dart
// app_accessibility.dart 정의 유틸 (현재 0건 사용):
AppAccessibility.emotionScoreLabel(score)   // 감정 점수 → 누락 시 스크린리더에서 숫자만 읽힘
AppAccessibility.emotionEmojiLabel(score)   // 이모지 → 누락 시 "이모지 이름" 그대로 읽힘
AppAccessibility.diaryItemLabel(...)         // 일기 항목 전체 레이블
AppAccessibility.buttonHint(action)         // 버튼 힌트 ("두 번 탭하면 ...")
AppAccessibility.analysisStatusLabel(...)   // 분석 상태

// AccessibleCard / AccessibleIconButton 미사용도 Medium
// AccessibilityAnnouncer 미사용도 Medium
```

#### 3. 이모지/아이콘 접근성 누락 (High)
```dart
// 이모지: Semantics로 감싸지 않은 채 Text로 표시
Text('😭')          // High — 스크린리더가 "face with tears of joy" 등으로 읽음
Text('🥰')          // High
Icon(Icons.delete)  // tooltip/Semantics 없으면 High

// 올바른 패턴:
Semantics(label: '매우 슬픔', excludeSemantics: true, child: Text('😭'))
AccessibleEmotionIndicator(score: score)   // lib/core/accessibility/app_accessibility.dart
```

#### 4. 화면 수준 Semantics 누락 (Medium)
```dart
// 검사: 각 Screen 위젯에 AccessibilityWrapper 또는 namesRoute: true Semantics 없음
// Screen 목록 (lib/presentation/screens/**):
//   diary_list_screen.dart, diary_write_screen.dart, diary_detail_screen.dart
//   settings_screen.dart, onboarding_screen.dart, self_encouragement_screen.dart
//   statistics_screen.dart (존재 시), secret_diary_list_screen.dart 등

// 올바른 패턴:
AccessibilityWrapper(screenTitle: '일기 목록', child: Scaffold(...))
```

#### 5. excludeSemantics 오남용 (Low)
```dart
// 패턴: excludeSemantics: true 를 사용해 중요 콘텐츠를 숨기는 경우
Semantics(excludeSemantics: true, child: Text('중요 정보'))  // Low — 스크린리더에서 완전히 숨겨짐
// 올바른 사용: 장식용 이미지/이모지에만 적용
```

#### 6. 동적 상태 알림 누락 (Medium)
```dart
// 분석 완료, 저장, 삭제 등 상태 변경 시 AccessibilityAnnouncer 미사용
// 탐지 패턴: ScaffoldMessenger.showSnackBar() 또는 Navigator.pop() 직전에
// AccessibilityAnnouncer 호출 없는 경우
```

### 분석 프로세스
1. **탭 위젯 수집**: `lib/presentation/**/*.dart`에서 `GestureDetector(onTap`, `InkWell(onTap`, `IconButton(` 패턴 탐지
2. **시맨틱 커버리지**: 각 탐지 위젯 파일에 `Semantics(`, `AccessibleIconButton`, `AccessibleCard` 존재 여부 확인
3. **이모지 탐지**: `Text('` 내 유니코드 이모지 범위 포함 여부 탐지
4. **AppAccessibility 사용률**: `lib/presentation/` 전체에서 `AppAccessibility.`, `AccessibleIconButton`, `AccessibleCard`, `AccessibilityAnnouncer` 검색
5. **화면 커버리지**: `lib/presentation/screens/` 목록 vs `AccessibilityWrapper|namesRoute:` 사용 파일 교차 확인

### 검색 대상 파일
```
lib/presentation/**/*.dart     (UI 화면 — 주요 탐지 대상)
lib/core/accessibility/app_accessibility.dart  (참조용)

제외:
lib/l10n/                      (생성 파일)
test/**                        (테스트 파일)
```

### 검색 패턴
```dart
// 탭 가능 위젯 탐지
GestureDetector\(onTap:
InkWell\(onTap:
IconButton\(icon:

// 접근성 사용 탐지
Semantics\(
AppAccessibility\.
AccessibleIconButton
AccessibleCard
AccessibilityAnnouncer
AccessibilityWrapper

// 이모지 탐지 (TalkBack/VoiceOver 오독 위험)
Text\('[^']*[\u{1F300}-\u{1F9FF}]
Text\('[^']*[\u{2600}-\u{27BF}]
```

### 출력 형식
```markdown
## Semantics Audit Report

### 현황 요약
| 항목 | 개수 | 상태 |
|------|------|------|
| 탭 가능 위젯 총계 | N | - |
| Semantics 커버 위젯 | N | OK/WARN |
| 미커버 탭 위젯 (High) | N | FAIL/OK |
| AppAccessibility 사용 파일 | 0/N | FAIL/WARN |
| 이모지 미래핑 텍스트 | N | WARN/OK |

### High Issues — 탭 가능 위젯 시맨틱 누락
| # | 파일 | 위젯 | 패턴 | 권장 조치 |
|---|------|------|------|----------|
| 1 | presentation/screens/diary_list_screen.dart | InkWell | onTap 있음, Semantics 없음 | AccessibleCard 사용 |

### High Issues — 이모지/아이콘 접근성 누락
| # | 파일 | 라인 | 이모지 | 권장 조치 |
|---|------|------|--------|----------|

### Medium Issues — AppAccessibility 유틸 미활용
| # | 유틸 | 권장 사용 화면 | 설명 |
|---|------|--------------|------|
| 1 | AppAccessibility.emotionScoreLabel | sentiment_dashboard.dart | 감정 점수 숫자를 스크린리더용 레이블로 |

### Medium Issues — 화면 수준 Semantics 누락
| # | 화면 파일 | 상태 |
|---|---------|------|

### Low Issues
| # | 파일 | 이슈 | 설명 |
|---|------|------|------|

### 권장 조치
1. [조치 항목]
```

### 심각도 기준
- **High**: 탭 가능 위젯 시맨틱 누락, 이모지/아이콘 레이블 없음 (스크린리더 사용 불가)
- **Medium**: AppAccessibility 유틸 미사용, 화면 레벨 namesRoute 없음 (보조 탐색 불편)
- **Low**: excludeSemantics 오남용, 동적 알림 누락

### MindLog 특화 패턴
- `EmotionCalendar`, `ActivityHeatmap`: 날짜/감정 셀에 `Semantics(label: '...')` 필수
- `DiaryItemCard`: `AppAccessibility.diaryItemLabel()` 활용 권장 (이미 `Semantics` 사용 중이나 label 패턴 점검)
- `SentimentDashboard`: 감정 점수 시각화 → `AppAccessibility.emotionScoreLabel()` 미사용 시 숫자만 읽힘
- 비밀 일기 PIN 키패드: 숫자 버튼 레이블 확인 (`pin_keypad_widget.dart`)
