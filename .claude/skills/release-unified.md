# release-unified

MindLog 전체 릴리스 파이프라인 통합 스킬
version-bump → CHANGELOG → update.json (2종) → GitHub Pages → RELEASE_NOTES → commit → push

## 목표
- 릴리스 준비 전 단계를 단일 명령어로 통합
- 단계 간 일관성 보장 (동일 버전 번호 사용)
- 3가지 문서 관점(사용자 / 채용담당자 / 개발자)을 각각 다른 톤으로 작성
- 선택적 Git 태그 & GitHub Release 생성

## 트리거 조건
- "릴리스 준비해줘", "release 해줘" 요청
- `/release-unified [type]` 명령어
- 배포 직전 한 번에 처리할 때

## 사용법

```
/release-unified [type] [--no-tag] [--no-push] [--no-gh-release]
```

| 인수 | 설명 | 기본값 |
|------|------|--------|
| `type` | patch \| minor \| major | patch |
| `--no-tag` | Git 태그 생성 생략 | 태그 생성 O |
| `--no-push` | git push 생략 | push 실행 O |
| `--no-gh-release` | GitHub Release 생성 생략 | 확인 후 실행 |

## 문서 작성 관점 (3-tier)

릴리스마다 업데이트하는 파일들은 **독자에 따라 톤이 달라야 한다**:

| 파일 | 독자 | 톤 | 핵심 |
|------|------|----|------|
| `docs/update.json` | 앱 사용자 | "~해요" 친근체, 기술 용어 풀어쓰기 | 사용자가 체감하는 변화 중심 |
| `docs/index.html` | 채용담당자 | 기술 결정의 "왜" 설명, 성과 수치 포함 | 설계 역량·문제 해결 능력 어필 |
| `CHANGELOG.md` | 개발자 | 구체 클래스/함수명, 원인-결과 명시 | 커밋 단위 변경사항 상세 기록 |

---

## 실행 순서 (8단계)

### Step 1: 현재 상태 확인
```bash
grep "^version:" pubspec.yaml
git describe --tags --abbrev=0 2>/dev/null || echo "(태그 없음)"
git status --short
git log origin/main..HEAD --oneline   # 미푸시 커밋 목록
```

**미스테이징 변경사항 처리 (개선된 안전 장치)**:
- 미스테이징 파일이 있으면 🛑 중단하지 않고 목록을 표시한다
- "릴리스 커밋에 함께 포함할까요? [Y/n]" 확인 후 진행
- Y → Step 6 스테이징 시 함께 포함 / N → 현재 커밋된 변경사항만 대상

미푸시 커밋이 없고 미스테이징 변경도 없으면 릴리스할 내용 없음 → 중단.

### Step 2: 버전 증가
```
현재: 1.4.47+55  →  patch  →  1.4.48+56
```

`pubspec.yaml` 업데이트:
```yaml
# Before
version: 1.4.47+55
# After
version: 1.4.48+56
```

규칙:
- `patch`: patch +1, build +1
- `minor`: minor +1, patch → 0, build +1
- `major`: major +1, minor → 0, patch → 0, build +1
- build 번호는 **항상** +1 (Play Store 제출 후 감소 불가)

### Step 3: CHANGELOG.md 업데이트 (개발자 관점)

변경사항 수집:
```bash
# 마지막 태그 이후 전체 커밋 (미푸시 + 미스테이징 포함)
git log {prev_tag}..HEAD --pretty=format:"%s" --no-merges
git diff HEAD --name-only   # 미스테이징 파일 목록
```

Conventional Commits → Keep a Changelog 카테고리 매핑:
| 접두사 | 카테고리 |
|--------|----------|
| `feat:` | Added |
| `fix:` | Fixed |
| `refactor:`, `perf:`, `style:` | Changed |
| `docs:` | Changed |
| `security:` | Security |
| `chore:`, `ci:`, `test:` | Testing / Chore (선택적 포함) |

**작성 톤**: 구체 파일명·클래스·함수명 명시, 변경 전후 동작 비교, 근본 원인 포함.

`CHANGELOG.md` 상단에 새 버전 섹션 삽입:
```markdown
## [1.4.48] - 2026-02-27

### Added
- **`FooClass`** (`lib/path/foo.dart`): 상세 설명 — 변경 전→후 동작 비교

### Fixed
- **버그명** (`파일명:라인`): 원인 및 해결 방법

### Changed
- **리팩토링 대상** (`파일명`): 변경 이유 및 영향 범위

### Testing
- **테스트 추가** (`test/path/`): 검증 항목 및 패턴
```

### Step 4: docs/update.json 업데이트 (사용자 출시노트)

**작성 톤**: 기술 용어 없이 사용자가 체감하는 변화 중심. "~해요" 친근체. 긍정적 표현.

```json
{
  "latestVersion": "1.4.48",
  "minSupportedVersion": "1.3.0",
  "forceUpdate": false,
  "androidUrl": "https://play.google.com/store/apps/details?id=com.mindlog.mindlog",
  "iosUrl": null,
  "changelog": {
    "1.4.48": [
      "알림이 더욱 안정적으로 전달돼요! ...",
      "앱 디자인이 더 예뻐졌어요! ...",
      "..."
    ],
    "1.4.47": [ ... (기존 항목 유지) ]
  },
  "updatedAt": "2026-02-27T12:00:00+09:00"
}
```

### Step 5: assets/update.json 업데이트 (인앱 업데이트 팝업)

앱 내 업데이트 안내 팝업에 사용하는 별도 포맷. features / improvements / bugFixes 3분류.

```json
{
  "latestVersion": "1.4.48",
  "minimumVersion": "1.4.0",
  "releaseNotes": {
    "ko": {
      "title": "v1.4.48 업데이트 안내",
      "features": ["신규 기능 설명"],
      "improvements": ["개선사항 설명"],
      "bugFixes": ["버그 수정 설명"]
    },
    "en": {
      "title": "v1.4.48 Update",
      "features": ["..."],
      "improvements": ["..."],
      "bugFixes": ["..."]
    }
  },
  "storeUrl": "https://play.google.com/store/apps/details?id=com.mindlog.mindlog"
}
```

### Step 6: docs/index.html GitHub Pages 업데이트 (채용담당자 관점)

`#updates` 섹션의 `<p class="section-subtitle">` 와 `.updates-grid` 카드들을 교체.

**작성 톤**: 기술 결정의 "왜"를 설명, 구체적 수치(테스트 수, 성능 개선율 등) 포함, 포트폴리오 어필.

카드 1개 예시:
```html
<div class="update-card">
    <span class="update-tag">Reliability</span>
    <h3>FCM 멱등성 Pre-lock 패턴 (v1.4.48)</h3>
    <p>Firebase Functions retry + Firestore 부분 실패로 인한 3회 중복 발송을
    Firestore <code>create()</code> 원자적 잠금으로 해결했습니다.
    기존 check-send-mark 패턴의 구조적 결함(race condition)을 분석하고
    acquireSendLock / completeSendLock / releaseSendLockOnFailure
    3-함수 패턴으로 교체했습니다. fail-open → fail-safe 전환으로 장애 시
    안전성을 우선했습니다.</p>
</div>
```

최근 5개 카드 유지 (오래된 카드 제거), section-subtitle 버전 번호 업데이트.

### Step 7: RELEASE_NOTES.md 생성

```markdown
# MindLog v{version}

> AI 기반 감정 케어 다이어리

## 새로운 기능 ✨
- {feat 커밋 → 사용자 언어로 변환}

## 개선사항 🔧
- {refactor/perf 커밋}

## 버그 수정 🐛
- {fix 커밋}

---
**업데이트 방법**: Google Play Store에서 자동 업데이트
```

### Step 8: Git 커밋 & 푸시

```bash
# 모든 릴리스 관련 파일 스테이징
git add pubspec.yaml CHANGELOG.md RELEASE_NOTES.md \
        docs/update.json assets/update.json docs/index.html

# Step 1에서 Y 선택한 미스테이징 파일 함께 추가
# git add {unstaged-files...}

# 릴리스 커밋
git commit -m "chore(release): bump version to {version}+{build}"

# Git 태그 (--no-tag 아닌 경우)
git tag v{version}

# Push (--no-push 아닌 경우)
git push && git push origin v{version}
```

---

## 출력 형식

```
🚀 릴리스 준비 완료

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 버전  1.4.47+55  →  1.4.48+56
 타입  patch
 날짜  2026-02-27
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Step 1/8 현재 상태 확인 (미스테이징 3개 → 함께 포함)
✅ Step 2/8 pubspec.yaml 버전 업데이트
✅ Step 3/8 CHANGELOG.md 업데이트
   ├── Added   : 3개
   ├── Fixed   : 2개
   ├── Changed : 2개
   └── Testing : 1개
✅ Step 4/8 docs/update.json 업데이트 (사용자용)
✅ Step 5/8 assets/update.json 업데이트 (인앱 팝업용)
✅ Step 6/8 docs/index.html 업데이트 (채용담당자용)
✅ Step 7/8 RELEASE_NOTES.md 생성
✅ Step 8/8 Git 커밋 + 태그 v1.4.48 + Push

📝 변경 파일:
   ├── pubspec.yaml
   ├── CHANGELOG.md
   ├── RELEASE_NOTES.md
   ├── docs/update.json
   ├── assets/update.json
   └── docs/index.html

🔧 다음 단계 (선택):
   └── GitHub Release: gh release create v1.4.48 --notes-file RELEASE_NOTES.md
```

---

## 중단 조건 (안전 장치)

| 조건 | 동작 |
|------|------|
| 미푸시 커밋 없음 + 미스테이징 변경 없음 | 🛑 릴리스할 내용 없음, 중단 |
| 미스테이징 변경사항 존재 | ⚠️ 목록 표시 → 포함 여부 확인 후 진행 |
| pubspec.yaml 버전 파싱 실패 | 🛑 중단, 수동 확인 요청 |
| CHANGELOG.md 없음 | ⚠️ 신규 파일 생성 후 계속 |
| git 태그 충돌 (이미 존재) | ⚠️ 태그 건너뛰기, 사용자에게 알림 |
| main 브랜치가 아님 | ⚠️ 경고 출력 후 사용자 확인 요청 |

---

## 사용 예시

```
> "/release-unified patch"

1. 상태 확인: 미스테이징 3개 → 포함 Y
2. 버전 증가: 1.4.47+55 → 1.4.48+56
3. CHANGELOG 업데이트: Added 3개, Fixed 2개
4. docs/update.json: 사용자용 출시노트 작성
5. assets/update.json: 인앱 팝업 ko/en 작성
6. docs/index.html: GitHub Pages 최근 개선 섹션 교체
7. RELEASE_NOTES.md 생성
8. Git 커밋 + 태그 + Push

> "/release-unified minor --no-tag --no-push"

1. 버전 증가: 1.4.47+55 → 1.5.0+56
2. 전체 문서 업데이트
3. Git 커밋만 생성 (태그·Push 생략)
```

## 연관 스킬
- `/version-bump` — 버전만 올릴 때
- `/changelog` — 체인지로그만 업데이트할 때
- `/release-notes` — RELEASE_NOTES.md만 생성할 때
- `/cd-diagnose` — CI/CD 파이프라인 문제 발생 시
- `/fastlane-audit` — 배포 전 Fastlane 설정 점검

## 주의사항
- build 번호(+N)는 Play Store에 제출한 적 있으면 절대 감소 불가
- `main` 브랜치에서 실행 권장 (다른 브랜치라면 경고)
- `docs/update.json` ≠ `assets/update.json` — 포맷이 다름, 둘 다 업데이트 필수
- `--no-tag` 사용 시 CD 파이프라인이 태그 기반이면 자동 배포 트리거 안 됨
- GitHub Release는 `gh` CLI 필요 (`brew install gh`)

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P0 |
| Category | release |
| Dependencies | version-bump, changelog-update, release-notes |
| Created | 2026-02-27 |
| Updated | 2026-02-27 |
