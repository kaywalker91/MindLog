# version-bump

pubspec.yaml의 버전을 자동으로 증가시키는 스킬

## 목표
- 일관된 Semantic Versioning 유지
- 버전 관리 자동화
- 빌드 번호 자동 증가

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "버전 올려줘", "version bump" 요청
- `/version-bump [type]` 명령어
- 릴리스 준비 시

## 버전 형식
```
version: {major}.{minor}.{patch}+{build}
예: 1.4.8+14
```

| 구성요소 | 설명 | 증가 시점 |
|---------|------|----------|
| major | 주요 버전 | 호환성 깨지는 변경 |
| minor | 부 버전 | 새 기능 추가 |
| patch | 패치 버전 | 버그 수정 |
| build | 빌드 번호 | 모든 빌드 시 자동 증가 |

## 프로세스

### Step 1: 현재 버전 확인
```bash
# pubspec.yaml에서 현재 버전 읽기
version: 1.4.8+14
```

### Step 2: 버전 타입 결정
| 타입 | 명령어 | 결과 |
|------|--------|------|
| major | `/version-bump major` | 1.4.8 → 2.0.0 |
| minor | `/version-bump minor` | 1.4.8 → 1.5.0 |
| patch | `/version-bump patch` (기본) | 1.4.8 → 1.4.9 |
| build | `/version-bump build` | +14 → +15 |

### Step 3: pubspec.yaml 업데이트
파일: `pubspec.yaml` (line 5)

```yaml
# Before
version: 1.4.8+14

# After (patch bump 예시)
version: 1.4.9+15
```

### Step 4: Git 태그 생성 (선택)
```bash
git tag v1.4.9
git push origin v1.4.9
```

## 출력 형식

```
🏷️ 버전 업데이트 완료

이전: 1.4.8+14
이후: 1.4.9+15
타입: patch

📝 변경 파일:
   └─ pubspec.yaml (line 5)

🔧 다음 단계:
   └─ /changelog 실행하여 CHANGELOG 업데이트
   └─ /release-notes 실행하여 릴리스 노트 생성
```

## 사용 예시

```
> "/version-bump patch"

AI 응답:
1. 현재 버전 확인: 1.4.8+14
2. patch 버전 증가: 1.4.8 → 1.4.9
3. 빌드 번호 증가: 14 → 15
4. pubspec.yaml 업데이트 완료
```

## 주의사항
- 빌드 번호(+N)는 항상 증가해야 함 (Play Store 요구사항)
- major/minor 변경 시 patch는 0으로 리셋
- Git 태그는 main 브랜치에서만 생성 권장
