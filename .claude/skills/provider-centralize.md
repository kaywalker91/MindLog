# provider-centralize

Provider 중복 및 분산 분석, 중앙화 권장 스킬 (`/provider-centralize`)

## 목표
- Provider 중복 정의 탐지
- UI State Provider 분산 식별
- Provider 배럴 파일 완전성 검증
- 중앙화 리팩토링 가이드 제공

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "/provider-centralize" 명령어
- "Provider 정리해줘" 요청
- 새 Provider 추가 시 중복 검사
- 리팩토링 세션 시작 시

## 참조 템플릿
참조: `lib/presentation/providers/` 구조

```
lib/presentation/providers/
├── providers.dart           # 배럴 파일 (모든 export)
├── infra_providers.dart     # Repository, UseCase 주입
├── ui_state_providers.dart  # UI 상태 (탭, 기간 선택 등)
├── statistics_providers.dart
├── diary_list_controller.dart
└── ...
```

## 프로세스

### Step 1: Provider 인벤토리 수집
```bash
# 모든 Provider 정의 검색
grep -rn "final.*Provider\|final.*StateProvider\|final.*FutureProvider\|final.*StreamProvider" lib/presentation/providers/ --include="*.dart"

# Screen/Widget 내 Provider 정의 검색 (분산 후보)
grep -rn "final.*Provider" lib/presentation/screens/ lib/presentation/widgets/ --include="*.dart"
```

### Step 2: 중복 Provider 탐지
동일 이름 또는 유사 기능 Provider 식별:
```bash
# 이름 기반 중복 검사
grep -oh "final \w*Provider" lib/presentation/ -r --include="*.dart" | sort | uniq -d
```

중복 패턴 분류:
| 패턴 | 예시 | 조치 |
|------|------|------|
| 동일 이름 | `diaryListProvider` 2개 | 하나로 통합 |
| 유사 기능 | `diaryProvider` + `diaryListControllerProvider` | 역할 명확화 후 통합 |
| autoDispose 불일치 | 같은 데이터, 다른 생명주기 | 사용처 분석 후 통합 |

### Step 3: UI State 분산 식별
UI 상태 Provider가 Screen/Widget에 정의된 경우:
```dart
// ❌ 분산된 정의 (screen 파일 내)
class SomeScreen extends ConsumerWidget {
  static final selectedIndexProvider = StateProvider<int>((ref) => 0);
}

// ✅ 중앙화된 정의 (ui_state_providers.dart)
// lib/presentation/providers/ui_state_providers.dart
final selectedIndexProvider = StateProvider<int>((ref) => 0);
```

### Step 4: 배럴 파일 완전성 검증
```bash
# providers.dart에서 export 중인 파일
grep "^export" lib/presentation/providers/providers.dart

# providers/ 내 모든 dart 파일
ls lib/presentation/providers/*.dart | grep -v providers.dart

# 누락된 export 식별
diff <(grep "^export" lib/presentation/providers/providers.dart | sed "s/export '//;s/';//" | sort) \
     <(ls lib/presentation/providers/*.dart | xargs -n1 basename | grep -v providers.dart | sort)
```

### Step 5: 중앙화 계획 수립

**UI State Provider 분류 기준:**
| 카테고리 | 저장 위치 | 예시 |
|----------|----------|------|
| 화면 간 공유 | `ui_state_providers.dart` | 탭 인덱스, 기간 선택 |
| 기능 특화 | `{feature}_providers.dart` | 일기 분석 상태 |
| 인프라 | `infra_providers.dart` | Repository, UseCase |

### Step 6: 리팩토링 실행
```dart
// 1. ui_state_providers.dart에 Provider 이동
// lib/presentation/providers/ui_state_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 메인 화면 탭 인덱스
final selectedTabIndexProvider = StateProvider<int>((ref) => 0);

/// 통계 화면 기간 선택
final selectedStatisticsPeriodProvider = StateProvider<StatisticsPeriod>(
  (ref) => StatisticsPeriod.week,
);

// 2. 기존 정의 제거 및 import 추가
// 각 사용처에서:
import '../providers/ui_state_providers.dart';

// 3. providers.dart에 export 추가
export 'ui_state_providers.dart';
```

## 출력 형식

```
=== 🗂️ Provider Centralization Report ===

📊 Summary
├── 총 Provider 수: 23개
├── 중복 의심: 2개
├── 분산 UI State: 2개
└── 배럴 누락: 3개

🔴 중복 Provider (2)
┌─────────────────────────────────────────────────────────
│ 1. diaryListProvider
│    ├── diary_analysis_controller.dart:108 (autoDispose)
│    └── diary_list_controller.dart:15 (영구)
│    💡 Fix: diary_list_controller.dart의 Provider로 통합
│
│ 2. todayDiariesProvider
│    ├── diary_analysis_controller.dart:114 (autoDispose)
│    💡 Fix: diaryListControllerProvider에서 파생하도록 변경
└─────────────────────────────────────────────────────────

🟠 분산된 UI State (2)
┌─────────────────────────────────────────────────────────
│ 1. selectedTabIndexProvider
│    └── main_screen.dart:25
│    💡 Fix: ui_state_providers.dart로 이동
│
│ 2. selectedStatisticsPeriodProvider
│    └── statistics_providers.dart:8
│    💡 Fix: ui_state_providers.dart로 이동
└─────────────────────────────────────────────────────────

🟡 배럴 파일 누락 (3)
┌─────────────────────────────────────────────────────────
│ providers.dart에 export 누락:
│ ├── diary_analysis_controller.dart
│ ├── notification_settings_controller.dart
│ └── firebase_providers.dart
└─────────────────────────────────────────────────────────

다음 단계:
├── /refactor-plan - 중복 제거 계획 수립
└── providers.dart에 누락 export 추가
```

## 네이밍 규칙

| Provider 종류 | 네이밍 | 예시 |
|--------------|--------|------|
| State | `{name}Provider` | `selectedTabIndexProvider` |
| Future | `{name}Provider` | `statisticsProvider` |
| StateNotifier | `{name}ControllerProvider` | `diaryListControllerProvider` |
| Notifier | `{name}NotifierProvider` | `updateStateNotifierProvider` |

## 사용 예시

```
> "/provider-centralize"

AI 응답:
1. Provider 인벤토리 수집: 23개 발견
2. 중복 분석: 2개 중복 의심
   - diaryListProvider (2곳 정의)
   - todayDiariesProvider (불필요한 별도 정의)
3. UI State 분산: 2개 발견
   - selectedTabIndexProvider (main_screen.dart)
   - selectedStatisticsPeriodProvider (statistics_providers.dart)
4. 배럴 파일: 3개 export 누락
5. 리팩토링 권장사항 제공
```

## 연관 스킬
- `/arch-check` - 아키텍처 위반 검사
- `/refactor-plan` - 리팩토링 계획 수립
- `/lint-fix` - 린트 오류 자동 수정

## 주의사항
- autoDispose vs 영구 Provider: 사용처의 생명주기 고려
- 순환 의존성: Provider 간 watch 체인 확인
- 테스트 영향: Mock override 필요성 검토
- 마이그레이션: 점진적 이동으로 빌드 오류 최소화

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | quality |
| Dependencies | - |
| Created | 2026-01-26 |
| Updated | 2026-01-26 |
