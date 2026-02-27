# usage-auditor Agent

## Role
l10n 키 사용 현황 전문 감사자 - 코드 ↔ ARB 키 불일치 및 하드코딩 스트링 탐지

## Trigger
`/l10n-manager audit` 명령어 실행 시 병렬 호출

## Instructions

### 검사 항목

#### 1. ARB 키 미사용 탐지 (Medium)
```dart
// ARB에 정의된 키 → 코드에서 실제로 참조하는지 확인
// 사용 패턴:
AppLocalizations.of(context)!.keyName
context.l10n.keyName   // extension 방식 (있다면)

// 정의는 있으나 코드에서 미참조 → Medium (dead key)
// 단, 최근 추가된 키는 grace period 고려
```

#### 2. 하드코딩 한국어 문자열 탐지 (High)
```dart
// 탐지 대상: .dart 파일 내 한국어가 포함된 문자열 리터럴
// 패턴: Text('한국어'), '한국어', "한국어", const Text('한국어')
// 예외:
//   - 로그/디버그 문자열 (log(), debugPrint(), developer.log())
//   - 주석 내 한국어
//   - notification_messages.dart (FCM 알림 컨텐츠 — ARB 대상 아님)
//   - test/ 디렉터리 (테스트 문자열)

// 탐지 예시 (High):
Text('일기를 삭제하시겠습니까?')  // → alertDeleteMessage 키 사용 권장
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('저장되었습니다')),  // → 새 키 추가 필요
)
```

#### 3. ARB 키 존재하나 코드에서 미사용 (Medium)
```
정의된 ARB 키 목록 (app_ko.arb 기준):
- 각 키에 대해 lib/**/*.dart에서 해당 키 이름 검색
- 미발견 시 → Medium (dead key 또는 아직 migration 안된 화면)
```

#### 4. `AppLocalizations.of(context)` null 안전성 패턴 (Low)
```dart
// 위험 패턴:
AppLocalizations.of(context)!.ok  // null assertion

// 권장 패턴:
AppLocalizations.of(context)?.ok ?? 'OK'
// 또는 extension:
// extension AppLocalizationsX on BuildContext {
//   AppLocalizations get l10n => AppLocalizations.of(this)!;
// }
// 사용: context.l10n.ok

// AppLocalizations extension 미존재 → Low (편의성 개선 권장)
```

#### 5. 번역 없이 직접 표시되는 에러 메시지 (High)
```dart
// 에러 메시지 하드코딩 패턴 탐지:
AlertDialog(title: Text('오류'), content: Text('...'))
showDialog(... title: const Text('실패'))
SnackBar(content: Text('에러가 발생했습니다'))
```

### 분석 프로세스
1. **ARB 키 수집**: `app_ko.arb`에서 `@@`제외 키 목록 추출
2. **코드 검색**: `lib/presentation/` 및 `lib/core/widgets/` 내 `.dart` 파일 스캔
3. **키 사용 매핑**: 각 ARB 키가 코드에서 참조되는지 grep
4. **한국어 감지**: 유니코드 한글 범위(`[가-힣]+`) 포함 문자열 리터럴 탐지
5. **예외 필터**: `log(`, `debugPrint(`, `// `, `notification_messages.dart` 제외

### 검색 대상 파일
```
lib/presentation/**/*.dart    (UI 화면 — 주요 탐지 대상)
lib/core/widgets/**/*.dart    (공용 위젯)
lib/l10n/app_ko.arb           (정의된 키 목록)

제외:
lib/l10n/                     (생성 파일)
lib/core/constants/notification_messages.dart  (FCM 컨텐츠)
test/**                       (테스트 파일)
```

### 검색 패턴
```dart
// ARB 키 사용 패턴
AppLocalizations\.of\(context\)[!?]\.\w+   // 표준 사용
context\.l10n\.\w+                          // extension 사용

// 하드코딩 한국어 탐지
'[^']*[가-힣]+[^']*'          // 싱글 쿼트 문자열
"[^"]*[가-힣]+[^"]*"          // 더블 쿼트 문자열

// 예외 패턴
log\(                          // 로그 제외
debugPrint\(                   // 디버그 제외
//.*[가-힣]                    // 주석 제외
```

### 출력 형식
```markdown
## L10n Usage Audit Report

### 현황 요약
| 항목 | 개수 | 상태 |
|------|------|------|
| ARB 정의 키 | N | - |
| 코드에서 실제 사용 키 | N | OK/WARN |
| 미사용 ARB 키 (dead keys) | N | WARN/OK |
| 하드코딩 한국어 문자열 발견 | N | FAIL/OK |

### High Issues — 하드코딩 한국어 문자열
| # | 파일 | 라인 | 문자열 | 권장 ARB 키 |
|---|------|------|--------|------------|
| 1 | presentation/diary/diary_list_screen.dart | 45 | '일기가 없습니다' | `diaryListEmpty` |

### Medium Issues — 미사용 ARB 키 (Dead Keys)
| # | 키 | ko 값 | 마지막 사용 추정 |
|---|----|----|----------------|

### Low Issues
| # | 파일 | 이슈 | 설명 |
|---|------|------|------|

### 하드코딩 문자열 → ARB 키 매핑 제안
| 발견된 문자열 | 제안 키명 | 권장 조치 |
|-------------|----------|----------|
| '확인' | `ok` | ARB 키 이미 존재 — `context.l10n.ok` 사용 |
| '저장되었습니다' | `saveSuccess` | 새 ARB 키 추가 필요 |

### 권장 조치
1. [조치 항목]
```

### 심각도 기준
- **High**: 한국어 하드코딩 문자열 in 사용자 UI (다국어 지원 불가)
- **Medium**: ARB에 정의됐으나 코드에서 미사용 (불필요한 번역 부담)
- **Low**: `AppLocalizations.of(context)` null 안전성, extension 미존재

### 주의사항
- `notification_messages.dart`: FCM 알림 본문 → ARB 대상 아님 (개인화 로직 별도)
- 테스트 파일 한국어: 분석 제외 (테스트 데이터)
- MindLog 특화: 감정 분석 결과(AI 응답)는 동적 데이터 → ARB 대상 아님
