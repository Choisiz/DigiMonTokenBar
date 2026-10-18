# Runtime artwork

The source and application package exclude downloaded third-party image files.
Generated X-Antibody A/S spheres and the project icon remain included, as do the
catalog, evolution rules and official profile excerpts. Their rights are separate
from the MIT source license; see [third-party notices](../../THIRD_PARTY_NOTICES.md).

`external-artwork.json` maps 475 species and 14 item/guide/egg originals. Capsule
images retain their original JPG backgrounds; no capsule background removal runs.
The Pendant resolves the original artist page's public image address on a cache
miss, rather than embedding a signed CDN URL in source.

## Download and cache

Images are fetched over HTTPS as needed. Successful image responses are validated
and stored atomically without changing their bytes. Simultaneous requests share
one download and decoded image cache. Source-addressed keys prevent old processed
images or Pokémon caches from replacing the new originals.

Cache directory: `~/Library/Application Support/DigiTokenBar/sprites/external-artwork-v1/`.
First display requires internet; previously downloaded images work offline. A
corrupt cache is replaced. Failed HTTP or HTML responses are not saved. Reopening
a view retries missing images; placeholders cover loading or unavailable sources.

Special scenes wait for their required art and offer Retry/Home when unavailable.
The bundled WebKit scene receives data URLs and cannot navigate to remote pages.
The approved visual shadow/binary/light effects do not rewrite the cached images.

Remote source availability and website formats can change. Runtime delivery and
source attribution do not establish rights-holder permission.

## Verification

The maintained tests cover first download, exact bytes, offline relaunch,
coalescing, corrupt caches, changed sources, HTTP/HTML failures, artist-page
resolution, disk write failure and legacy cache isolation. The resource allowlist
is checked by `scripts/check-digimon-artwork-distribution.py` before assembly and
by `scripts/verify-digimon-package.py` after ZIP extraction.
