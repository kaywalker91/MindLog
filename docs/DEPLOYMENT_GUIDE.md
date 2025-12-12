# MindLog 배포 가이드

Android 앱 배포를 위한 Keystore 생성, GitHub Secrets 설정, Google Play Console 등록 가이드입니다.

---

## 목차

1. [Keystore 생성](#1-keystore-생성)
2. [GitHub Secrets 설정](#2-github-secrets-설정)
3. [Google Play Console 설정](#3-google-play-console-설정)
4. [첫 배포 (수동)](#4-첫-배포-수동)
5. [자동 배포 활성화](#5-자동-배포-활성화)
6. [문제 해결](#6-문제-해결)

---

## 1. Keystore 생성

### 1.1 Upload Keystore 생성

터미널에서 `android/app` 디렉토리로 이동 후 실행:

```bash
cd android/app

keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

### 1.2 입력 정보

프롬프트에 다음 정보를 입력합니다:

| 항목 | 예시 값 | 설명 |
|------|--------|------|
| 키스토어 비밀번호 | `MySecurePass123!` | 강력한 비밀번호 (기억 필수) |
| 키 비밀번호 | `MySecurePass123!` | 동일하게 설정 권장 |
| 이름과 성 | `MindLog Developer` | 개발자/회사 이름 |
| 조직 단위 | `Development` | 부서명 |
| 조직 | `MindLog` | 회사/프로젝트 이름 |
| 시/군/구 | `Seoul` | 도시 |
| 시/도 | `Seoul` | 주/도 |
| 국가 코드 | `KR` | 2자리 국가 코드 |

### 1.3 생성 확인

```bash
# 키스토어 정보 확인
keytool -list -v -keystore upload-keystore.jks
```

### 1.4 로컬 테스트용 key.properties 생성

```bash
# android/ 디렉토리에 key.properties 생성
cat > ../key.properties << EOF
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
EOF
```

### 1.5 Base64 인코딩 (GitHub Secret용)

```bash
# macOS - 클립보드에 복사
base64 -i upload-keystore.jks | pbcopy

# 또는 파일로 저장
base64 -i upload-keystore.jks > keystore-base64.txt

# Linux
base64 upload-keystore.jks | xclip -selection clipboard
```

> ⚠️ **중요**: `upload-keystore.jks`와 `key.properties`는 절대 Git에 커밋하지 마세요!

---

## 2. GitHub Secrets 설정

### 2.1 GitHub Repository 접속

1. GitHub 저장소 페이지 이동: `https://github.com/kaywalker91/MindLog`
2. **Settings** 탭 클릭
3. 좌측 메뉴에서 **Secrets and variables** → **Actions** 클릭
4. **New repository secret** 버튼 클릭

### 2.2 필수 Secrets 등록

| Secret 이름 | 값 | 획득 방법 |
|------------|-----|----------|
| `KEYSTORE_BASE64` | Base64 인코딩된 keystore 내용 | 1.5단계에서 복사한 값 |
| `KEYSTORE_PASSWORD` | 키스토어 비밀번호 | 1.2단계에서 설정한 값 |
| `KEY_PASSWORD` | 키 비밀번호 | 1.2단계에서 설정한 값 |
| `KEY_ALIAS` | `upload` | 1.1단계에서 설정한 alias |
| `GEMINI_API_KEY` | Gemini API 키 | [Google AI Studio](https://aistudio.google.com/apikey) |
| `GROQ_API_KEY` | Groq API 키 | [Groq Console](https://console.groq.com/keys) |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Google Play API JSON | 3단계에서 생성 |

### 2.3 Secret 등록 방법

각 Secret에 대해:
1. **Name**: 위 표의 Secret 이름 입력
2. **Secret**: 해당 값 붙여넣기
3. **Add secret** 클릭

---

## 3. Google Play Console 설정

### 3.1 개발자 계정 등록

> 이미 개발자 계정이 있다면 3.2로 이동

1. [Google Play Console](https://play.google.com/console) 접속
2. **개발자 계정 만들기** 클릭
3. 등록비 $25 결제 (일회성)
4. 개발자 정보 입력 및 약관 동의

### 3.2 앱 만들기

1. Play Console 대시보드에서 **앱 만들기** 클릭
2. 앱 세부정보 입력:

| 항목 | 값 |
|------|-----|
| 앱 이름 | MindLog |
| 기본 언어 | 한국어 - ko-KR |
| 앱 또는 게임 | 앱 |
| 유료 또는 무료 | 무료 (또는 유료) |

3. 개발자 프로그램 정책 동의 후 **앱 만들기** 클릭

### 3.3 스토어 등록정보 작성

**대시보드** → **스토어 등록정보** 에서 필수 정보 입력:

#### 기본 정보
- **앱 이름**: MindLog - AI 감정 케어 다이어리
- **간단한 설명** (80자 이내):
  ```
  AI가 분석하는 나만의 감정 일기. 매일의 감정을 기록하고 맞춤 케어를 받아보세요.
  ```
- **자세한 설명** (4000자 이내):
  ```
  MindLog는 AI 기반 감정 케어 다이어리입니다.

  ✨ 주요 기능
  • AI 감정 분석: 일기를 작성하면 AI가 감정 상태를 분석합니다
  • 맞춤 공감 메시지: 당신의 감정에 공감하는 따뜻한 메시지를 받아보세요
  • 추천 행동: 현재 감정 상태에 맞는 실천 가능한 행동을 제안합니다
  • 감정 통계: 시간에 따른 감정 변화를 차트로 확인하세요
  • 활동 히트맵: GitHub 스타일의 일기 작성 기록을 확인하세요

  🔒 개인정보 보호
  • 모든 일기는 기기에만 저장됩니다
  • 외부 서버에 일기 내용이 저장되지 않습니다

  💡 이런 분께 추천합니다
  • 매일의 감정을 기록하고 싶은 분
  • 번아웃을 겪고 있는 직장인
  • 자신의 감정 패턴을 파악하고 싶은 분
  • AI의 따뜻한 공감이 필요한 분
  ```

#### 그래픽 에셋 (필수)
| 항목 | 규격 | 설명 |
|------|------|------|
| 앱 아이콘 | 512 x 512 px | PNG, 32비트 |
| 기능 그래픽 | 1024 x 500 px | 스토어 상단 배너 |
| 스크린샷 | 최소 2장 | 휴대전화용 필수 |

> 💡 스크린샷은 실제 앱 화면을 캡처하여 업로드하세요.

### 3.4 앱 콘텐츠 설정

**대시보드** → **앱 콘텐츠** 에서 설정:

1. **개인정보처리방침**: URL 입력 필수
2. **앱 액세스 권한**: 특별한 권한 없음 선택 (또는 해당 권한 설명)
3. **광고**: 광고 포함 여부 선택
4. **콘텐츠 등급**: 설문지 작성 후 등급 받기
5. **타겟층**: 18세 이상 선택 (감정/정신건강 앱)
6. **뉴스 앱**: 아니오
7. **코로나19 앱**: 아니오
8. **데이터 보안**: 데이터 수집/공유 정보 입력

### 3.5 Google Play API 설정 (자동 배포용)

#### 3.5.1 Google Cloud Console에서 서비스 계정 생성

1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. **IAM 및 관리자** → **서비스 계정** 이동
4. **서비스 계정 만들기** 클릭
5. 정보 입력:
   - 이름: `play-store-publisher`
   - 설명: `GitHub Actions Play Store 배포용`
6. **만들기 및 계속** 클릭
7. 역할은 건너뛰기 (Play Console에서 설정)
8. **완료** 클릭

#### 3.5.2 JSON 키 생성

1. 생성된 서비스 계정 클릭
2. **키** 탭 → **키 추가** → **새 키 만들기**
3. **JSON** 선택 → **만들기**
4. JSON 파일이 자동 다운로드됨

#### 3.5.3 Play Console에서 API 액세스 설정

1. [Play Console](https://play.google.com/console) → **설정** → **API 액세스**
2. **Google Cloud 프로젝트 연결** 클릭
3. 3.5.1에서 생성한 프로젝트 선택
4. **서비스 계정** 섹션에서 생성한 계정 찾기
5. **액세스 권한 관리** 클릭
6. 권한 설정:
   - **앱 권한**: MindLog 앱 선택
   - **계정 권한**:
     - ✅ 앱 정보 보기
     - ✅ 출시 관리
     - ✅ 프로덕션으로 앱 출시

#### 3.5.4 GitHub Secret에 JSON 등록

다운로드된 JSON 파일 내용을 `PLAY_STORE_SERVICE_ACCOUNT_JSON` secret에 등록:

```bash
# JSON 파일 내용 복사 (macOS)
cat ~/Downloads/your-service-account-key.json | pbcopy
```

---

## 4. 첫 배포 (수동)

> ⚠️ Google Play 정책상 첫 번째 빌드는 반드시 수동으로 업로드해야 합니다.

### 4.1 Release AAB 빌드

```bash
# 프로젝트 루트에서 실행
flutter build appbundle --release
```

빌드 완료 후 파일 위치:
```
build/app/outputs/bundle/release/app-release.aab
```

### 4.2 Play Console에 AAB 업로드

1. Play Console → **MindLog** 앱 선택
2. **테스트** → **내부 테스트** 이동
3. **새 버전 만들기** 클릭
4. **App Bundle** 섹션에서 `app-release.aab` 업로드
5. **버전 이름** 입력 (예: 1.0.0)
6. **출시 노트** 작성:
   ```
   v1.0.0 첫 번째 릴리스
   - AI 기반 감정 분석
   - 감정 통계 대시보드
   - 활동 히트맵
   ```
7. **저장** → **버전 검토** → **내부 테스트로 출시 시작**

### 4.3 내부 테스터 추가

1. **내부 테스트** → **테스터** 탭
2. **이메일 목록 만들기** 또는 기존 목록 사용
3. 테스터 이메일 추가
4. **변경사항 저장**

### 4.4 테스트 링크 공유

테스터들에게 내부 테스트 참여 링크 공유:
- Play Console에서 **링크 복사** 클릭
- 테스터가 링크를 통해 앱 설치 가능

---

## 5. 자동 배포 활성화

첫 수동 배포가 완료되면 GitHub Actions를 통한 자동 배포가 활성화됩니다.

### 5.1 자동 배포 트리거

```bash
# main 브랜치에 push하면 자동 배포
git push origin main
```

### 5.2 배포 확인

1. GitHub → **Actions** 탭에서 워크플로우 실행 확인
2. **CD - Build & Deploy to Play Store** 워크플로우 클릭
3. 각 단계 성공 여부 확인

### 5.3 배포 트랙 변경

`cd.yml`에서 트랙 변경 가능:

```yaml
# 내부 테스트 (기본값)
track: internal

# 비공개 테스트
track: alpha

# 공개 테스트
track: beta

# 프로덕션 (정식 출시)
track: production
```

---

## 6. 문제 해결

### 6.1 빌드 실패

**증상**: `flutter build appbundle` 실패

**해결**:
```bash
# 캐시 정리
flutter clean
flutter pub get

# 다시 빌드
flutter build appbundle --release
```

### 6.2 서명 오류

**증상**: `Keystore was tampered with, or password was incorrect`

**해결**:
- `key.properties`의 비밀번호 확인
- keystore 파일 경로 확인
- GitHub Secret의 `KEYSTORE_BASE64` 값 재생성

### 6.3 Play Store 업로드 실패

**증상**: `Package name not found`

**해결**:
- Play Console에 앱이 먼저 생성되어 있는지 확인
- 첫 AAB는 수동 업로드 필수
- 패키지 이름 일치 확인: `com.mindlog.mindlog`

### 6.4 API 권한 오류

**증상**: `The caller does not have permission`

**해결**:
1. Play Console → 설정 → API 액세스
2. 서비스 계정 권한 재확인
3. "프로덕션으로 앱 출시" 권한 활성화

### 6.5 버전 코드 충돌

**증상**: `Version code already used`

**해결**:
`pubspec.yaml`에서 버전 증가:
```yaml
version: 1.0.1+3  # +뒤의 숫자가 versionCode
```

---

## 체크리스트

### 배포 전 확인사항

- [ ] Keystore 생성 완료
- [ ] key.properties 로컬 설정 완료
- [ ] GitHub Secrets 7개 모두 등록
- [ ] Google Play Console 앱 생성
- [ ] 스토어 등록정보 작성 완료
- [ ] 앱 콘텐츠 설정 완료
- [ ] 첫 AAB 수동 업로드 완료
- [ ] 내부 테스터 추가 및 테스트 완료

### 정식 출시 전 확인사항

- [ ] 내부 테스트 완료
- [ ] 비공개/공개 테스트 진행 (권장)
- [ ] 모든 스토어 정책 준수 확인
- [ ] 개인정보처리방침 URL 유효
- [ ] cd.yml의 track을 `production`으로 변경

---

## 참고 링크

- [Flutter Android 배포 가이드](https://docs.flutter.dev/deployment/android)
- [Google Play Console 도움말](https://support.google.com/googleplay/android-developer)
- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [upload-google-play Action](https://github.com/r0adkll/upload-google-play)
