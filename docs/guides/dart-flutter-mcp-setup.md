# Dart & Flutter MCP Server 설정 가이드 (MindLog)

> 기준일: 2026-02-27 | Flutter stable 채널 기준

---

## 현재 설정 상태

`.mcp.json` (프로젝트 루트, 체크인됨):

```json
{
  "mcpServers": {
    "dart": {
      "command": "fvm",
      "args": ["dart", "mcp-server"],
      "type": "stdio"
    }
  }
}
```

`fvm dart mcp-server`를 사용하므로 프로젝트 핀된 SDK(`.fvm/fvm_config.json`)를 자동 사용.

---

## 정적 도구 (stable 채널, 즉시 사용 가능)

| 도구 | 설명 |
|------|------|
| `analyze` | Dart 파일 분석, lint 오류 감지 |
| `format` | `dart format` 동일 포맷팅 |
| `pub search` | pub.dev 패키지 검색 |
| `pub add/remove` | `pubspec.yaml` 의존성 관리 |
| `test` | `flutter test` 실행 및 결과 파싱 |
| Symbol resolution | 심볼 → 문서/시그니처 조회 |

---

## 라이브 도구 (beta/dev 빌드 필요 — MindLog에서 미지원)

Hot reload, screenshot, 위젯 트리 조회는 **Dart Tooling Daemon(DTD)** 연결이 필요하며,
Dart SDK 3.9.0-163.0.dev+ 이상의 개발 빌드에서만 동작.

- GitHub [#176311](https://github.com/flutter/flutter/issues/176311): stable에서 DTD 연결 오류
- GitHub [#61366](https://github.com/dart-lang/sdk/issues/61366): Dart 3.9.0 stable에서 미동작
- **결론**: stable 채널 유지하는 한 라이브 도구는 사용 불가

---

## Phase 3 (선택): mcp_flutter — 스크린샷 & Hot Reload

**stable에서 동작 가능** (Dart VM Service 경유, DTD 아님).
단, 매 `flutter run`마다 포트가 변경되어 수동 업데이트 필요.

### 설치

```bash
# 방법 1: Smithery CLI
npx -y @smithery/cli install @Arenukvern/mcp_flutter --client claude

# 방법 2: 소스 빌드
cd ~/Developer
git clone https://github.com/Arenukvern/mcp_flutter
cd mcp_flutter && make install
```

### 세션별 사용법

1. `flutter run` 실행 → 출력에서 VM Service 포트 확인:
   ```
   VM Service is available at: http://127.0.0.1:PORT/...
   ```

2. 포트로 MCP 등록 (`.claude/settings.local.json` — gitignored):
   ```json
   {
     "mcpServers": {
       "flutter-inspector": {
         "command": "/Users/kaywalker/Developer/mcp_flutter/mcp_server_dart/build/flutter_inspector_mcp",
         "args": ["--dart-vm-host=localhost", "--dart-vm-port=PORT", "--no-resources", "--images"],
         "type": "stdio"
       }
     }
   }
   ```

3. Claude Code 재시작 후 스크린샷/위젯 트리 조회 가능

> **주의**: 포트는 세션마다 바뀌므로 `.claude/settings.local.json`을 매번 업데이트하거나,
> `claude mcp add` CLI로 등록 후 `claude mcp update`로 포트 갱신.

---

## 캐시 안정성 주의사항

MCP 서버 목록 변경 = system prompt tool 정의 변경 = **캐시 전체 무효화**.

- `dart` 서버는 `.mcp.json`에 고정 → 세션 시작부터 일관적 (안전)
- `flutter-inspector`는 `.claude/settings.local.json`에만 → gitignored, 로컬 전용
- 세션 중 MCP 서버 활성화/비활성화 금지 (`context-management.md` 참조)

---

## 참고 문서

- [Flutter Docs: MCP Server](https://docs.flutter.dev/ai/mcp-server)
- [Dart Docs: MCP Server](https://dart.dev/tools/mcp-server)
- [GitHub: Arenukvern/mcp_flutter](https://github.com/Arenukvern/mcp_flutter)
- [Very Good Ventures: 7 MCP Servers for Flutter](https://www.verygood.ventures/blog/7-mcp-servers-every-dart-and-flutter-developer-should-know)
