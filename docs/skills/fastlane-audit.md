# fastlane-audit

Fastlane 설정을 사전 검증하여 배포 오류를 예방하는 스킬

## 목표
- Fastlane 설정 오류 사전 탐지
- Play Store API 호환성 검증
- 배포 전 체크리스트 자동화

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "Fastlane 검증", "배포 설정 확인" 요청
- `/fastlane-audit` 명령어
- 첫 배포 전 사전 검증
- Fastfile 수정 후

## 참조 파일
- `android/fastlane/Fastfile`
- `android/fastlane/Appfile`
- `android/fastlane/metadata/`

## 프로세스

### Step 1: Fastfile 구문 검증
```bash
cd android && bundle exec fastlane lanes
```

### Step 2: 메타데이터 구조 검증
```
metadata/
├── android/
│   ├── en-US/           # 기본 언어 (필수)
│   │   ├── title.txt
│   │   ├── short_description.txt
│   │   ├── full_description.txt
│   │   └── changelogs/
│   └── ko/              # 추가 언어 (선택)
│       └── ...
```

### Step 3: skip 파라미터 일관성 검증

| 파라미터 | 권장값 | 이유 |
|----------|--------|------|
| `skip_upload_metadata` | `true` | Play Console 직접 관리 |
| `skip_upload_images` | `true` | 스크린샷 별도 관리 |
| `skip_upload_screenshots` | `true` | 스크린샷 별도 관리 |
| `skip_upload_changelogs` | `true` | 언어 listing 오류 방지 |

### Step 4: Play Console 동기화 상태 확인

```bash
# Play Console에서 현재 상태 가져오기
cd android && bundle exec fastlane run supply \
  track:internal \
  skip_upload_aab:true \
  skip_upload_apk:true
```

## 검증 체크리스트

### 필수 항목
- [ ] `Appfile`에 `package_name` 설정
- [ ] `Appfile`에 `json_key_file` 경로 설정
- [ ] Service Account JSON 파일 존재
- [ ] `en-US` 기본 언어 메타데이터 존재

### 권장 항목
- [ ] 모든 deploy lane에 `skip_upload_changelogs: true`
- [ ] 버전 코드 자동 증가 설정
- [ ] Play Console에 등록된 언어만 로컬에 존재

### 안티패턴 탐지
- [ ] `continue-on-error: true` 사용 여부 (cd.yml)
- [ ] 하드코딩된 경로 존재 여부
- [ ] 중복된 upload_to_play_store 설정

## 출력 형식

```
🔍 Fastlane Audit Report

📋 파일 검증
├── ✅ Fastfile 구문 정상
├── ✅ Appfile 설정 완료
└── ✅ Service Account JSON 존재

🌐 메타데이터 검증
├── ✅ en-US (기본 언어)
├── ⚠️ ko (Play Console 미등록 가능성)
└── 총 2개 언어

🔧 Lane 설정 검증
├── deploy_internal
│   ├── ✅ skip_upload_metadata: true
│   ├── ✅ skip_upload_images: true
│   ├── ✅ skip_upload_screenshots: true
│   └── ✅ skip_upload_changelogs: true
├── deploy_beta: ✅ 동일
└── deploy_production: ✅ 동일

⚠️ 경고
├── ko 언어가 Play Console에 등록되어 있는지 확인 필요
└── 등록 안 됨 → skip_upload_changelogs: true 필수

✅ 결론: 배포 준비 완료
```

## 사용 예시

```
> "/fastlane-audit"

AI 응답:
1. Fastfile 구문 검증... ✅
2. Appfile 설정 확인... ✅
3. 메타데이터 구조 검증...
   - en-US: ✅
   - ko: ⚠️ (Play Console 등록 확인 필요)
4. Lane 설정 검증...
   - deploy_internal: ✅
   - deploy_beta: ✅
   - deploy_production: ✅
5. 안티패턴 탐지...
   - continue-on-error: 미사용 ✅

📊 결론: 배포 가능 (ko 언어 주의)
```

## 주요 오류 패턴

### 언어 관련
| 상태 | 결과 | 해결 |
|------|------|------|
| 로컬 O + Console O | ✅ 정상 | - |
| 로컬 O + Console X | ❌ Invalid request | skip_upload_* 설정 |
| 로컬 X + Console O | ✅ 정상 | - |

### 인증 관련
| 오류 | 원인 | 해결 |
|------|------|------|
| `Unable to parse JSON` | JSON 형식 오류 | Service Account JSON 재생성 |
| `Insufficient permissions` | 권한 부족 | Play Console에서 권한 추가 |
| `App not found` | 패키지명 불일치 | Appfile package_name 확인 |

## 연관 스킬
- `/cd-diagnose` - CD 워크플로우 오류 진단
- `/version-bump` - 버전 관리

## 주의사항
- 첫 배포 전에는 반드시 실행
- Play Console 언어 설정은 수동 확인 필요
- Service Account 권한: "Release Manager" 이상

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | ci-cd |
| Dependencies | Fastlane, bundler |
| Created | 2025-01-29 |
| Updated | 2025-01-29 |
