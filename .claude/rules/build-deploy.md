# Build & Deploy

## Groq API Key Injection

**Priority**: `GROQ_API_KEY` > `DEV_GROQ_API_KEY` (debug only)

| Environment | Variable | Usage |
|-------------|----------|-------|
| Production | `GROQ_API_KEY` | `--dart-define=GROQ_API_KEY=xxx` |
| Development | `DEV_GROQ_API_KEY` | debug mode fallback only |

**Local build:**
```bash
GROQ_API_KEY=your_key ./scripts/run.sh build-appbundle
```

**CI/CD build (cd.yml):**
```yaml
flutter build appbundle --release \
  --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }} \
  --dart-define=ENVIRONMENT=production
```

## CI/CD Pipelines

| Workflow | Trigger | Steps |
|----------|---------|-------|
| `ci.yml` | PR to main/develop | analyze -> test -> build-check |
| `cd.yml` | push to main | test -> build-appbundle -> Play Store (internal) |

## Required GitHub Secrets
`GROQ_API_KEY`, `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`, `PLAY_STORE_SERVICE_ACCOUNT_JSON`

## Key Files
| File | Role |
|------|------|
| `lib/core/config/env_config.dart` | API Key config & fallback |
| `scripts/run.sh` | Local build script |
| `.github/workflows/ci.yml` | PR validation |
| `.github/workflows/cd.yml` | Deploy pipeline |
