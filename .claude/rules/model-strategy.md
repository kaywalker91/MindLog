# Model Strategy (모델 전략)

## 태스크 유형별 모델 선택 기준

| 단계 | 모델 | 사용 기준 |
|------|------|----------|
| 탐색 / 보일러플레이트 | Haiku 4.5 | 단순 위젯, 빠른 아이디어 검증, 반복 작업 |
| 핵심 기능 개발 | Sonnet 4.6 | 멀티파일 변경, Riverpod 설계, Firebase 연동 |
| 최종 검증 / 최적화 | Opus 4.6 | 메모리 누수, 아키텍처 리뷰, 복잡한 버그 |

## 상세 적용 가이드

### Haiku 4.5 — 빠른 반복
- 단일 파일 위젯 생성 (`scaffold`, `settings-card-gen`)
- 보일러플레이트 코드 (DTO, Model, Entity 필드 추가)
- 아이디어 검증 / 프로토타이핑
- 단순 lint 수정, 포맷팅
- `/test-unit-gen` 단순 케이스

### Sonnet 4.6 — 주력 개발 (기본값)
- Clean Architecture 레이어 간 변경 (2+ 파일)
- Riverpod Provider 설계 및 invalidation chain
- Firebase / Groq API 통합
- 비즈니스 로직 UseCase 구현
- 알림 시스템, DB 마이그레이션
- 대부분의 feature 개발

### Opus 4.6 — 심층 분석
- 복잡한 버그 (race condition, 메모리 누수)
- 아키텍처 레벨 리팩토링 결정
- 성능 병목 원인 분석
- 보안 취약점 리뷰
- `--think-hard` / `--ultrathink` 플래그 작업

## 비용 최적화 원칙

1. **Haiku 먼저 시도** — 탐색/생성 단계는 Haiku로 충분
2. **Sonnet으로 구현** — 실제 코드 작성은 Sonnet이 기본
3. **Opus는 목적 있을 때만** — "왜 Opus가 필요한가?" 자문 후 사용
4. **컨텍스트 70% 이상** → Haiku + `--uc` 플래그로 토큰 절감

## Claude Code에서 모델 전환

```
# Haiku로 전환 (빠른 탐색)
/model claude-haiku-4-5-20251001

# Sonnet으로 복귀 (기본값)
/model claude-sonnet-4-6

# Opus 심층 분석
/model claude-opus-4-6
```
