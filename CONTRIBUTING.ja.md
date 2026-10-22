# DigiMonTokenBarへの貢献

DigiMonTokenBar is an independent fan adaptation of
[chattymin/PokeTokenBar](https://github.com/chattymin/PokeTokenBar). Retain the
original MIT copyright and permission notices. See [NOTICE](NOTICE.md) and
[third-party notices](THIRD_PARTY_NOTICES.md) before changing artwork or data.

- Use macOS 14+, Swift 6 and Apple developer tools.
- Build with `./scripts/build-digimon-app.sh`.
- Validate with `./scripts/test-gate.sh`; focused tests use `swift test --filter <TestCase>`.
- Package with `./scripts/package-digimon-app.sh`. This creates a local ZIP only.
- Use English Conventional Commit titles and describe behavior and validation.
- Keep maintained regression tests; do not commit personal saves, credentials,
  private paths, agent instructions, local QA fixtures, previews or instrumentation.
- Do not add downloaded artwork to resources. The distribution allowlist must pass.
- Runtime downloads do not establish copyright permission; include provenance and
  verify applicable terms. No official endorsement or rights clearance is claimed.
- Follow the pull request template. Provide only images you may share when
  explaining a visible UI change; never include private data.

To report a problem, use this repository's Issues and describe the OS, app version,
expected behavior and actual behavior. Remove secrets, prompts and private paths
from any diagnostic text before posting it.
