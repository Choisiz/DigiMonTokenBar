<div align="center">
<img src="Sources/PokeTokenBar/Resources/Digimon/AppIcon.png" width="128" alt="DigiTokenBar fan-made Digivice icon">

# DigiTokenBar

**Turn your AI coding tokens into Digimon growth, right in your macOS menu bar.**

[![macOS](https://img.shields.io/badge/macOS-14%2B-0969da)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6-f05138)](https://swift.org)
[![Source license](https://img.shields.io/badge/source-MIT-3fb950)](LICENSE)

**English** · [한국어](README.ko.md) · [日本語](README.ja.md)
</div>

DigiTokenBar is an unofficial, non-commercial Digimon fan adaptation of
[PokeTokenBar](https://github.com/chattymin/PokeTokenBar) by chattymin and its contributors.
Your existing Claude Code, Codex and other supported local coding-tool usage raises a
Digimon companion. Hatch eggs, choose branching evolutions, collect fusion partners,
and fill your Notebook through a black-and-cyan digital terminal interface.

> **Source code: MIT. Third-party artwork, text, trademarks and data: separate rights.**
> Third-party images are downloaded on demand and cached on the user's Mac, not bundled.
> Attribution is not redistribution
> permission; public binary distribution is not cleared. See [notices](NOTICE.md),
> [asset rights](THIRD_PARTY_NOTICES.md) and [validation status](docs/reference/distribution-validation.md).

## Preview

Third-party artwork screenshots and local review previews are omitted from this source distribution.

## How it works

1. **Code as usual.** Existing local usage records provide tokens; the app does not run model turns.
2. **Hatch.** Start from one of seven baby Digimon in the bundled 475-species catalog.
3. **Evolve.** Choose a direct ordinary evolution, or let the app randomly favor uncollected
   ordinary candidates when the gauge fills. Already registered ordinary forms can be revisited.
4. **Collect.** The Notebook tracks unique species, Time Stranger numbers, stages,
   official-profile excerpts and move names. Final training forms need a full final gauge.
5. **Unlock special evolution.** Fusion uses collected partners; item evolution consumes its
   designated item; daily-token evolution uses combined actual usage. An orange/yellow blinking
   alert opens all available results. Committing a special evolution registers its result without
   replacing the companion you are raising.
6. **Continue a special result.** If an uncollected ordinary branch remains, continue training it
   while parking one existing Digimon. Eggs cannot start new continuations. Only the active
   companion grows; the parked companion returns automatically when training completes.

## Features

- **Usage dashboard:** today, input/output/cache composition, cost and inherited provider-limit views.
- **475 Digimon:** remotely fetched static artwork and a Time Stranger-based graph with explicit app-rule overrides.
- **Branching collection:** uncollected-route priority, known intermediate free transit during continuation,
  and no repeated species within one realized training path.
- **Special evolution:** collection-based fusion, dedicated capsules, Digivice, X-Antibody A/S,
  unscaled daily-token gates and silhouette/binary-belt/reveal effects.
- **Shop and Bag:** Digi-Egg, Pendant, Digivice, antibodies and dedicated capsules. Tokens are virtual
  in-app currency; no purchases or real payments are involved.
- **Stable saves:** one parked Digimon, exact progress/selection/profile restoration, import/export,
  and backups for older save migrations.
- **Cyber interface:** black background, cyan circuitry/binary data, Notebook stages and a fan-made Digivice icon.

The graph and names are a versioned snapshot, not a continuously updated official encyclopedia.
Some inherited Pokémon-oriented internals remain for compatibility; they do not define Digimon lore.
Digimon illustrations are static; this version does not promise animated species sprites, shiny
variants, official combat statistics, or an accurate personality system.

## Install

Requires **macOS 14+ and an Apple Silicon Mac (M1 or later)**. You do not need
Xcode or a paid Apple developer account. Intel Macs must build from source;
an Intel release is not yet verified.

### Homebrew

With [Homebrew](https://brew.sh) installed, run:

```sh
brew install --cask choisiz/tap/digitokenbar
```

Homebrew checks the download automatically and removes only the installed app's
`com.apple.quarantine` attribute. This does not grant Apple notarization or disable
system-wide protection. Open **DigiTokenBar** from Applications.
To update, quit the app, then run `brew update` and `brew upgrade --cask choisiz/tap/digitokenbar`.

### Direct download

1. [Download the ZIP](https://github.com/Choisiz/DigiTokenBar/releases/download/v0.1.0/DigiTokenBar-0.1.0-macos-arm64.zip).
2. Extract it and drag **DigiTokenBar.app** into **Applications**.
3. Open **DigiTokenBar**. Its icon appears in the menu bar.

To update a direct installation, quit the app and replace it with the new download.
Both methods preserve your saved companion data. First image loading needs internet;
downloaded images are cached on your Mac.

### Direct download: first launch

The app is **ad-hoc signed, without Developer ID signing or Apple notarization**.
If macOS blocks a download you trust, follow Apple's
[Privacy & Security → Open Anyway instructions](https://support.apple.com/102445).
Managed Macs may disallow this exception. Do not disable system-wide protections.

<details>
<summary>Optional: manually verify a direct download</summary>

Download the matching `.sha256` file from [Releases](https://github.com/Choisiz/DigiTokenBar/releases)
and run this in the folder containing both files:

```sh
shasum -a 256 -c DigiTokenBar-0.1.0-macos-arm64.zip.sha256
```

Homebrew already performs this check for its installations.

</details>

## Build from source

Requires **macOS 14+**, Swift 6, and Apple developer tools. The local release candidate has
been tested on Apple Silicon only; Intel and a universal package are not currently verified.

```sh
git clone https://github.com/Choisiz/DigiTokenBar.git
cd DigiTokenBar
./scripts/build-digimon-app.sh
open build/DigiTokenBar.app
```

The build script defaults to an optimized release build. It assembles and ad-hoc signs the app
without installing it or terminating a running copy. Quit any older copy before opening another.
The Swift package/executable remains named `PokeTokenBar` internally for upstream compatibility;
the assembled application is **DigiTokenBar.app**.

This is not a Developer ID-signed or Apple-notarized distribution. An ad-hoc signature verifies
local integrity and does not imply Gatekeeper approval. Homebrew and ready-to-run ZIP installation are available above. There is no App Store listing
or in-app automatic updater.

To prepare a local candidate archive:

```sh
./scripts/package-digimon-app.sh
python3 scripts/verify-digimon-package.py build/distribution/DigiTokenBar-0.1.0-macos-arm64.zip --launch
```

This produces a versioned ZIP and SHA-256 checksum under `build/distribution/`. It does not
publish a GitHub Release, notarize the app or grant rights to bundled assets.
The verifier checks the extracted app and can start it with isolated save data.
Use `--parallel-launch` instead of `--launch` to validate an isolated temporary-ID copy
while leaving an existing app running. The verifier also rejects builder home paths
in the executable. Use the filename
produced by your build if its version or architecture differs.

## Usage and saves

Open the menu-bar egg/Digimon to see Home, Shop, Bag and Notebook. Choose language and growth
difficulty in Settings. Existing usage is baselined so it is not all granted as new growth on first use.

- Normal training: final form + full gauge → new egg, or restore an existing parked partner.
- Continuation: final form + full gauge → automatically restore the parked companion.
- One active + one parked Digimon maximum. Swapping preserves progress; parked Digimon earn no XP.
- Fusion ingredients stay collected; consumable evolution items are deducted once at commit.
- Daily gates combine actual providers, ignore Pendant XP, and do not scale with difficulty.
- Saves: `~/Library/Application Support/DigiTokenBar/`; exports use `.digitokenbar.save`.
- No automatic import or replacement of upstream PokeTokenBar saves; app identifier is `local.digitokenbar.app`.

See [evolution rules](docs/reference/digimon-evolution-methods.md),
[continuation rules](docs/reference/digimon-continue-training.md) and
[Korean-name mapping](docs/reference/digimon-korean-names.md).

## Privacy and network access

Usage is read from local tool records. The app does not upload those usage logs or prompts.
It inherits optional authenticated provider-limit requests and provider-status requests from
PokeTokenBar; it is not a fully offline application. Credentials used for optional limit features
are sent to their corresponding provider. Digimon and third-party item/guide/egg images are
fetched on demand from `external-artwork.json` and cached under
`~/Library/Application Support/DigiTokenBar/sprites/external-artwork-v1/`.
Capsules use the original background-bearing JPGs without background removal.
First display requires a network connection; downloaded images work offline. Generated X-Antibody
spheres, the project icon, catalog data, and profile excerpts remain bundled.
Upstream automatic update fetching is disabled.

Personal saves, credentials, build products and local coverage/crash logs are excluded from Git.
Never upload your Application Support directory or a personal export in an issue.

## Development and validation

With full Xcode selected:

```sh
swift test
```

The maintained test suite and `./scripts/test-gate.sh` verify production logic and
coverage. Local QA fixtures, preview generators, and agent instructions are not
part of this source distribution.
See the [validation report](docs/reference/distribution-validation.md) for actual results and limits.

## Credits and license

- **Foundation:** [PokeTokenBar](https://github.com/chattymin/PokeTokenBar), chattymin and upstream contributors.
- **Fan adaptation:** Choisiz; original MIT notices and upstream Git history retained.
- **Data and art sources:** DAPI, Digimon API, Grindosaur, official Digimon Encyclopedia,
  Wikimon and the credited fan artist; detailed per-file provenance in [third-party notices](THIRD_PARTY_NOTICES.md).

Digimon characters, names, designs and imagery belong to their respective rights holders,
including BANDAI, Akiyoshi Hongo, Toei Animation and Bandai Namco Entertainment. This project is
not affiliated with or endorsed by them. No ownership or redistribution permission for that
material is claimed. The independently drawn icon is fan art based on the Digivice design.

[MIT](LICENSE) applies to project source code; it does **not** relicense third-party material.
Non-commercial fan intent is not permission from a rights holder. For concerns or removal
requests, [contact the maintainer](https://github.com/Choisiz/DigiTokenBar/issues).
