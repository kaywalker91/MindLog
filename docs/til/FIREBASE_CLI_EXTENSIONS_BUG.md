# TIL: Firebase CLI Extensions API 403 버그 및 패치

**날짜**: 2026-02-27
**카테고리**: Firebase, CLI, Deployment
**난이도**: 중급~고급
**소요 시간**: 10분

---

## 문제

Firebase CLI 14.x (및 v13 포함)로 `firebase deploy --only functions`를 실행하면
`--only functions`임에도 Extensions API를 항상 호출한다.

```
Error: HTTP Error: 403, The caller does not have permission
GET https://firebaseextensions.googleapis.com/v1beta/projects/{id}/instances
```

### 증상

- `firebase deploy --only functions` 실행 시 403 에러로 배포 실패
- `--except extensions` 플래그 추가해도 동일하게 실패
- `firebase.json`에 `"extensions": {}` 추가해도 우회 불가
- IAM `testIamPermissions` 체크는 200 OK (권한 있음으로 통과)하지만
  실제 GET 요청에서 403 반환 — IAM 권한과 별개의 서비스 레벨 제한

### 근본 원인

Firebase CLI의 Extensions planner(`lib/deploy/extensions/planner.js`)가
`haveDynamic()` 및 `have()` 함수에서 Extensions 배포 여부와 무관하게
항상 `listInstances()`를 호출한다.

이 API(`firebaseextensions.googleapis.com/v1beta`)는 Firebase 플랜 티어 또는
조직 정책에 의해 특정 프로젝트에서 제한될 수 있으며, IAM 권한과는 독립적으로 동작한다.

---

## 시도한 것들 (모두 실패)

| 방법 | 결과 |
|------|------|
| `firebase deploy --only functions` | 403 실패 |
| `firebase deploy --only functions --except extensions` | 403 실패 |
| `firebase.json`에 `"extensions": {}` 추가 | 403 실패 |
| Firebase 콘솔에서 Extensions API 권한 확인 | IAM은 정상, 서비스 레벨 제한 |

---

## 작동하는 해결책: planner.js 직접 패치

### 패치 위치

```
/opt/homebrew/lib/node_modules/firebase-tools/lib/deploy/extensions/planner.js
```

### 패치 내용

`haveDynamic()` 함수와 `have()` 함수가 `listInstances()`를 호출하지 않고
빈 배열을 즉시 반환하도록 변경한다.

**변경 전:**
```javascript
async function haveDynamic() {
  const instances = await listInstances(projectId);
  // ... 처리 로직
}

async function have(projectId) {
  const instances = await listInstances(projectId);
  // ... 처리 로직
}
```

**변경 후:**
```javascript
async function haveDynamic() {
  return [];
}

async function have(projectId) {
  return [];
}
```

### 패치 적용 방법

1. 파일 열기:
   ```bash
   nano /opt/homebrew/lib/node_modules/firebase-tools/lib/deploy/extensions/planner.js
   ```

2. `haveDynamic` 함수 찾기 (`Ctrl+W` 검색)

3. 함수 본문을 `return [];`로 교체

4. `have` 함수도 동일하게 교체

5. 저장 후 재배포:
   ```bash
   firebase deploy --only functions
   ```

---

## 주의사항

### 임시 패치임

이 패치는 `brew upgrade firebase-tools` 또는 `npm install -g firebase-tools` 실행 시
**자동으로 원복**된다. 업그레이드 후 재적용이 필요하다.

### 사이드 이펙트

- Extensions 배포 기능이 비활성화된다
- `firebase deploy` (전체 배포)는 Extensions를 건너뛴다
- Functions만 배포하는 용도에서는 문제 없음

### Extensions가 실제로 필요한 경우

Extensions를 배포해야 한다면 이 패치 대신 다음을 시도:
- Firebase 지원팀에 `firebaseextensions.googleapis.com` API 접근 문의
- 프로젝트 플랜 확인 (Blaze 플랜 필요 가능성)

---

## 재적용 체크리스트

`firebase-tools` 업그레이드 후 배포 실패 시:

```bash
# 1. planner.js 위치 확인
ls /opt/homebrew/lib/node_modules/firebase-tools/lib/deploy/extensions/planner.js

# 2. 현재 firebase-tools 버전 확인
firebase --version

# 3. haveDynamic / have 함수 상태 확인
grep -n "haveDynamic\|async function have" \
  /opt/homebrew/lib/node_modules/firebase-tools/lib/deploy/extensions/planner.js

# 4. 패치 적용 (위 패치 내용 참고)

# 5. 배포 확인
firebase deploy --only functions
```

---

## 핵심 교훈

1. **IAM 통과 != API 접근 가능**: `testIamPermissions`가 200을 반환해도 실제 API 호출은 403일 수 있다. Firebase 서비스별 접근 제어는 IAM과 독립적으로 존재한다.

2. **CLI 플래그가 항상 작동하지는 않는다**: `--only`, `--except` 플래그가 내부 코드의 모든 API 호출을 막지 않을 수 있다. CLI 소스를 직접 확인하는 것이 필요할 때가 있다.

3. **node_modules 패치는 최후 수단**: 패키지 업그레이드 시 원복되므로, 패치 위치와 방법을 이 문서처럼 기록해 두어야 한다.
