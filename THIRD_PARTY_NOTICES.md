# Third-party notices and asset permissions

Reviewed: 2026-10-19. This is an attribution inventory, not a grant of rights or
legal advice. **Third-party assets are excluded from the MIT source-code license.**
No general Digimon artwork redistribution permission has been established.

| Material | Source / provenance | Rights and distribution status |
| --- | --- | --- |
| Application foundation | [PokeTokenBar](https://github.com/chattymin/PokeTokenBar), [MIT license](https://github.com/chattymin/PokeTokenBar/blob/main/LICENSE) | Original copyright and MIT terms retained in `LICENSE`; source modifications use MIT. |
| Species art and aliases | [DAPI](https://digi-api.com/), initial twelve images from [Digimon API](https://digimon-api.vercel.app/) / `digimon.shadowsmith.com` | API availability is not an artwork license. Per-species URLs are preserved in `time-stranger.json` and `sources.json`. Redistribution permission unverified. |
| Time Stranger numbers and graph | [Grindosaur](https://www.grindosaur.com/en/games/digimon-story-time-stranger/digimon) | Per-entry page and image URLs in `time-stranger.json`. Game graph is adapted with explicit app-rule overrides; no official partnership or exhaustive lore verification claimed. Database/image redistribution permission unverified. |
| Korean names, types, attributes, moves and short excerpts | [Official Digimon Encyclopedia](https://digimon.net/reference_ko/), per-profile links in `korean-names.json` and `species-info.json` | Official text remains third-party material. Short excerpts and attribution are not a permission grant. The [official portal](https://digimon.net/) prohibits unauthorized reuse of images, text and data; permission must be checked before public asset/binary distribution. |
| Digi-Egg art | [Official profile report #011](https://digimon.net/profile/report011/) | Original transparent PNG; redistribution permission unverified. |
| Digivice / Gennai | [Wikimon Digivice](https://wikimon.net/Digivice), [file page](https://wikimon.net/File:Digivice.png), [Gennai](https://wikimon.net/Gennai) | Hosting on a wiki does not establish an underlying artwork license. Redistribution permission unverified. |
| Pendant / Tag illustration | [Digimon Tag HD by jojogape](https://www.deviantart.com/jojogape/art/Digimon-Tag-HD-578170061) | Fan artist attribution retained. No redistribution permission verified; fan art can involve both artist and franchise rights. |
| Dedicated capsule illustrations | Wikimon Digimental source pages listed individually in `ui-sources.json` | Original background-bearing JPGs fetched at runtime; no capsule background removal. Original rights remain with their owners; usage permission unverified. |
| X-Antibody binary spheres | Project-generated cyan/red 0/1 sphere designs | Generated visual assets; no claim to Digimon names, marks or franchise rights. |
| Application icon | `AppIcon.svg`, independently drawn from the Adventure Digivice concept | New vector drawing; underlying Digivice design remains third-party intellectual property. Not an official logo or clearance. |
| Historical Pokémon screenshots and upstream examples | Preserved PokeTokenBar source/documentation history | Pokémon rights remain with Nintendo, Game Freak, Creatures and The Pokémon Company as applicable. No Pokémon rights are conveyed by MIT. |

## Detailed manifests

Under `Sources/PokeTokenBar/Resources/Digimon/`:

- `time-stranger.json`: all 475 local/game IDs, graph edges, DAPI mapping and source URLs.
- `sources.json`: initial twelve partner images.
- `ui-sources.json`: item/source pages, historical cutout provenance and original generation records.
- `external-artwork.json`: 489 runtime sources (including the artist-page resolver).
- `bundled-files.json`: allowlist enforced before app assembly and after ZIP extraction.
- `korean-names.json` / `species-info.json`: per-profile official source links.
- `evolution-rules.json`: app-selected evolution rules and supporting references.

Third-party image bytes are excluded from current source resources and new app packages.
The app fetches 475 species originals and 14 item/guide/egg originals at runtime, then
caches them on the user's Mac. The Pendant resolves the artist page's public `og:image`
address on a cache miss; signed image queries are not hardcoded in source. Dedicated
capsules use the source JPG, not the former locally edited transparent PNGs.

Generated X-Antibody spheres and the project icon remain bundled. Catalog/evolution
metadata and official profile excerpts are also still bundled; this image-only change
does not remove those materials or establish permission for their use. Runtime fetching
is a delivery mechanism, not a copyright license or clearance. Previously tracked
upstream Pokémon documentation/history is preserved. Local artwork previews, screenshots, QA files and agent instructions are
excluded from the current public source tree. Original upstream history is retained.
Published ZIPs use an ad-hoc signature without Developer ID/notarization; the
validation report explains the technical and rights limitations. No rights-holder
approval or legal clearance is claimed.

Source mirrors can have separate terms from the underlying rights holders.
Consult both before redistributing or repackaging their material. If a source page
cannot be reached, its license status stays unverified; absence of a notice is not
permission. The notices above should accompany any permitted distribution.
