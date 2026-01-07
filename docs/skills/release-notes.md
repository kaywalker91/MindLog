# release-notes

Git 커밋 히스토리 기반으로 릴리스 노트를 자동 생성하는 스킬

## 목표
- 릴리스 문서화 자동화
- 사용자 친화적 릴리스 노트 생성
- GitHub Releases 연동

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "릴리스 노트 생성", "release notes" 요청
- `/release-notes` 명령어
- 배포 직전

## 프로세스

### Step 1: 버전 정보 수집
```bash
# 현재 버전
grep "version:" pubspec.yaml

# 마지막 태그
git describe --tags --abbrev=0
```

### Step 2: 커밋 히스토리 분석
```bash
# 마지막 릴리스 이후 커밋
git log v1.4.8..HEAD --pretty=format:"%s"
```

### Step 3: 릴리스 노트 생성
파일: `RELEASE_NOTES.md` 또는 GitHub Release

```markdown
# MindLog v1.4.9

> AI 기반 감정 케어 다이어리

## 새로운 기능

- 개별 일기 삭제 기능 추가
  - 스와이프 제스처로 간편하게 삭제
  - 삭제 확인 다이얼로그 제공

## 개선사항

- AI 분석 결과 UI 전면 개편
  - 더 직관적인 감정 시각화
  - 행동 지침 카드 디자인 개선

## 버그 수정

- CI 빌드 오류 수정

## 기술적 변경

- Firebase 통합 완료
- Claude Skills 도입

---

**설치 방법**
- Google Play Store에서 업데이트
- 또는 APK 직접 다운로드

**문의**: [이슈 등록](https://github.com/user/mindlog/issues)
```

### Step 4: GitHub Release 생성 (선택)
```bash
gh release create v1.4.9 \
  --title "MindLog v1.4.9" \
  --notes-file RELEASE_NOTES.md
```

## 출력 형식

```
📄 릴리스 노트 생성 완료

버전: v1.4.9
커밋 수: 7개

내용 요약:
├── 새로운 기능: 2개
├── 개선사항: 1개
├── 버그 수정: 2개
└── 기술적 변경: 2개

📝 생성 파일:
   └─ RELEASE_NOTES.md

🔧 다음 단계:
   └─ gh release create v1.4.9 --notes-file RELEASE_NOTES.md
```

## 릴리스 노트 스타일

### 사용자용 (User-facing)
```markdown
## 새로운 기능
- 일기를 스와이프하여 삭제할 수 있어요
- AI 분석 결과가 더 예쁘게 바뀌었어요
```

### 개발자용 (Technical)
```markdown
## Technical Changes
- feat: add swipe-to-delete gesture for diary entries
- refactor: revamp analysis result UI with new design system
```

## 참조 파일
- 버전: `pubspec.yaml`
- CI/CD: `.github/workflows/cd.yml`
- 이전 릴리스: `git tag -l`

## 사용 예시

```
> "/release-notes"

AI 응답:
1. 현재 버전: 1.4.9
2. 마지막 태그: v1.4.8
3. 새 커밋: 7개 분석
4. 릴리스 노트 생성:
   - 사용자 친화적 설명 추가
   - 카테고리별 정리
5. RELEASE_NOTES.md 저장 완료
```

## 연관 스킬
- `/version-bump` - 버전 업데이트 먼저 실행
- `/changelog` - CHANGELOG.md 동시 업데이트 권장
