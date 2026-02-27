# 실리콘밸리 Claude Code × Flutter 개발 워크플로우 브리핑

> 조사 기준일: 2026년 2월 27일 | 주요 출처: CodeWithAndrea, Flutter 공식 문서, Medium 개발자 사례, GitHub 오픈소스 프로젝트

---

## 1. 핵심 요약 (Executive Summary)

실리콘밸리와 글로벌 Flutter 커뮤니티에서 Claude Code는 **"Vibe Coding"이 아닌 "AI-Assisted Software Development"** 라는 패러다임으로 자리잡고 있다. 
핵심은 **사전 기획(Plan-first) → 구조화된 프롬프트 → 단계별 검증** 의 체계적 워크플로우이며, 숙련된 개발자일수록 Claude Code를 통해 생산성을 극대화하고 있다.

대표적인 사례로 Andrea Bizzotto(CodeWithAndrea)는 Voice Timer 앱을 Claude Code + Opus 4 모델로 개발하여 실제 App Store에 출시했고, Rémy Baudet는 Feature-First Clean Architecture 기반의 geofencing 앱 프로토타입을 2시간 만에 완성했다.

---

## 2. 표준 워크플로우: 5단계 개발 프로세스

### Phase 1: 프로젝트 초기화 & 컨텍스트 설정

**CLAUDE.md 설정이 가장 중요한 첫 단계다.** `/init` 명령으로 프로젝트를 분석한 뒤, 생성된 CLAUDE.md를 직접 편집하여 프로젝트의 아키텍처, 코딩 컨벤션, 빌드/테스트 명령어를 명시한다.

```
# CLAUDE.md 예시 (Flutter 프로젝트)
# 프로젝트: iLity Hub - 멀티체인 크립토 지갑
# 아키텍처: Clean Architecture + Riverpod
# 코드 스타일: dart analyze --fatal-infos, Effective Dart 준수
# 테스트: flutter test 실행 후 커밋
# 상태관리: Riverpod (Provider 사용 금지)
# 폴더 구조: Feature-First (lib/features/{feature}/data|domain|presentation)
```

**CLAUDE.md 작성 원칙:**
- 150줄 이하로 유지 (너무 길면 Claude가 지시를 무시하기 시작함)
- 브로드한 규칙만 포함하고, 도메인별 지식은 `.claude/skills/`에 분리
- `@docs/architecture.md` 같은 외부 파일 참조 활용
- Git에 커밋하여 팀 전체가 공유

### Phase 2: 상세 요구사항 문서 작성

**"Forget vibe coding"** — 이것이 실리콘밸리 개발자들의 공통된 조언이다. Claude에게 코드를 작성시키기 전에 반드시 상세한 요구사항 문서를 먼저 작성한다.

```
# docs/initial-requirements.md 예시
## 기능 요구사항
- WalletConnect v2를 통한 지갑 연결
- EVM 호환 체인(Ethereum, BSC, Base) 지원
- Deep Link Cold Start 처리 큐 시스템

## 비기능 요구사항
- Clean Architecture (Domain → Data → Presentation)
- Riverpod으로 상태관리
- 모든 비즈니스 로직에 유닛 테스트 작성
- Effective Dart 코딩 스타일 준수
```

Andrea Bizzotto는 이렇게 강조한다: *"구체적인 요구사항을 사전에 작성하면 AI가 의도를 정확히 파악하고, 이후 리팩토링이 크게 줄어든다."*

### Phase 3: Plan Mode로 실행 계획 수립

Claude Code의 Plan Mode(Shift+Tab 두 번)를 사용하여 요구사항을 실행 가능한 단계로 분해한다.

```
# 프롬프트 예시
"@docs/initial-requirements.md를 참고하여 WalletConnect v2 연동 기능의
구현 계획을 세워줘. 코드는 작성하지 말고 계획만 세워줘."
```

**Plan Mode 활용 핵심:**
- PLAN.md 파일로 계획을 관리하고 단계별로 업데이트
- 각 단계를 5~10분 단위의 atomic task로 분해
- 각 task 완료 후 반드시 빌드/테스트 → Git 커밋

### Phase 4: 모델 전략적 활용 (단계별 모델 전환)

실리콘밸리 개발자들은 프로젝트 단계에 따라 Claude 모델을 전략적으로 전환한다:

| 단계 | 모델 | 용도 |
|------|------|------|
| **브레인스토밍/초기 UI** | Haiku 4.5 | 빠른 아이디어 검증, 작은 위젯 구현 |
| **핵심 기능 개발** | Sonnet 4.5 | 멀티 파일 변경, Firebase 연동, 상태관리 |
| **최종 검증/최적화** | Opus 4+ | 메모리 누수, 불필요한 리빌드, 비동기 로직 버그 탐지 |

### Phase 5: 검증 & 반복

```bash
# Custom 커맨드 예시 (.claude/commands/)
# /commit - 자동 커밋 워크플로우
# /test-and-commit - 테스트 실행 후 커밋
# /plan-update - PLAN.md 진행상황 업데이트
```

---

## 3. MCP Server 연동: 게임 체인저

### 3-1. Dart & Flutter 공식 MCP Server

Flutter 팀이 공식 제공하는 MCP 서버(Dart 3.9+ / Flutter 3.35+ 필요)로, Claude Code가 실행 중인 Flutter 앱과 직접 소통할 수 있다.

**주요 기능:**
- **위젯 트리 인스펙션**: 레이아웃 이슈를 AI가 직접 분석
- **런타임 에러 분석**: RenderFlex overflow 같은 에러를 자동 감지 및 수정
- **pub.dev 패키지 검색 & 의존성 관리**: 자연어로 패키지 추가
- **Hot Reload/Restart 트리거**: 코드 변경 즉시 반영
- **테스트 실행 & 결과 분석**

```bash
# 설정 (Flutter beta 채널 필요)
flutter channel beta
flutter upgrade
# MCP 서버가 자동으로 사용 가능
```

### 3-2. mcp_flutter (커뮤니티 오픈소스)

Arenukvern이 개발한 오픈소스 MCP 서버로, 더 심화된 디버깅 기능을 제공한다.

**아키텍처:**
```
Claude Code ←→ MCP Server ←→ Flutter Debug Service ←→ Flutter App (with MCP Toolkit)
```

**주요 기능:**
- 스크린샷 캡처 (Claude가 앱 화면을 직접 볼 수 있음)
- 에러 모니터링 (Dart VM 에러를 Claude에 최적화된 형태로 전달)
- 동적 MCP 도구 등록 (앱 내에서 커스텀 도구 런타임 등록)
- 위젯 선택 & 상세 정보 조회

```bash
# 설치
cd ~/Developer
git clone https://github.com/Arenukvern/mcp_flutter
cd mcp_flutter && make install

# Claude Code에 등록
claude mcp add flutter-inspector \
  ~/Developer/mcp_flutter/mcp_server_dart/build/flutter_inspector_mcp \
  -- --dart-vm-host=localhost --dart-vm-port=[PORT] --no-resources --images
```

### 3-3. Marionette MCP (UI 자동 테스트)

LeanCode에서 개발한 MCP 서버로, Claude가 실행 중인 앱의 UI를 직접 조작할 수 있다.

**사용 시나리오:**
```
"Forgot Password 화면을 구현했으니 검증해줘. 앱에 연결해서 로그인 화면으로
이동하고, 'Forgot Password'를 탭하고, 유효한 이메일을 입력한 뒤 제출해.
로그에서 API 호출이 성공했는지 확인해줘."
```

---

## 4. Sub-Agent 활용 패턴

Claude Code 2.0의 Sub-Agent 기능을 활용하여 병렬 개발이 가능하다:

| Sub-Agent | 담당 영역 |
|-----------|-----------|
| **UI Agent** | 화면 구현, 위젯 조합, 애니메이션 |
| **Logic Agent** | Riverpod Provider, 비즈니스 로직 |
| **Firebase Agent** | Auth, Firestore, FCM 설정 |
| **Test Agent** | 유닛/위젯/통합 테스트 작성 |

각 Agent가 독립적으로 작업하면서도 프로젝트 컨텍스트를 공유하여, 한 사람이 여러 명의 팀원과 협업하는 것과 유사한 효과를 낸다.

---

## 5. Skills & Hooks: 자동화 설정

### Skills (도메인별 지식)

```
.claude/skills/
├── wallet-connect/SKILL.md    # WalletConnect 연동 패턴
├── riverpod-patterns/SKILL.md # Riverpod 아키텍처 패턴
└── testing/SKILL.md           # Flutter 테스트 베스트 프랙티스
```

Claude가 관련 작업 시 자동으로 해당 Skill을 참조한다.

### Hooks (자동 실행 스크립트)

```bash
# 파일 수정 후 자동으로 dart analyze 실행
claude hooks add post-edit "dart analyze --fatal-infos"

# 커밋 전 자동 테스트
claude hooks add pre-commit "flutter test"
```

---

## 6. 실전 사례에서 배운 교훈

### ✅ Claude Code가 잘하는 것
- **보일러플레이트 생성**: Clean Architecture 레이어 구조, Repository 패턴 등
- **API 문서 기반 코드 생성**: pub.dev 패키지 사용법을 문서에서 읽고 적용
- **테스트 코드 작성**: 비즈니스 로직에 대한 유닛 테스트 자동 생성
- **복잡한 로직 구현**: 상태 머신, 비동기 처리 패턴 등
- **프로젝트 구조 설정**: 폴더 구조, 의존성, 설정 파일 등 초기 세팅

### ⚠️ 주의해야 할 점
- **컨텍스트 망각**: 긴 세션에서 이전 지시사항을 잊는 경우가 빈번 (테스트-커밋 습관 등)
- **시각적 피드백 부재**: UI 디자인 미세 조정은 개발자가 직접 확인 필요 (MCP로 부분 해결)
- **SVG/그래픽 작업**: 로고, 복잡한 그래픽 요소는 수동 작업이 더 효율적
- **80% 제약 현상**: 전체 제약조건 중 무작위로 80%만 기억하는 whack-a-mole 문제
- **네이티브 통합**: 플랫폼별 권한, 음성인식 등 네이티브 기능은 추가 디버깅 필요

### 💡 생산성 극대화 팁
1. **첫 70%는 Claude에게, 나머지 30%는 직접 작성** — 이것이 가장 빠른 조합
2. **Checkpoint 적극 활용** — 예상치 못한 삭제/변경 시 즉시 롤백
3. **각 Task 완료 시 Git 커밋** — 작동 상태를 항상 유지
4. **커스텀 커맨드로 반복 작업 자동화**
5. **CLAUDE.md를 코드처럼 관리** — 문제 발생 시 검토, 정기적 정리, 변경 후 행동 관찰

---

## 7. 추천 도구 조합 (2025-2026 기준)

| 도구 | 역할 | 비고 |
|------|------|------|
| **Claude Code (Max Plan)** | 핵심 코딩 에이전트 | Opus 4+ 모델 접근 |
| **Dart & Flutter MCP Server** | 런타임 연동 | Flutter 3.35+ 필요 |
| **mcp_flutter** | 스크린샷/에러 분석 | macOS, iOS 지원 |
| **Marionette MCP** | UI 자동 테스트 | 스모크 테스트 자동화 |
| **flutter-claude-code plugins** | 19개 전문 에이전트 | UI, 테스트, 배포 등 |
| **Git + Checkpoints** | 버전 관리 & 안전망 | 필수 |

---

## 8. 대각님 워크플로우에 적용 시 권장사항

현재 보유한 Clean Architecture + Riverpod 전문성과 WalletConnect 경험을 고려하면:

1. **CLAUDE.md에 아키텍처 규칙을 명시**하여 Claude가 Clean Architecture를 자동 준수하도록 설정
2. **WalletConnect v2 연동 패턴을 Skills로 등록**하여 재사용 가능한 지식 자산화
3. **MCP Flutter 연동**으로 실행 중인 앱을 Claude가 직접 검사하는 환경 구축
4. **Sub-Agent 패턴**으로 UI/로직/테스트를 병렬 진행하여 1인 개발 생산성 극대화
5. **Hooks로 dart analyze와 flutter test를 자동화**하여 코드 품질 자동 유지

이 워크플로우를 MindLog 같은 개인 프로젝트에 먼저 적용하고 포트폴리오에 AI-Assisted Development 사례로 포함하면, 차별화된 경쟁력이 될 수 있다.

---

*출처: CodeWithAndrea, Flutter 공식 블로그, Medium 개발자 사례, GitHub 오픈소스 프로젝트 등*