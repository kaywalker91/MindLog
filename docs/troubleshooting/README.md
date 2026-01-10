# MindLog Troubleshooting

> 알려진 이슈 및 해결책 문서

## Known Issues

| Issue | Status | Category | Related |
|-------|--------|----------|---------|
| [예약 알림 미작동 (Release)](./notification-not-firing-release.md) | **해결됨** | Android / Proguard | NotificationService |

## Issue Categories

### Android
- [예약 알림 미작동 (Release)](./notification-not-firing-release.md) - R8 난독화로 인한 알림 실패

### iOS
- (이슈 없음)

### Firebase
- (이슈 없음)

### Build
- (이슈 없음)

---

## Quick Diagnosis

### 알림이 작동하지 않음
```
1. Debug vs Release 환경 확인
2. Release면 → proguard-rules.pro 확인
3. flutter_local_notifications keep 규칙 추가
```

### 빌드 실패
```
1. flutter clean
2. flutter pub get
3. flutter analyze
```

### Firebase 연결 실패
```
1. google-services.json 위치 확인
2. Firebase 프로젝트 설정 확인
3. 네트워크 연결 확인
```

---

## Issue Template

새로운 이슈 문서 작성 시:

```markdown
# {이슈 제목} 트러블슈팅

> **상태** | YYYY-MM-DD | Category

## 문제 요약
| 항목 | 내용 |
|------|------|
| 증상 | |
| 환경 | |
| 영향 | |
| 해결책 | |

## 근본 원인
...

## 해결 방법
...

## 진단 과정
...

## 검증 방법
...

## 관련 파일
...

## 교훈
...
```

---

## Related

- [Skills Index](../skills/README.md) - 자동화 스킬
- [Deployment Guide](../guides/deployment.md) - 배포 가이드
