#!/usr/bin/env python3
"""Assemble only reviewed public landing-page assets; never copy user/build data."""
from pathlib import Path
import argparse,re,shutil
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--output',type=Path,default=ROOT/'build/pages-preview')
args=parser.parse_args()
out=args.output.resolve()
if out==ROOT or ROOT not in out.parents:
 raise SystemExit('Output must be a dedicated directory inside this checkout.')
out.mkdir(parents=True,exist_ok=True)
version=re.search(r'<key>CFBundleShortVersionString</key><string>([0-9.]+)</string>',(ROOT/'scripts/build-digimon-app.sh').read_text())[1]
for name in ['index.html','styles.css','app.js']:
 text=(ROOT/'site'/name).read_text().replace('__APP_VERSION__',version)
 (out/name).write_text(text)
assets=out/'assets';assets.mkdir(exist_ok=True)
shutil.copyfile(ROOT/'Sources/PokeTokenBar/Resources/Digimon/AppIcon.png',assets/'app-icon.png')
screens=assets/'screenshots';screens.mkdir(exist_ok=True)
for name in ['home','notebook','detail','fusion']:
 shutil.copyfile(ROOT/f'assets/readme-screenshots/{name}.png',screens/f'{name}.png')
shutil.copyfile(ROOT/'site/fusion-demo.mp4',assets/'fusion-demo.mp4')
(out/'.nojekyll').write_text('')
expected={'index.html','app.js','styles.css','.nojekyll','assets/app-icon.png','assets/fusion-demo.mp4'} | {f'assets/screenshots/{n}.png' for n in ['home','notebook','detail','fusion']}
actual={str(p.relative_to(out)) for p in out.rglob('*') if p.is_file()}
assert actual==expected, f'Unexpected public output files: {actual ^ expected}'
assert not any(p.is_symlink() for p in out.rglob('*')), 'Symlinks cannot enter the public artifact'
print(f'Built public site v{version}: {out}')
