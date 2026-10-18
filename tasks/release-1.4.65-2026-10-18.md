# v1.4.65 릴리스 변경·검증 기록

작성: 2026-10-18. 요청 범위는 미푸시 변경 요약, 독자별 문서 반영, 버전업, 커밋 및 `main` 병합·푸시다. 스토어 배포 완료까지를 이번 결과로 단정하지 않는다.

## 대상과 완료 조건

- 시작 브랜치 `fix/android-system-ui-insets`, HEAD `95e7323b0630f10402884211ff5f54ad72ca9c87`. `origin/main` 이후 Android UI 커밋 7개와 사진 보관/텍스트 분석 로컬 구현을 포함한다.
- 소스 버전은 `1.4.64+72` → `1.4.65+73`. 이전 세션이 준비한 버전을 사용하며 중복으로 다시 올리지 않는다. Play Console의 versionCode 사용 가능 여부는 이번에 조회하지 않았다.
- `CHANGELOG.md`: 개발자용 계층별 변경·캐시/데이터 호환성·제거 코드·검증/한계. `docs/index.html`: 채용담당자용 문제·해결·효과와 검증 범위 3개 카드. `docs/update.json`: 사용자용 안내 5개, 최신 버전·갱신 시각. 기존 버전 안내 64개와 강제 업데이트 정책을 보존한다.
- README도 현행 동작·검사 결과와 맞춘다. Pages CSS는 카드 본문/태그 대비, 좁은 화면의 단일 열, 긴 코드 줄바꿈만 보완하고 캐시 키를 갱신했다.
- 성공 여부는 문서·버전 일치, 실제 검사 종료코드, main과 원격 커밋 일치로 판정한다. **품질 게이트는 아래 실패가 남아 있어 전체 PASS가 아니다.**
- 사용자가 푸시 대상을 **main에 병합 후 푸시**로 지정했다. Pages 게시 원본은 `main:/docs`(GitHub API 조회 rc=0), CD도 main push를 사용한다. 원격 반영/자동 배포의 최종 상태는 실행 결과로 별도 보고한다.

## 이번 세션의 실행 결과

| 명령 / 확인 | 결과 | 로그 / 근거 |
| --- | --- | --- |
| `./scripts/run.sh quality` | **FAIL, rc=1**. analyze·strict architecture·format 단계는 rc=0, design audit 기존 35건에서 중단. 이 실행은 테스트 단계까지 도달하지 않음 | `/tmp/mindlog-v1.4.65-quality.log`, `.rc` |
| `./scripts/run.sh test` | **PASS, rc=0, 1,847개**. 테스트 로그 누수 검사도 통과 | `/tmp/mindlog-v1.4.65-tests.log`, `.rc` |
| HEAD/현재 소스의 `bash scripts/design-audit.sh <presentation 경로>` 비교 | 두 감사는 각각 **FAIL, rc=1**. 파일/소스별 35건 동일, 비교는 **PASS, rc=0**, 신규 위반 0건 | `/tmp/mindlog-v1.4.65-design-{baseline,current}.log`, `/tmp/mindlog-v1.4.65-design-comparison.json` |
| `python3 /tmp/mindlog-v1.4.65-doc-check.py` 최종 실행 | **PASS, rc=0**. 버전·JSON·기존 출시 안내 보존·앵커 5개·로컬 Pages 리소스 11개 HTTP 200·보호 파일/CI 불변 확인 | `/tmp/mindlog-v1.4.65-doc-check.log`, `.json` |
| 같은 문서 검사 최초 실행 | **FAIL, rc=1**. 외부 Google Fonts stylesheet를 로컬 파일로 간주한 일회성 검사 스크립트 오류. 외부 URL 제외로 수정 후 위 결과 확보. 제품 코드 수정 없음 | `/tmp/mindlog-v1.4.65-doc-check-first-failure.log` |
| `git diff --check` | **PASS, rc=0** | 문서 검사에도 포함 |
| Chrome 로컬 페이지 시각/DOM 확인 | 데스크톱 1512px에서 카드 3열, 320px에서 단일 열·새 카드 내부 넘침 없음. CSS 보완 후 문서 폭 305px로 가로 넘침 없음. 본문·태그는 기존 진한 텍스트 토큰 사용. UI 도구는 shell exit code를 반환하지 않으므로 rc=N/A | `http://127.0.0.1:8765/index.html#updates`, 뷰포트 임시 설정은 복원 |
| 이전 A34 실기 증거 확인 | 저장된 최종/화면 검증 rc=0 파일 존재, 테스트한 제품 Dart 232개 해시가 현재 lib와 일치. **이번 세션의 실기 재실행이 아님** | [실기 검증 기록](photo-text-analysis-a34-verification-2026-10-18.md) |

## 보존과 한계

- 사용자 기존 `.serena/project.yml` 수정과 `.claude/settings.local.json.bak-allowwrite-20260721`은 해시를 보존하고 stage에서 제외한다. 이 두 항목이 남아 있어도 이번 작업 누락으로 간주하지 않는다.
- `SafetyBlockedFailure`가 있는 `lib/core/errors/failures.dart`는 기존 해시·origin/main 원본과 일치한다. Domain 순수 Dart와 presentation→data 경계 검사 통과. CI 워크플로·Fastlane 변경 없음.
- 디자인 감사 35건은 기존 부채다. 이번 릴리스에 무관한 화면 수정이나 검사 완화를 섞지 않았다. 전체 품질 결과는 **FAIL**로 유지한다.
- 배포 서명/R8 release 빌드·Firebase 부트스트랩·실제 사용자 DB 업그레이드·삼성 OS 사진 선택기 직접 조작·Play Store 제공 상태는 **UNVERIFIED**다.
- Fastlane의 `skip_upload_changelogs: true`는 유지한다. `update.json` 수정이 Play 출시 노트의 자동 업로드를 의미하지 않는다.
- 로그는 로컬 임시 경로이며 Git에는 포함하지 않는다. 오래된 구현/핸드오프의 “미커밋/안내 1.4.64 유지”는 해당 시점 기록이고, 이번 정리 상태는 본 문서가 우선한다.
