# DigiMonTokenBar release procedure

1. Review README installation steps, NOTICE, third-party provenance and rights limits.
   The website in `site/` is assembled by `python3 site/build.py`; its version/download
   links follow `scripts/build-digimon-app.sh`. GitHub Pages deploys relevant main changes.
2. Keep personal saves, credentials, local QA material, screenshots and agent instructions out of Git.
3. Run `./scripts/test-gate.sh` and `python3 scripts/check-digimon-artwork-distribution.py`.
4. Run `./scripts/package-digimon-app.sh` and verify the ZIP with
   `python3 scripts/verify-digimon-package.py <ZIP> --launch` using isolated state.
5. Review the exact commit, version, English release notes, contributors and SHA-256.
6. Push the source commit, then publish a matching version tag with the ZIP and checksum.
7. Update `version` and `sha256` in [the Homebrew tap](https://github.com/Choisiz/homebrew-tap/blob/main/Casks/digitokenbar.rb)
   to match the published arm64 ZIP; validate the cask and push the tap update.
8. Confirm the source tree, download files, checksum and public CI result.

Current release: 0.1.1, Apple Silicon only, macOS 14 minimum deployment target.
Developer ID signing and Apple notarization have not been performed. Document the
first-run Privacy & Security exception and never advise disabling system-wide protection.
Original upstream Git history and MIT credits are retained. Runtime image delivery
is not a rights grant for third-party images, text, data or designs.
