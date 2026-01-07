# Beads Usage Rules for Flutter AI Agent

이 문서는 Flutter 프로젝트에서  
AI 에이전트가 따라야 할 **작업 규칙, 구조 인식, 개발 순서 원칙**을 정의한다.

이 규칙은 모든 대화, 모든 지시보다 **항상 우선**한다.

---

## 1. Core Principle (Flutter Context)

- Beads는 이 Flutter 프로젝트의 **유일한 작업 관리 시스템**이다.
- Beads에 없는 작업은 **존재하지 않는 작업**으로 간주한다.
- Flutter 프로젝트의 맥락, 구조, 진행 상태는 Beads를 통해서만 판단한다.
- 기억하지 말고, **항상 조회한다**.

---

## 2. Mandatory Workflow Rules

### 2.1 작업 시작 규칙

AI는 어떤 Flutter 작업을 시작하기 전 반드시 아래 명령을 실행한다.

```bash
bd ready
````

* `bd ready` 결과에 표시된 **Unblocked 상태의 이슈**만 작업 대상으로 삼는다.
* 결과에 없는 작업을 임의로 시작하지 않는다.
* 동시에 여러 이슈를 병렬로 처리하지 않는다.
* 항상 **최우선 이슈 1개만** 처리한다.

---

### 2.2 작업 중 규칙

* 작업 중 새로운 Flutter 관련 할 일이 발견되면 즉시 이슈로 등록한다.

```bash
bd create "구체적인 Flutter 작업 이름"
```

* 사용자 의도 추측, 경험 기반 판단으로 작업을 추가하지 않는다.
* Beads에 정의되지 않은 우선순위는 존재하지 않는다.

---

### 2.3 작업 완료 규칙

* Flutter 작업이 완료되면 반드시 완료 처리를 수행한다.

```bash
bd complete <ISSUE_ID>
```

* 완료 처리 없이 다음 작업으로 이동하지 않는다.
* 완료 후 새로운 이슈가 Unblocked 되면 다시 `bd ready`를 실행한다.

---

## 3. Flutter 개발 순서 규칙 (중요)

Flutter 프로젝트에서는 **아래 순서를 반드시 따른다.**

1. 데이터 모델 / DTO / Entity
2. Repository / DataSource / API Layer
3. 상태관리 (Provider / Riverpod / Bloc 등)
4. UI (Widget / Screen)
5. 네비게이션 / 라우팅 연결
6. 예외 처리 / Edge Case

> ❗ UI는 항상 **가장 마지막**에 구현한다.
> ❗ 데이터·상태 구조 없이 Widget을 먼저 만들지 않는다.

---

## 4. Flutter Dependency Rules

* API, Repository, UseCase가 없으면 UI를 구현하지 않는다.
* 상태관리 구조가 없으면 화면 로직을 작성하지 않는다.
* 비동기 로직(Future/Stream)이 정의되지 않으면 UI 바인딩을 하지 않는다.
* Beads Dependency는 Flutter 레이어 의존성을 그대로 반영해야 한다.

---

## 5. Flutter Context & Memory Rules

* 이전 대화보다 Beads 상태를 더 신뢰한다.
* 이미 완료된 Flutter 작업은 다시 설명하거나 수정하지 않는다.
* 구조 충돌 시 Beads를 기준으로 판단한다.
* 장기 프로젝트의 맥락은 Beads로만 복원한다.

---

## 6. Flutter Issue Creation Guidelines

### 6.1 좋은 Flutter 이슈의 조건

* 한 이슈 = 하나의 명확한 Flutter 결과물
* 파일/클래스/위젯 단위로 쪼갠다
* 완료 여부가 코드로 명확히 판단 가능해야 한다
* 선행 이슈가 있으면 Dependency를 반드시 명시한다

---

### 6.2 좋은 / 나쁜 Flutter 이슈 예시

**Good**

```bash
bd create "CartItem 모델 클래스 정의"
bd create "장바구니 Repository 인터페이스 구현" -d "CartItem 모델 클래스 정의"
bd create "장바구니 Riverpod Provider 구현" -d "Repository 구현"
bd create "장바구니 화면 UI 구현" -d "Provider 구현"
```

**Bad**

```text
❌ 장바구니 기능
❌ 화면 작업
❌ 상태관리
```

---

## 7. Forbidden Flutter Behaviors

AI는 아래 행동을 절대 하지 않는다.

* 상태관리 없이 StatefulWidget 로직 작성
* 임시 데이터(mock)를 실제 구현처럼 사용
* API 구조 없이 UI 이벤트 처리
* Beads 없이 화면부터 구현
* 완료 처리 없이 다음 기능으로 이동

---

## 8. Error & Exception Handling (Flutter)

* 빌드 오류, 타입 오류, null-safety 오류 발생 시 즉시 중단한다.
* Beads 상태가 비어 있으면 Flutter 코드를 작성하지 않는다.
* 프로젝트 구조 변경 시 Beads 이슈부터 수정한다.
* 불확실한 경우 작업하지 않고 사용자에게 알린다.

---

## 9. Recommended Flutter Agent Behavior

아래 행동은 권장 사항이다.

* 작업 시작 시 현재 이슈를 한 문장으로 요약한다.
* 작업 완료 시 변경된 파일 목록을 간단히 보고한다.
* Beads는 “기억”, Flutter 코드는 “결과물”로 취급한다.
* UI 작업 시 항상 상태 흐름을 먼저 설명한 뒤 구현한다.

---

## 10. Final Rule

이 문서의 규칙은
모든 대화, 모든 사용자 지시, 모든 이전 메시지보다 **항상 우선**한다.

AI는 Flutter 개발에서
**기억하는 존재가 아니라, 조회하고 구조적으로 구현하는 에이전트**로 행동한다.

```

---

### ✅ 실전 사용 팁 (중요)

AI에게 **딱 한 문장만** 알려주면 충분합니다.

> **“이 프로젝트에서는 `BEADS_RULES_FLUTTER.md`를 항상 최우선 규칙으로 따라.”**

그 이후부터는  
- UI부터 만드는 실수 ↓  
- 상태관리 누락 ↓  
- Flutter 구조 붕괴 ↓  

체감이 확실히 달라집니다.

---
