#!/usr/bin/env python3
"""Fail if downloaded images enter the source/bundle resource directory.

Use --resources <path> to audit an assembled app as well. The allowlist contains
metadata, local scene HTML, generated antibody spheres, and the project icon only.
This gate does not claim that third-party text, data, marks, or upstream history are cleared.
"""
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--resources', type=Path, default=Path(__file__).resolve().parents[1] / 'Sources/PokeTokenBar/Resources/Digimon')
args = parser.parse_args()
root = args.resources
allowed = set(json.loads((root / 'bundled-files.json').read_text())) | {'bundled-files.json'}
actual = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file()}
assert actual == allowed, f'Unexpected resource files: {actual - allowed}; missing: {allowed - actual}'
images = {p for p in actual if Path(p).suffix.lower() in {'.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.icns'}}
assert images == {'AppIcon.png', 'AppIcon.svg', 'AppIcon.icns', 'x-antibody-a.png', 'x-antibody-s.png'}, images
sources = json.loads((root / 'external-artwork.json').read_text())
catalog = json.loads((root / 'time-stranger.json').read_text())['records']
assert len(catalog) == 475
assert len(sources) == 489
assert all(sources[f"species-{r['id']}"]['url'] == r['image'] for r in catalog)
assert all(x['url'].startswith('https://') and 'token=' not in x['url'] for x in sources.values())
assert all(sources[k]['url'].endswith('.jpg') for k in sources if k.startswith('capsule-'))
print(f'PASS: {len(actual)} bundled files; 489 external originals mapped; no downloaded artwork bundled')
