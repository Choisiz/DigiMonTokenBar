# DigiTokenBar 0.1.1 validation

Validated on 2026-10-20 on Apple Silicon using the installed Xcode toolchain.

| Check | Result |
| --- | --- |
| XCTest release gate | 1,585 executed, 17 skipped, zero failures |
| English regressions | Included: all recipe/item strings, 475 English profiles and production scene JavaScript |
| Logic-core line coverage | 91.17%, above the unchanged 75% gate |
| Source and packaged resources | 18 allowlisted files; no downloaded third-party image files |
| Extracted optimized app | Signature, checksum, builder-path scan and 12-second isolated native startup passed |
| Personal save protection | Temporary bundle ID and isolated state; personal save not accessed |
| Documentation | Eight refreshed native English UI renders with synthetic data |

Release ZIP: `DigiTokenBar-0.1.1-macos-arm64.zip` (6,650,192 bytes).

SHA-256: `5de53a197dd9b0a51e97b658f8872a4d0b3dbfaf4778fcb188f2fc092af4d8ae`.

Runtime artwork sources are unchanged from 0.1.0; a full remote-artwork download was not repeated for this localization patch. The 475 English profile excerpts, classifications and move lists were checked for matching species IDs and Korean text leakage. Screenshots use synthetic data, not personal usage. Recording videos, local saves, capture tools and agent instructions are excluded from Git.

This is an arm64, macOS 14+ build. Intel and a separate physical macOS 14 machine have not been verified. The app is ad-hoc signed without Developer ID signing or Apple notarization; Gatekeeper assessment is expected to reject an unapproved direct download. Homebrew removes only the installed app's quarantine attribute. Passing integrity tests or delivering artwork at runtime does not grant third-party rights.

[Runtime artwork](runtime-artwork.md) · [third-party rights](../../THIRD_PARTY_NOTICES.md) · [public CI](https://github.com/Choisiz/DigiTokenBar/actions)

## Historical 0.1.0 evidence

Validated on 2026-10-19 using Xcode 27.1 / Swift 6.4, macOS 26.6.2, Apple Silicon.

| Check | Result |
| --- | --- |
| XCTest | 1,582 executed: 1,565 passed, 17 skipped, zero failures |
| Final detail/traffic rendering regressions | 9 passed, zero failures |
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
checked for builder home paths. User saves, QA fixtures, private screenshots, instrumentation, development logs and
agent instructions are excluded from the current public source tree. Maintained
regression tests and build/check tools remain. Original upstream commit history
and author/license attribution are retained; upstream history can include files
removed from this fork's current tree.

[Runtime artwork](runtime-artwork.md) · [third-party rights](../../THIRD_PARTY_NOTICES.md)

Release ZIP: `DigiTokenBar-0.1.0-macos-arm64.zip` (6,606,367 bytes).
SHA-256: `fc52b114a49fac121552159697485c5d330a455c77240a4c6fe27d6ebef63121`.
The release archive passed full-byte private-marker scanning and signature checks.
Its copied executable was launched after re-signing only the isolated temporary-ID
copy; the distribution archive and currently running user application were unchanged.

Documentation update (2026-10-20): the explicitly reviewed README feature-tour images
are native renders with synthetic data. These documentation-only images do not change
the release app or its bundled resource inventory.
