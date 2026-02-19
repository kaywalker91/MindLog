# cd-diagnose

CD 워크플로우 실패 시 근본 원인을 자동 분석하고 수정 방안을 제시하는 스킬

## 목표
- CD 워크플로우 실패 원인 신속 파악
- 스택트레이스 기반 근본 원인 분석
- 수정 방안 및 검증 체크리스트 제공

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "CD 실패", "deploy 오류", "fastlane 오류" 요청
- `/cd-diagnose [run_id]` 명령어
- GitHub Actions 실패 알림 수신

## 프로세스

### Step 1: 워크플로우 상태 확인
```bash
# 최근 실패 run 확인
gh run list --workflow=cd.yml --status=failure --limit=5

# 특정 run 상세 조회
gh run view {run_id} --log-failed
```

### Step 2: 오류 로그 분석
```bash
# 전체 로그 다운로드
gh run view {run_id} --log > /tmp/cd-run-{run_id}.log

# 오류 패턴 검색
grep -E "(Error|FAIL|Invalid|error:)" /tmp/cd-run-{run_id}.log
```

### Step 3: 스택트레이스 추적

| 오류 유형 | 검색 패턴 | 일반적 원인 |
|----------|----------|-------------|
| Fastlane | `supply/lib/supply` | Play Store API 오류 |
| 빌드 | `FAILURE:` | Gradle/Flutter 빌드 실패 |
| 서명 | `signing` | keystore/key.properties 문제 |
| 인증 | `authentication` | Service Account JSON 오류 |

### Step 4: 근본 원인 분류

```markdown
## 진단 결과

### 오류 요약
- **Run ID**: {run_id}
- **실패 단계**: {step_name}
- **오류 메시지**: {error_message}

### 근본 원인
{원인 분석}

### 스택트레이스
```
{relevant_stack_trace}
```

### 수정 방안
1. {수정 단계 1}
2. {수정 단계 2}
3. {수정 단계 3}

### 검증 체크리스트
- [ ] 로컬 테스트 통과
- [ ] CD 워크플로우 재실행
- [ ] 오류 미발생 확인
```

## 일반적 오류 패턴

### Fastlane Play Store 오류
| 오류 | 원인 | 해결 |
|------|------|------|
| `Invalid request` | 언어 listing 미등록 | `skip_upload_*: true` 설정 |
| `Authentication failed` | Service Account 권한 부족 | Play Console 권한 확인 |
| `Version code already used` | 버전 충돌 | pubspec.yaml 버전 증가 |

### 빌드 오류
| 오류 | 원인 | 해결 |
|------|------|------|
| `Keystore not found` | 경로 오류 | key.properties 경로 확인 |
| `Could not resolve dependencies` | 캐시 문제 | `flutter clean && flutter pub get` |
| `Execution failed for task :app:*` | Gradle 설정 | build.gradle 검토 |

## 출력 형식

```
🔍 CD 진단 완료

📋 Run #21467121965
├── 상태: failure
├── 실패 단계: Deploy with Fastlane
└── 오류: ko - Invalid request

🔬 근본 원인
└── skip_upload_changelogs 미설정 + ko 언어 미등록

🛠 수정 방안
├── 1. Fastfile에 skip_upload_changelogs: true 추가
├── 2. 3개 deploy lane 모두 수정
└── 3. 커밋 후 재배포

✅ 검증 체크리스트
├── [ ] Fastfile 수정 완료
├── [ ] CD 워크플로우 재실행
└── [ ] "ko - Invalid request" 오류 미발생
```

## 사용 예시

```
> "/cd-diagnose 21467121965"

AI 응답:
1. Run #21467121965 로그 분석 중...
2. 실패 단계: Deploy with Fastlane
3. 오류 메시지: "ko - Invalid request"
4. 스택트레이스 분석:
   - supply/lib/supply/uploader.rb:530
   - get_edit_listing('ko') 호출 실패
5. 근본 원인: Play Console에 ko 언어 미등록
6. 수정 방안:
   - skip_upload_changelogs: true 추가
7. 예상 수정 파일: android/fastlane/Fastfile
```

## 연관 스킬
- `/fastlane-audit` - Fastlane 설정 사전 감사
- `/version-bump` - 버전 충돌 해결

## 주의사항
- `gh` CLI가 설치되어 있어야 함
- GitHub 인증 필요 (`gh auth login`)
- 민감한 정보(시크릿)는 로그에 마스킹됨

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | ci-cd |
| Dependencies | gh CLI |
| Created | 2025-01-29 |
| Updated | 2025-01-29 |
