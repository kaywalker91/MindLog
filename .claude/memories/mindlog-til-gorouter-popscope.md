# MindLog TIL: go_router + PopScope 호환성 패턴

## 날짜
2026-02-02

## 주제
go_router v17+에서 Android 시스템 뒤로가기 버튼 처리

## 문제
PopScope의 `canPop: GoRouter.of(context).canPop()`이 빌드 시점에 한 번만 평가되어,
이후 push로 스택이 쌓여도 값이 업데이트되지 않음.

## 해결 패턴

### 1. PopScope 동적 분기 패턴
```dart
PopScope(
  canPop: false,  // 모든 pop 이벤트 인터셉트
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;

    // 런타임에 스택 상태 확인
    if (GoRouter.of(context).canPop()) {
      context.pop();  // 서브화면 → 정상 pop
      return;
    }

    // 루트 화면 → 앱 종료 처리
    // ...
  },
)
```

### 2. Navigation Extension 패턴
```dart
// go() vs push() 차이점
// - go(): 스택 교체 (뒤로가기 불가)
// - push(): 스택 추가 (뒤로가기 가능)

// 서브 화면 이동 시 push 사용
void pushSettings() => push(AppRoutes.settings);
void pushPrivacyPolicy() => push(AppRoutes.privacyPolicy);

// 홈으로 완전 이동 시 go 사용
void goHome() => go(AppRoutes.home);
```

## 관련 GitHub Issues
- flutter/flutter#138737: PopScope incompatibility with GoRouter
- flutter/flutter#140869: PopScope doesn't trigger on root screens

## 적용 대상
- MainScreen에서 Android 뒤로가기 버튼 처리
- IndexedStack 기반 탭 네비게이션과 go_router 혼용 시

## 키워드
go_router, PopScope, canPop, Android back button, navigation stack
