# arch-check

Clean Architecture 의존성 위반 검사 자동화 스킬 (`/arch-check`)

## 목표
- 레이어 간 의존성 위반 자동 탐지
- presentation → data 직접 import 차단
- domain → data/presentation 참조 금지 확인

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "/arch-check" 명령어
- "아키텍처 위반 검사해줘" 요청
- PR 리뷰 시 자동 권장
- 리팩토링 세션 시작 시

## 참조 규칙
참조: `.claude/rules/architecture.md`

```
## Layer Dependencies
- presentation → domain (O)
- data → domain (O)
- domain → data/presentation (X - forbidden)
- presentation → data (X - DI 통해서만)
```

## 프로세스

### Step 1: 금지된 Import 패턴 검사
```bash
# P0: presentation → data 직접 import (Provider 제외)
grep -rn "import.*data/datasources\|import.*data/dto" lib/presentation/ --include="*.dart"

# P0: domain → data 참조
grep -rn "import.*data/" lib/domain/ --include="*.dart"

# P0: domain → presentation 참조
grep -rn "import.*presentation/" lib/domain/ --include="*.dart"
```

### Step 2: 위반 심각도 분류
| 심각도 | 패턴 | 설명 |
|--------|------|------|
| **P0 Critical** | `domain → data/*` | 핵심 원칙 위반 |
| **P0 Critical** | `domain → presentation/*` | 핵심 원칙 위반 |
| **P1 High** | `presentation → data/datasources` | DI 우회 |
| **P1 High** | `presentation → data/dto` | DTO 직접 참조 |
| **P2 Medium** | `data/repo → data/dto (cross)` | DTO 의존성 정리 필요 |

### Step 3: 위반 상세 분석
각 위반에 대해:
1. 파일 경로 및 라인 번호
2. import 대상 파일
3. 실제 사용되는 클래스/함수
4. 권장 수정 방법

### Step 4: 수정 가이드 제공
```dart
// 위반 예시: presentation → data 직접 참조
// ❌ 잘못된 코드
import '../../data/datasources/preferences_local_data_source.dart';
final prefs = PreferencesLocalDataSource();

// ✅ 올바른 코드: Repository 인터페이스 통한 DI
import '../../domain/repositories/settings_repository.dart';
// Provider에서 주입받아 사용
final repository = ref.watch(settingsRepositoryProvider);
```

### Step 5: 검증 스크립트 실행
```bash
#!/bin/bash
# arch-check.sh

echo "=== Clean Architecture Violation Check ==="

# Domain layer violations (CRITICAL)
echo -e "\n🔴 P0: Domain Layer Violations"
DOMAIN_DATA=$(grep -rn "import.*data/" lib/domain/ --include="*.dart" 2>/dev/null | wc -l)
DOMAIN_PRES=$(grep -rn "import.*presentation/" lib/domain/ --include="*.dart" 2>/dev/null | wc -l)

if [ "$DOMAIN_DATA" -gt 0 ] || [ "$DOMAIN_PRES" -gt 0 ]; then
  echo "❌ CRITICAL: Domain layer has forbidden dependencies"
  grep -rn "import.*data/\|import.*presentation/" lib/domain/ --include="*.dart"
else
  echo "✅ Domain layer is clean"
fi

# Presentation → Data violations
echo -e "\n🟠 P1: Presentation → Data Violations"
PRES_DATA=$(grep -rn "import.*data/datasources\|import.*data/dto" lib/presentation/ --include="*.dart" 2>/dev/null | wc -l)

if [ "$PRES_DATA" -gt 0 ]; then
  echo "⚠️  Found $PRES_DATA presentation → data violations:"
  grep -rn "import.*data/datasources\|import.*data/dto" lib/presentation/ --include="*.dart"
else
  echo "✅ No presentation → data violations"
fi

echo -e "\n=== Check Complete ==="
```

## 출력 형식

```
=== 🏗️ Architecture Violation Report ===

📊 Summary
├── 총 검사 파일: 116개
├── P0 Critical: 0개 ✅
├── P1 High: 1개 ⚠️
└── P2 Medium: 0개 ✅

🔴 P0 Critical Violations (0)
(없음)

🟠 P1 High Violations (1)
┌─────────────────────────────────────────────────────────
│ File: lib/presentation/providers/update_state_provider.dart
│ Line: 5
│ Import: import '../../data/datasources/preferences_local_data_source.dart'
│ Used: PreferencesLocalDataSource (getDismissedUpdateVersion, setDismissedUpdateVersion)
│
│ 💡 Fix: SettingsRepository 인터페이스에 메서드 추가 후 DI로 주입
│ 참조: Phase 1 of refactoring plan
└─────────────────────────────────────────────────────────

🟢 P2 Medium Violations (0)
(없음)

다음 단계:
└── 위반 사항에 대한 리팩토링 계획 수립: /refactor-plan
```

## 네이밍 규칙

| 항목 | 검사 대상 | 금지 패턴 |
|------|----------|----------|
| domain | `lib/domain/**/*.dart` | `import.*data/`, `import.*presentation/` |
| presentation | `lib/presentation/**/*.dart` | `import.*data/datasources`, `import.*data/dto` |
| data | `lib/data/**/*.dart` | `import.*presentation/` |

## 사용 예시

```
> "/arch-check"

AI 응답:
1. lib/domain/ 검사: 0개 위반 ✅
2. lib/presentation/ 검사: 1개 위반 발견
   - update_state_provider.dart:5 → data/datasources 직접 import
3. lib/data/ 검사: 0개 위반 ✅
4. 총 1개 P1 위반 발견
5. 수정 가이드 제공

권장 조치:
├── SettingsRepository에 getDismissedUpdateVersion() 추가
├── SettingsRepositoryImpl에 구현
└── UpdateStateNotifier에서 Repository 통해 접근
```

## 연관 스킬
- `/refactor-plan` - 위반 수정 계획 수립
- `/provider-centralize` - Provider 정리
- `/review [file]` - 코드 리뷰

## 주의사항
- Provider 파일은 data import가 필요한 경우가 있음 (Repository 구현체 연결)
- `infra_providers.dart` 같은 DI 설정 파일은 예외로 처리
- 테스트 파일은 검사 대상에서 제외

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P0 |
| Category | quality |
| Dependencies | - |
| Created | 2026-01-26 |
| Updated | 2026-01-26 |
