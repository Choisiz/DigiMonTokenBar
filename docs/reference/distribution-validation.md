# DigiTokenBar 0.1.0 validation

Validated on 2026-10-19 using Xcode 27.1 / Swift 6.4, macOS 26.6.2, Apple Silicon.

| Check | Result |
| --- | --- |
| XCTest | 1,582 executed: 1,565 passed, 17 skipped, zero failures |
| Logic-core line coverage | 90.77%, above the unchanged 75% gate |
| Artwork cache | 98.51% line coverage; 89.83% region coverage |
| Live remote originals | 489/489 downloaded and decoded |
| Source and packaged resources | 17 allowlisted files; no downloaded third-party image files |
| Extracted optimized app | Verified with isolated state; concurrent validation uses a temporary-ID copy |
| Personal save protection | Isolated state directory; parallel validation never reads personal saves |
| ZIP / SHA-256 / ad-hoc integrity | Passed |

Skips include opt-in performance, screenshots, local parity/credential-dependent
checks and the opt-in live artwork check, which passed separately. Coverage is
not a claim of exhaustive UI, branch or external-service verification.

The current downloadable build is arm64. Intel/universal and a separate physical
macOS 14 machine have not been verified. It uses an ad-hoc signature, without
Developer ID or Apple notarization; downloaded apps may require a manual exception
under Privacy & Security. Public CI results are available under the repository's
[Actions](https://github.com/Choisiz/DigiTokenBar/actions) tab.

Debug/local symbols are stripped before signing and the extracted executable is
checked for builder home paths. User saves, QA fixtures, local screenshots, instrumentation, development logs and
agent instructions are excluded from the current public source tree. Maintained
regression tests and build/check tools remain. Original upstream commit history
and author/license attribution are retained; upstream history can include files
removed from this fork's current tree.

[Runtime artwork](runtime-artwork.md) · [third-party rights](../../THIRD_PARTY_NOTICES.md)

Release ZIP: `DigiTokenBar-0.1.0-macos-arm64.zip` (6,605,029 bytes).
SHA-256: `857622dd2a2202d7e1698ec34eebfee5482eb328ad4907bb3ed12175057f201e`.
The release archive passed full-byte private-marker scanning and signature checks.
Its copied executable was launched after re-signing only the isolated temporary-ID
copy; the distribution archive and currently running user application were unchanged.
