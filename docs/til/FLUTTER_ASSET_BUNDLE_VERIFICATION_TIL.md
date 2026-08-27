# 기기 없이 Flutter asset 번들링 검증하기

**작성일**: 2026-08-25
**계기**: v1.4.63 — 개인정보 처리방침 asset이 AAB에 실렸는지 확인해야 했으나, "앱 설치해서 화면 열어보기"가 유일한 검증 수단처럼 보였다
**난이도**: 초급
**소요 시간**: 10분

---

## 1. 문제: "앱 켜서 확인" 은 검증 병목이다

MindLog의 `docs/legal/privacy-policy.md`는 문서처럼 생겼지만 **앱 번들 asset**이다(`pubspec.yaml`의 `assets:` 에 선언, `privacy_policy_screen.dart`가 `rootBundle.loadString()`으로 렌더).

v1.4.62에서 이 파일의 잘못된 문장을 고쳤는데 CD가 트리거되지 않아 versionCode 70 AAB에 반영되지 못했다. v1.4.63으로 재빌드한 뒤 **"이번엔 정말 실렸는가"** 를 확인해야 했는데, 기본 접근은 이랬다:

> Internal 트랙 빌드를 기기에 설치 → 설정 > 개인정보 처리방침 열기 → 문장 대조

이 방식의 문제는 세 가지다.

| 문제 | 설명 |
|------|------|
| **느리다** | 업로드 → 배포 반영 대기 → 설치 → 화면 이동. 수십 분이 프로덕션 승격을 막는다 |
| **증거가 약하다** | "봤더니 맞더라"는 재현·기록이 안 된다. 스크린샷도 어느 빌드인지 증명하지 못한다 |
| **늦다** | 빌드가 끝난 **뒤에야** 알 수 있다. 잘못됐으면 버전을 또 올려야 한다 |

핵심은 이것이다 — **asset이 번들에 들어갔는지는 앱을 실행해야만 알 수 있는 정보가 아니다.** 빌드 산출물을 직접 보면 된다.

---

## 2. 방법 A: `flutter build bundle` + 해시 대조 (빠름, 빌드 전 가능)

`flutter build bundle`은 Dart 컴파일과 asset 수집만 수행해 `build/flutter_assets/`를 만든다. Android 툴체인·서명·AAB 패키징이 없어 **수 초** 안에 끝나고, `GROQ_API_KEY` 같은 릴리스 변수도 필요 없다.

```bash
fvm flutter build bundle
# → build/flutter_assets/ 생성

# 1) asset이 존재하는가 + 경로가 맞는가
ls -la build/flutter_assets/docs/legal/privacy-policy.md

# 2) 내용이 저장소 원본과 동일한가  ← 핵심
shasum -a 256 build/flutter_assets/docs/legal/privacy-policy.md docs/legal/privacy-policy.md
diff -q build/flutter_assets/docs/legal/privacy-policy.md docs/legal/privacy-policy.md
```

v1.4.63 실측:

```
2bd36259926fb2068dc3c5a3bc5ce70d1c03a1f88859e84daf0606e52a19dfdf  build/flutter_assets/docs/legal/privacy-policy.md
2bd36259926fb2068dc3c5a3bc5ce70d1c03a1f88859e84daf0606e52a19dfdf  docs/legal/privacy-policy.md
→ 동일
```

**해시가 같으면 "이 파일이 번들에 들어갔다"가 바이트 단위로 증명된다.** 눈으로 문장을 읽는 것보다 강한 증거다.

### `build/flutter_assets/` 구조

```
build/flutter_assets/
├── AssetManifest.bin      ← 최신 Flutter는 .json 이 아니라 .bin (바이너리)
├── FontManifest.json
├── NativeAssetsManifest.json
├── docs/legal/privacy-policy.md   ← pubspec 경로가 그대로 유지된다
├── assets/  packages/  fonts/  shaders/
├── kernel_blob.bin  vm_snapshot_data  isolate_snapshot_data
└── NOTICES.Z
```

> ⚠️ `AssetManifest.json`을 파싱해 확인하려던 접근은 실패한다. 최신 Flutter는 **`AssetManifest.bin`(바이너리)** 만 만든다. 매니페스트를 파싱하려 들지 말고 **디렉터리에 파일이 있는지 + 해시가 맞는지**를 보면 된다.

---

## 3. 방법 B: AAB/APK 직접 검사 (결정적, 빌드 후)

실제로 배포될 산출물을 직접 뜯는 방법이다. AAB는 그냥 zip이다.

```bash
# asset이 AAB 안에 있는가
unzip -l build/app/outputs/bundle/release/app-release.aab | grep "flutter_assets/docs"
#     5680  01-01-1981 01:01   base/assets/flutter_assets/docs/legal/privacy-policy.md

# 내용을 꺼내서 직접 대조
unzip -p build/app/outputs/bundle/release/app-release.aab \
  base/assets/flutter_assets/docs/legal/privacy-policy.md | shasum -a 256
```

**AAB 내부 경로는 `base/assets/flutter_assets/<pubspec 경로>` 다.** (APK는 `assets/flutter_assets/<경로>`)

위 출력의 `5680` 바이트는 구버전 AAB(2026-02 빌드)의 방침 파일이고, v1.4.63 기준 원본은 **11,468 바이트**다. 크기만 봐도 다른 파일임이 드러난다 — 이런 식으로 **"이 AAB에 실린 게 어느 시점 버전인가"** 를 판별할 수 있다.

> zip 엔트리의 타임스탬프(`01-01-1981`)는 재현 가능 빌드를 위해 고정된 값이라 **날짜 판별에 쓸 수 없다.** 크기와 해시로 봐야 한다.

---

## 4. 검증은 3단계 체인이다

asset 하나가 화면에 뜨기까지 끊길 수 있는 고리는 셋이고, 위 방법은 그중 둘을 덮는다.

| 단계 | 무엇을 확인하나 | 방법 |
|------|----------------|------|
| **① 선언** | pubspec의 `assets:` 에 경로가 있는가 | `grep -A5 "assets:" pubspec.yaml` |
| **② 번들** | 산출물에 실제로 들어갔고 내용이 맞는가 | 방법 A / B (해시 대조) |
| **③ 로드** | 코드가 **그 경로 문자열**로 읽는가 | `grep -rn "rootBundle" lib/` 로 경로 문자열 대조 |

③이 중요하다. `pubspec`에 선언하고 번들에 들어가도, 코드가 다른 경로 문자열로 읽으면 런타임에 실패한다. v1.4.63에서는 이렇게 확인했다:

```bash
grep -rn "rootBundle" lib/presentation/screens/privacy_policy_screen.dart
# 31:  final content = await rootBundle.loadString(
# 32:    'docs/legal/privacy-policy.md',     ← 번들 내 경로와 일치
```

여기에 더해 **그 화면 파일이 이번 릴리스에서 변경되지 않았음**을 `git log -- <file>`로 확인하면, 렌더링 회귀 가능성까지 배제된다.

---

## 5. 이 방법이 증명하는 것과 증명하지 않는 것

**증명한다**
- asset이 번들에 포함됐다
- 내용이 저장소 원본과 바이트 단위로 같다
- 코드가 참조하는 경로와 번들 경로가 일치한다

**증명하지 않는다**
- 렌더링 결과(마크다운 표가 좁은 화면에서 깨지는지 등) — MindLog은 `flutter_markdown_plus` 스타일시트에 표 스타일이 없어 실제로 겪은 문제다
- 화면 진입 경로가 살아 있는지 (라우팅·버튼)
- 다국어/테마별 표시

즉 **"실렸는가"는 완전히 닫히고, "예쁘게 보이는가"는 남는다.** 콘텐츠만 고친 릴리스라면 전자로 충분하고, 렌더링 코드를 건드렸다면 여전히 눈으로 봐야 한다.

---

## 6. 체크리스트

asset(마크다운·JSON·이미지)을 수정한 릴리스에서:

- [ ] `pubspec.yaml` `assets:` 에 경로가 선언돼 있는가
- [ ] **CI 트리거 경로에 걸리는가** — `cd.yml`의 `paths-ignore`가 asset 경로를 제외하고 있지 않은지. MindLog은 `docs/**` 제외 때문에 실제로 반영 누락 사고를 냈다
- [ ] `fvm flutter build bundle` → `build/flutter_assets/<경로>` 존재 확인
- [ ] 저장소 원본과 `shasum -a 256` 일치
- [ ] `rootBundle.loadString('<경로>')` 문자열이 번들 경로와 동일
- [ ] (선택) AAB에서 `unzip -p ... | shasum -a 256` 으로 최종 확인
- [ ] 렌더링 코드를 변경했다면 → 여기서 멈추지 말고 실제 화면 확인

---

## 7. 일반화

> **빌드 산출물에 대한 질문은 앱을 실행하지 말고 산출물에게 물어라.**

"앱을 켜봐야 안다"고 느끼는 검증 중 상당수는 실제로는 파일 시스템 질문이다. asset 포함 여부, 폰트 번들링, 네이티브 라이브러리 ABI, ProGuard 제거 여부 모두 zip 하나를 뜯으면 나온다. 실행이 필요한 건 **동작**이지 **포함**이 아니다.

---

## 관련 문서

- `memory/privacy-policy-is-an-app-asset.md` — 이 asset이 CD 트리거에서 누락되는 함정
- `tasks/lessons.md` 2026-08-25 — cd.yml `paths-ignore` 양방향 결함
- `CLAUDE.md` Protected Files — `docs/` 디렉터리 파일들의 역할
