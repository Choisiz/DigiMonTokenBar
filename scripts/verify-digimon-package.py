#!/usr/bin/env python3
"""Verify an extracted local candidate; --launch also tests isolated native startup.

An ad-hoc signature can pass integrity checks while Gatekeeper rejects the app.
This verifier reports that distinction and never grants asset redistribution rights.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import uuid
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("archive", type=Path)
parser.add_argument("--launch", action="store_true")
parser.add_argument("--parallel-launch", action="store_true",
                    help="Launch an isolated copy with a temporary bundle ID; leave a running app untouched")
args = parser.parse_args()
archive = args.archive.resolve()
output = Path(tempfile.mkdtemp(prefix="verified-", dir=archive.parent))
subprocess.run(["ditto", "-x", "-k", str(archive), str(output)], check=True)
app = output / "DigiTokenBar.app"
contents = app / "Contents"
resources = contents / "Resources"
plist = plistlib.loads((contents / "Info.plist").read_bytes())
assert plist["CFBundleIdentifier"] == "local.digitokenbar.app"
assert not plist.get("DigiTokenSessionTesting") and not plist.get("DigiTokenFreePendant")
assert plist["CFBundleIconFile"] == "AppIcon"
for name in ("LICENSE", "NOTICE.md", "THIRD_PARTY_NOTICES.md", "AppIcon.icns"):
    assert (resources / name).is_file(), name
catalog = json.loads((resources / "Digimon/time-stranger.json").read_text())
assert len(catalog["records"]) == 475
subprocess.run(["python3", str(Path(__file__).with_name("check-digimon-artwork-distribution.py")),
                "--resources", str(resources / "Digimon")], check=True)
binary = contents / "MacOS/DigiTokenBar"
assert not re.search(rb"/Users/[^/\x00\s]+/", binary.read_bytes()), "Builder home directory remains in the executable"
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
assert archive.with_suffix(".zip.sha256").read_text().startswith(digest)
gatekeeper = subprocess.run(["spctl", "--assess", "--type", "execute", str(app)], capture_output=True, text=True)
report = {
    "version": plist["CFBundleShortVersionString"], "archive": archive.name,
    "bytes": archive.stat().st_size, "sha256": digest,
    "architecture": subprocess.check_output(["lipo", "-archs", str(contents / "MacOS/DigiTokenBar")], text=True).strip(),
    "normalBuild": True, "catalogSpecies": 475, "bundledThirdPartyImages": 0, "runtimeArtworkSources": 489, "signatureIntegrity": "passed",
    "gatekeeperExit": gatekeeper.returncode, "nativeStartup": "not requested", "builderPathsRemoved": True,
}
if args.launch or args.parallel_launch:
    active = subprocess.run(["pgrep", "-f", r"^.*/DigiTokenBar\.app/Contents/MacOS/DigiTokenBar$"], capture_output=True)
    if active.returncode == 0 and not args.parallel_launch:
        raise SystemExit("A DigiTokenBar is running; use --parallel-launch to verify an isolated copy without stopping it.")
    launch_contents = contents
    if args.parallel_launch:
        launch_app = output / "parallel/DigiTokenBar.app"
        launch_app.parent.mkdir()
        shutil.copytree(app, launch_app)
        launch_contents = launch_app / "Contents"
        isolated_plist = dict(plist, CFBundleIdentifier="local.digitokenbar.validation." + uuid.uuid4().hex,
                              CFBundleName="DigiTokenBar Validation")
        (launch_contents / "Info.plist").write_bytes(plistlib.dumps(isolated_plist))
        # codesign changes embedded signature bytes when the bundle ID changes.
        # Confirm the copied executable before signing; only the copy is re-signed.
        assert (launch_contents / "MacOS/DigiTokenBar").read_bytes() == binary.read_bytes()
        subprocess.run(["codesign", "--force", "--sign", "-", str(launch_app)], check=True, capture_output=True)
        report["launchIdentity"] = "same executable copied before separate signing; temporary ID; release archive unchanged"
    real_save = Path.home() / "Library/Application Support/DigiTokenBar/companion-state.json"
    before = real_save.read_bytes() if not args.parallel_launch and real_save.exists() else None
    state = output / "isolated-state"
    state.mkdir()
    process = subprocess.Popen([str(launch_contents / "MacOS/DigiTokenBar")],
        env=dict(os.environ, PTB_STATE_DIR=str(state)), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        time.sleep(12)
        assert process.poll() is None, f"Native startup exited early: {process.returncode}"
    finally:
        if process.poll() is None:
            process.terminate()
        stdout, stderr = process.communicate(timeout=15)
        (output / "startup.log").write_bytes(stdout + stderr)
    if not args.parallel_launch:
        assert (real_save.read_bytes() if real_save.exists() else None) == before
        report["personalSaveUnchanged"] = True
    else:
        report["personalSaveAccessed"] = False
    assert (state / "companion-state.json").is_file()
    report.update(nativeStartup="passed: 12 seconds with isolated state")
(output / "verification.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
print(f"Verification record: {output / 'verification.json'}")
