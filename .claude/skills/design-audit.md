# Design Audit Skill

디자인 토큰 위반 감지 — 하드코딩 색상, 누락 토큰, 대비 부족 색상 사용을 탐지한다.

## 실행 전 준비

- 감사 대상 경로 확인 (기본값: `lib/presentation/`)
- `docs/design-guidelines.md` 참조 (토큰 매핑 규칙)
- `// design-ok: [이유]` 주석이 있는 줄은 위반에서 제외

---

## Step 1: Colors.white / Colors.black 하드코딩 탐지

```bash
# 위반 탐지 (design-ok 제외, app_colors.dart 제외)
grep -rn "Colors\.\(white\|black\)" <path> --include="*.dart" \
  | grep -v "design-ok" \
  | grep -v "app_colors.dart"
```

**올바른 대체**:
- `Colors.white` → `colorScheme.surface` (배경), `colorScheme.onPrimary` (버튼 텍스트)
- `Colors.black` → `colorScheme.onSurface` (텍스트), `colorScheme.scrim.withValues(alpha:...)` (오버레이)
- ShaderMask BlendMode.dstIn → `// design-ok: alpha mask (BlendMode.dstIn)` 주석으로 이스케이프

---

## Step 2: 인라인 Color(0x...) hex 탐지

```bash
# 인라인 hex 위반 (design-ok 제외, app_colors.dart 제외, _DiagnosticColors 등 private 제외)
grep -rn "Color(0x[0-9A-Fa-f]\{8\})" <path> --include="*.dart" \
  | grep -v "design-ok" \
  | grep -v "app_colors.dart"
```

**올바른 대체**: `AppColors`에 토큰 추가하거나, 위젯 전용인 경우 `_PrivateColors` 내부 클래스로 묶고 `// design-ok` 주석 추가.

---

## Step 3: AppColors.primary 텍스트 색상 오용 탐지

`AppColors.primary` (#87CEEB)는 파스텔 하늘 — on white 대비 1.7:1로 텍스트 WCAG 미달.

```bash
# primary가 TextStyle color로 직접 사용되는 패턴
grep -rn "color: AppColors\.primary[^D]" <path> --include="*.dart" \
  | grep -v "design-ok"
```

**올바른 대체**: `AppColors.primaryDark` (#4A90B8, WCAG AA ≈3.8:1)

---

## Step 4: 결과 집계 및 보고

각 위반에 대해 출력:
```
[VIOLATION] <file>:<line> — <위반 유형>
→ 제안 수정: <올바른 토큰>
```

최종 요약:
```
────────────────────────────
총 위반 건수: N
영향받는 파일: M
```

- violations=0 → "✓ 디자인 토큰 감사 통과"
- violations>0 → 각 위반을 수정하거나 `// design-ok: [이유]` 이스케이프 추가

---

## 참조

- 색상 토큰: `lib/core/theme/app_colors.dart`
- 텍스트 스타일: `lib/core/theme/app_text_styles.dart`
- 디자인 가이드: `docs/design-guidelines.md`
- 토큰 규칙: `.claude/rules/design-token-rules.md`
- 색상 마이그레이션: `/color-migrate [파일]`
