# Fastlane Play Store 배포 패턴

## 핵심 규칙

### skip_upload_changelogs 필수 설정
Play Console에 등록되지 않은 언어(예: ko)가 로컬 metadata에 존재할 경우:
- `skip_upload_changelogs: false` (기본값) → "Invalid request" 오류
- `skip_upload_changelogs: true` → 정상 동작

**원인**: changelog 업로드 시 `listing_for_language(lang)` API 호출 → 미등록 언어면 실패

### 권장 설정 (바이너리 전용 배포)
```ruby
upload_to_play_store(
  track: "internal",
  aab: "../build/app/outputs/bundle/release/app-release.aab",
  skip_upload_metadata: true,
  skip_upload_images: true,
  skip_upload_screenshots: true,
  skip_upload_changelogs: true  # 필수!
)
```

## 안티패턴

### continue-on-error 금지
```yaml
# ❌ 잘못된 패턴 - 오류 마스킹
- name: Deploy
  run: bundle exec fastlane deploy
  continue-on-error: true

# ✅ 올바른 패턴 - 실패 시 워크플로우 중단
- name: Deploy
  run: bundle exec fastlane deploy
```

## 언어 지원 확장 시
1. Play Console에서 먼저 언어 추가
2. `fastlane supply init`으로 메타데이터 동기화
3. 필요시 skip 옵션 조정

---
*발견일: 2025-01-29 | 커밋: b6c992c*
