# flutter-security-expert

Flutter 앱 보안 분석, 취약점 점검, 보안 강화 전문가 스킬

## 목표
- 앱 보안 취약점 식별
- 민감 데이터 보호
- 보안 베스트 프랙티스 적용

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "보안 점검", "security audit" 요청
- `/security [action]` 명령어
- 민감 데이터 처리 로직 추가 시
- 배포 전 보안 검증 시

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `lib/core/config/env_config.dart` | 환경 변수 관리 |
| `lib/data/datasources/local/sqlite_local_datasource.dart` | 로컬 DB 접근 |
| `lib/data/datasources/remote/*.dart` | API 통신 |
| `android/app/src/main/AndroidManifest.xml` | Android 권한 |
| `ios/Runner/Info.plist` | iOS 권한 |
| `.gitignore` | 버전 관리 제외 파일 |

## 보안 체크리스트

### 1. API 키 관리
```
□ API 키 하드코딩 없음
□ --dart-define으로 빌드 타임 주입
□ .env 파일 .gitignore 포함
□ 프로덕션/개발 키 분리
□ GitHub Secrets 사용 (CI/CD)
```

### 2. 로컬 데이터 보안
```
□ 민감 데이터 암호화 저장
□ SharedPreferences에 민감 정보 미저장
□ SQLite 데이터 보호
□ 캐시 데이터 적절히 관리
□ 앱 삭제 시 데이터 완전 삭제
```

### 3. 네트워크 보안
```
□ HTTPS 강제 사용
□ Certificate Pinning (선택)
□ 요청/응답 로깅에 민감 정보 미포함
□ 타임아웃 설정
□ 재시도 로직 보안 (Rate Limit 준수)
```

### 4. 입력 검증
```
□ 사용자 입력 sanitization
□ SQL Injection 방지
□ XSS 방지 (WebView 사용 시)
□ 길이 제한 적용
□ 형식 검증 (이메일, 전화번호 등)
```

### 5. 인증/권한
```
□ 토큰 안전하게 저장
□ 토큰 만료 처리
□ 권한 최소화 원칙
□ 불필요한 권한 요청 없음
□ 런타임 권한 적절히 요청
```

### 6. 디버깅/로깅
```
□ 프로덕션에서 디버그 로그 비활성화
□ Crashlytics에 민감 정보 미전송
□ 스택 트레이스에 민감 정보 없음
□ assert 문 프로덕션에서 제거됨
□ debugPrint는 kDebugMode 내에서만
```

### 7. 빌드 보안
```
□ ProGuard/R8 난독화 적용 (Android)
□ 릴리스 빌드에서 디버깅 비활성화
□ 앱 서명 키 안전하게 관리
□ 무결성 검증 (선택)
```

## 프로세스

### Action 1: audit-secrets
민감 정보 노출 검사

```
Step 1: 하드코딩된 시크릿 검색
  - API 키 패턴 검색
  - 비밀번호 패턴 검색
  - 토큰 패턴 검색

Step 2: 환경 변수 사용 확인
  - dart-define 사용 여부
  - env_config.dart 검토

Step 3: .gitignore 검증
  - .env 파일 제외 확인
  - 키 파일 제외 확인

Step 4: Git 히스토리 검사 (선택)
  - 과거 커밋에 시크릿 노출 여부

Step 5: 리포트 생성
```

**시크릿 패턴 검사:**
```dart
// 검사 대상 패턴
final patterns = [
  r'api[_-]?key\s*[:=]\s*["\'][^"\']+["\']',
  r'secret[_-]?key\s*[:=]\s*["\'][^"\']+["\']',
  r'password\s*[:=]\s*["\'][^"\']+["\']',
  r'token\s*[:=]\s*["\'][^"\']+["\']',
  r'gsk_[a-zA-Z0-9]{20,}',  // Groq API Key
  r'sk-[a-zA-Z0-9]{20,}',   // OpenAI API Key
];
```

### Action 2: audit-storage
로컬 저장소 보안 검사

```
Step 1: SQLite 데이터 분석
  - 저장되는 데이터 유형
  - 암호화 적용 여부

Step 2: SharedPreferences 검사
  - 저장 데이터 확인
  - 민감 정보 여부

Step 3: 캐시 데이터 검토
  - 이미지 캐시
  - 네트워크 캐시

Step 4: 암호화 권장 사항
```

**안전한 저장소 패턴:**
```dart
// ✅ 안전한 저장 (flutter_secure_storage)
final storage = FlutterSecureStorage();
await storage.write(key: 'token', value: accessToken);

// ❌ 위험한 저장 (SharedPreferences)
final prefs = await SharedPreferences.getInstance();
await prefs.setString('token', accessToken); // 평문 저장
```

### Action 3: audit-network
네트워크 보안 검사

```
Step 1: HTTP vs HTTPS 확인
  - 모든 URL이 HTTPS인지

Step 2: API 호출 분석
  - 인증 헤더 처리
  - 요청 본문 검토

Step 3: 로깅 검사
  - 요청/응답 로깅 내용
  - 민감 정보 필터링

Step 4: 에러 처리 검토
  - 에러 메시지에 민감 정보 없음
```

**안전한 API 호출:**
```dart
// ✅ 안전한 로깅
void _logRequest(http.Request request) {
  if (kDebugMode) {
    debugPrint('Request: ${request.method} ${request.url}');
    // 헤더, 바디는 로깅하지 않음
  }
}

// ❌ 위험한 로깅
void _unsafeLog(http.Request request) {
  print('Headers: ${request.headers}');  // API 키 노출
  print('Body: ${request.body}');        // 사용자 데이터 노출
}
```

### Action 4: audit-permissions
권한 사용 검사

```
Step 1: Android 권한 분석
  - AndroidManifest.xml 검토
  - 필요한 권한만 요청하는지

Step 2: iOS 권한 분석
  - Info.plist 검토
  - 권한 설명 적절한지

Step 3: 런타임 권한 검사
  - permission_handler 사용
  - 적절한 시점에 요청

Step 4: 불필요한 권한 식별
```

**현재 앱 권한:**
```xml
<!-- Android -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

### Action 5: audit-build
빌드 보안 설정 검사

```
Step 1: Android 빌드 설정
  - minifyEnabled 확인
  - shrinkResources 확인
  - debuggable 설정

Step 2: iOS 빌드 설정
  - 코드 서명 확인
  - 엔타이틀먼트 검토

Step 3: Flutter 빌드 모드
  - 프로덕션 빌드 설정
  - dart-define 주입

Step 4: 난독화 설정
```

**안전한 빌드 설정:**
```groovy
// android/app/build.gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                      'proguard-rules.pro'
    }
}
```

### Action 6: security-report
전체 보안 감사 리포트

```
Step 1: 모든 감사 실행
  - audit-secrets
  - audit-storage
  - audit-network
  - audit-permissions
  - audit-build

Step 2: 취약점 분류
  - Critical, High, Medium, Low

Step 3: 개선 권장 사항
  - 우선순위별 정리

Step 4: 종합 리포트 생성
```

## 취약점 심각도

| 레벨 | 아이콘 | 설명 | 예시 |
|------|--------|------|------|
| Critical | 🔴 | 즉시 조치 필요 | API 키 하드코딩 |
| High | 🟠 | 빠른 조치 필요 | 평문 토큰 저장 |
| Medium | 🟡 | 조치 권장 | 불필요한 권한 |
| Low | 🟢 | 개선 권장 | 디버그 로그 과다 |

## 출력 형식

```
🔒 Flutter Security Audit Report

프로젝트: MindLog
감사 일시: 2026-01-10
스캔 범위: 전체 코드베이스

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 요약
├── Critical: 0개 ✅
├── High: 0개 ✅
├── Medium: 1개 ⚠️
└── Low: 2개

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ API 키 관리: PASS
   └── dart-define으로 안전하게 주입

✅ 로컬 저장소: PASS
   └── 일기 데이터 SQLite 저장 (암호화 권장)

✅ 네트워크 보안: PASS
   └── HTTPS 사용, 적절한 에러 처리

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟡 Medium Issues

1. [audit-storage] SQLite 암호화 미적용
   현재: 평문 저장
   권장: sqlcipher_flutter_libs 사용

   영향: 루팅/탈옥 기기에서 데이터 접근 가능

   ```yaml
   dependencies:
     sqlcipher_flutter_libs: ^0.6.0
   ```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟢 Low Issues

1. [audit-build] ProGuard 규칙 최적화 권장
   현재: 기본 규칙 사용
   권장: 앱 특화 규칙 추가

2. [audit-logging] 일부 debugPrint 존재
   위치: lib/core/services/analytics_service.dart
   권장: kDebugMode 가드 확인

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 권장 조치 (우선순위순)

1. [Medium] SQLite 암호화 도입 고려
   └── 민감 일기 데이터 보호 강화

2. [Low] ProGuard 규칙 검토
   └── 난독화 효과 극대화

3. [Low] 디버그 로그 정리
   └── 불필요한 로그 제거

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏆 보안 점수: 92/100 (우수)

다음 감사 권장: 주요 기능 추가 시
```

## 사용 예시

### 전체 보안 감사
```
> "/security audit"

AI 응답:
1. 전체 보안 감사 실행
2. 취약점 분류:
   - Critical: 0개
   - High: 0개
   - Medium: 1개
   - Low: 2개
3. 개선 권장 사항 제공
4. 보안 점수: 92/100
```

### API 키 검사
```
> "/security audit-secrets"

AI 응답:
1. 하드코딩된 시크릿 검색
2. 결과: 발견되지 않음 ✅
3. dart-define 사용 확인
4. .gitignore 검증 완료
```

### 저장소 보안 검사
```
> "/security audit-storage"

AI 응답:
1. SQLite 데이터 분석
   - 일기 내용 저장
   - 분석 결과 저장
2. 암호화: 미적용
3. 권장: sqlcipher 도입 고려
```

## MindLog 특화 보안 고려사항

### 일기 데이터 보호
```dart
// 현재: 평문 SQLite
// 권장: 암호화 SQLite 또는 flutter_secure_storage

// 민감 데이터
- 일기 내용 (content)
- AI 분석 결과 (analysis_result)
- 감정 점수 (sentiment_score)
```

### AI API 통신 보안
```dart
// 현재: HTTPS + dart-define API 키
// 추가 고려:
- Rate Limit 준수
- 요청 타임아웃
- 재시도 제한
```

### 알림 데이터
```dart
// 알림 설정은 민감하지 않음
// SharedPreferences 사용 가능
```

## 연관 스킬
- `/resilience` - 에러 처리 및 복원력
- `/code-review` - 코드 리뷰 (보안 항목 포함)
- `/lint-fix` - 코드 품질 개선

## 주의사항
- 보안 감사는 정기적으로 수행 권장
- 새 기능 추가 시 보안 영향 검토
- 민감 데이터 범위 명확히 정의
- 과도한 보안은 UX 저하 초래 가능
- 플랫폼별 보안 가이드라인 준수
- 보안 업데이트 정기 적용
- 제3자 패키지 취약점 모니터링
