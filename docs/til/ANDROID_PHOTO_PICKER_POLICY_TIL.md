# TIL: Google Play Photo/Video Permissions 정책 대응

**생성일**: 2026-01-21
**주제**: Android Photo Picker API와 Google Play 정책 준수
**난이도**: 중급
**소요 시간**: 15-20분

---

## 1. 문제

### 1.1 Google Play 정책 변경 (2024-2025 시행)

Google Play는 2024년부터 **Photo/Video Permissions 정책**을 강화하여, 앱이 `READ_MEDIA_IMAGES` 또는 `READ_MEDIA_VIDEO` 권한을 요청할 경우 **반드시 정당한 사유를 증명**해야 합니다.

```
정책 위반 시 제재:
- 스토어 게시 거부
- 기존 앱 삭제 경고
- 개발자 계정 정지 (반복 위반 시)
```

### 1.2 문제 상황

MindLog 앱에 AI 일기 사진 분석 기능을 추가하면서 갤러리 접근이 필요했습니다:

```xml
<!-- 문제가 될 수 있는 권한 선언 -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

**핵심 질문**:
- 사진 선택만 필요한데 `READ_MEDIA_IMAGES` 권한이 필요한가?
- Google Play 심사를 통과할 수 있는가?
- 사용자 경험을 해치지 않는가?

### 1.3 기술적 배경

| Android 버전 | API Level | 갤러리 접근 방식 |
|--------------|-----------|------------------|
| 10 이하 | ≤29 | `READ_EXTERNAL_STORAGE` |
| 11-12 | 30-32 | `READ_EXTERNAL_STORAGE` (scoped) |
| 13+ | ≥33 | `READ_MEDIA_IMAGES` 또는 Photo Picker |

---

## 2. 해결책

### 2.1 Android Photo Picker API 활용

Android 13 (API 33)부터 제공되는 **Photo Picker**는 **권한 없이** 사용자가 선택한 사진에만 접근할 수 있습니다.

```
Photo Picker 특징:
- 시스템 UI 제공 (일관된 UX)
- 권한 불필요 (No runtime permission)
- 선택한 파일에만 임시 접근권 부여
- Google Play 정책 자동 준수
```

### 2.2 image_picker Flutter 패키지 동작

`image_picker` 패키지 버전 1.0.0 이상은 **자동으로 Photo Picker를 사용**합니다:

```dart
// image_picker 사용 예시
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.gallery);
```

**내부 동작 (Android 13+)**:
```
1. ImagePicker.pickImage() 호출
2. Android Photo Picker Intent 실행 (ACTION_PICK_IMAGES)
3. 시스템 Photo Picker UI 표시
4. 사용자가 사진 선택
5. 선택된 파일의 임시 URI 반환
6. 앱에서 해당 URI로 파일 접근
```

### 2.3 권한 전략: 하이브리드 접근

```xml
<!-- AndroidManifest.xml - 최적화된 권한 선언 -->

<!-- 카메라 권한 (사진 촬영용) -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Android 12 이하: READ_EXTERNAL_STORAGE로 갤러리 접근 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />

<!-- Android 13+: image_picker가 Photo Picker 사용하여 READ_MEDIA_IMAGES 불필요 -->
<!-- READ_MEDIA_IMAGES 선언하지 않음! -->

<!-- 카메라 기능 선택적 (필수 아님) -->
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

**핵심 포인트**:
- `READ_MEDIA_IMAGES` 선언 **제거**
- `android:maxSdkVersion="32"` 사용하여 Android 13+에서 `READ_EXTERNAL_STORAGE` 자동 무시
- Photo Picker가 권한 없이 작동하므로 정책 위반 없음

### 2.4 버전별 동작 매트릭스

| Android 버전 | 갤러리 | 카메라 | 필요 권한 |
|--------------|--------|--------|-----------|
| 12 이하 | READ_EXTERNAL_STORAGE | CAMERA | 2개 |
| 13+ | Photo Picker (권한 불필요) | CAMERA | 1개 |

---

## 3. 핵심 교훈

### 3.1 정책 우선 설계 (Policy-First Design)

```
Before: 기능 구현 → 필요 권한 추가 → 정책 검토
After:  정책 검토 → 권한 최소화 설계 → 기능 구현
```

**교훈**: Google Play 정책을 **개발 초기**에 검토하면 재작업을 방지할 수 있습니다.

### 3.2 플랫폼 API 진화 추적

```dart
// 과거 (Android 12 이하)
// 권한 요청 → 갤러리 전체 접근

// 현재 (Android 13+)
// Photo Picker → 선택된 파일만 접근 → 권한 불필요
```

**교훈**: 새로운 플랫폼 API가 권한 문제를 해결해주는 경우가 많습니다.

### 3.3 패키지 버전 차이 인식

| image_picker 버전 | Android 동작 |
|-------------------|--------------|
| < 1.0.0 | 기존 Intent 방식 |
| >= 1.0.0 | Photo Picker 자동 사용 |

**교훈**: 패키지 업그레이드만으로 정책 준수가 가능할 수 있습니다.

### 3.4 android:maxSdkVersion 활용

```xml
<!-- 특정 버전 이하에서만 권한 적용 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

**교훈**: `maxSdkVersion`을 활용하면 레거시 지원과 새 정책 준수를 동시에 달성할 수 있습니다.

### 3.5 권한 최소화 원칙

```
권한 요청 시 자문:
1. 이 권한이 정말 필요한가?
2. 권한 없이 달성할 수 있는 대안이 있는가?
3. 권한 범위를 더 좁힐 수 있는가?
```

---

## 4. 구현 체크리스트

### 4.1 AndroidManifest.xml 검증

```
[x] READ_MEDIA_IMAGES 제거 또는 미선언
[x] READ_EXTERNAL_STORAGE에 maxSdkVersion="32" 추가
[x] CAMERA 권한 선언 (촬영 기능 사용 시)
[x] uses-feature required="false" 설정
```

### 4.2 패키지 버전 확인

```yaml
# pubspec.yaml
dependencies:
  image_picker: ^1.0.0  # Photo Picker 자동 사용
```

### 4.3 테스트 매트릭스

```
[ ] Android 12 (API 32) - READ_EXTERNAL_STORAGE 테스트
[ ] Android 13 (API 33) - Photo Picker 테스트
[ ] Android 14 (API 34) - Photo Picker 테스트
[ ] 권한 거부 시나리오 테스트
```

### 4.4 Google Play 제출 전 확인

```
[ ] 권한 선언 목록 검토
[ ] Data Safety Form 업데이트
[ ] 정책 가이드라인 재확인
```

---

## 5. 참고 링크

### Google 공식 문서

- [Photo Picker 가이드](https://developer.android.com/training/data-storage/shared/photopicker)
- [Photo/Video Permissions 정책](https://support.google.com/googleplay/android-developer/answer/14115180)
- [권한 선언 가이드](https://developer.android.com/guide/topics/permissions/overview)

### Flutter 패키지

- [image_picker 패키지](https://pub.dev/packages/image_picker)
- [image_picker Changelog](https://pub.dev/packages/image_picker/changelog)

### 관련 블로그/아티클

- [Android 13 Photo Picker 변경사항](https://android-developers.googleblog.com/2022/05/photo-picker-privacy-friendly-and-no.html)
- [Google Play 2024 정책 변경 요약](https://android-developers.googleblog.com/2023/12/new-google-play-policies-to-strengthen-user-trust-and-safety.html)

---

## 6. 요약

```
문제: Google Play Photo/Video Permissions 정책으로 READ_MEDIA_IMAGES 사용 제한
해결: Android 13+ Photo Picker API 활용 (권한 불필요)
핵심: image_picker >= 1.0.0 + maxSdkVersion="32" 조합으로 정책 준수
```

### 한 줄 요약

> **Android 13+에서 Photo Picker를 사용하면 READ_MEDIA_IMAGES 권한 없이 갤러리 접근이 가능하며, image_picker 1.0.0+가 이를 자동으로 처리한다.**

---

**작성자**: Claude Code
**최종 검수**: 2026-01-21
**다음 업데이트**: 정책 변경 시