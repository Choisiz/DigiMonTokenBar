# DigiMonTokenBar for Windows

React + TypeScript + Tauri desktop preview **0.2.11**, alongside the existing Swift macOS app.

## Download and run

[Download the x64 ZIP](https://github.com/Choisiz/DigiMonTokenBar/releases/download/windows-v0.2.11/DigiMonTokenBar-0.2.11-Windows-x64.zip), extract it, then run `DigiMonTokenBar.exe`. No developer tools are required. Windows 11 x64 is verified; Microsoft Edge WebView2 Runtime must be installed. See the [English guide](../README.md#windows-download-and-usage) or [한국어 안내](../README.ko.md#windows-다운로드-및-사용법) for setup, tray controls and updates.

The first scan baselines existing usage. Later log increases grow the partner. Codex defaults to `%USERPROFILE%/.codex/sessions` and `archived_sessions` (or CODEX_HOME); Claude Code defaults to `%USERPROFILE%/.claude/projects`, `.config/claude/projects`, or CLAUDE_CONFIG_DIR. Additional folders can be selected in Settings.

Progress is stored under `%LOCALAPPDATA%/com.choisiz.digimontokenbar.windows/state-v2.json`; the previous save is retained as `.bak`. Export/import uses `.digimon2`. macOS saves are not compatible. The `--demo` flag enables an isolated 148-species sample; ordinary launches use the user's progress.

## Features and limits

- Ordinary branching evolution and conditional fusion/item/daily-token evolution; Notebook, capture paths, shop and inventory.
- System tray, floating partner, representative species, token display and animation settings.
- Pet visibility and always-on-top apply immediately; other settings apply after Save.
- Local Codex/Claude Code JSONL logs are supported. Account quota, remaining allowance and billing costs are not queried.
- English translation is partial. Original macOS pet size control, bubble alerts and some system integrations are not yet ported.
- Character/item artwork is fetched at runtime and cached, rather than bundled. See [LICENSE](../LICENSE), [NOTICE](../NOTICE.md), [third-party notices](../THIRD_PARTY_NOTICES.md) and the bundled Noto Sans KR OFL license.

## Develop and build

Install Node.js, Rust stable MSVC and Visual Studio Build Tools with Desktop development with C++ (MSVC and Windows SDK). From this directory:

~~~powershell
npm ci
npm test
npm run build
cargo test --lib --manifest-path src-tauri/Cargo.toml
npm run build:windows
~~~

Default output: `src-tauri/target/release/digimon-tokenbar.exe`. For a separate build directory use `scripts/Build-Windows.ps1`; it runs the frontend/native checks and Windows build. From the repository root: `powershell -File desktop/scripts/Build-Windows.ps1`.

Shared Digimon JSON resources remain under `../Sources/PokeTokenBar/Resources/Digimon`. The Swift macOS sources are unchanged by the Windows port. Browser preview (`npm run dev`) uses sample data; native save mutations require Tauri.

## Validation

Native logic regression suite: 38 tests, including every ordinary edge, special conditions, item consumption, usage accounting and continuation. Frontend catalog/continuation: 12 tests. Release 0.2.11 settings validation used an isolated native app: 12 scenarios passed, including actual pet-window visibility/topmost, settings persistence, animation, difficulty, log roots and manual/60-second refresh. File-picker export/import was not automated in that UI run. Other refresh intervals use the same timer but were not individually waited out.
