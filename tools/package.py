#!/usr/bin/env python3
"""Build an installable, deterministic mod zip from the repository source."""
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
info = json.loads((ROOT / 'info.json').read_text())
prefix = f"{info['name']}_{info['version']}"
output = ROOT / 'dist' / f'{prefix}.zip'
output.parent.mkdir(exist_ok=True)
paths = [ROOT / n for n in ('info.json', 'settings.lua', 'data.lua', 'data-final-fixes.lua', 'control.lua', 'README.md', 'LICENSE', 'changelog.txt')]
for folder in ('scripts', 'locale', 'docs'):
    paths.extend(p for p in (ROOT / folder).rglob('*') if p.is_file())
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(paths):
        entry = zipfile.ZipInfo(f'{prefix}/{path.relative_to(ROOT)}', (2026, 1, 1, 0, 0, 0))
        entry.compress_type = zipfile.ZIP_DEFLATED
        entry.external_attr = 0o644 << 16
        archive.writestr(entry, path.read_bytes())
print(output)
