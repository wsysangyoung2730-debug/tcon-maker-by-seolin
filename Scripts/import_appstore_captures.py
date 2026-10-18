"""Preserve named XCTest PNG attachments and record their origin without changing pixels."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import struct

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('attachments', type=Path)
parser.add_argument('--device', required=True, choices=['iPhone-Large-1320x2868', 'iPad-13-2064x2752'])
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
out = root / 'Design/AppStore/Captures/v1.0.2'
folder = out / 'ko-KR' / args.device
folder.mkdir(parents=True, exist_ok=True)
manifest = json.loads((args.attachments / 'manifest.json').read_text())
seen = set()
for test in manifest:
    for attachment in test['attachments']:
        name = attachment['suggestedHumanReadableName']
        match = re.match(r'store-(\d{2}-[a-z-]+)', name)
        if not match or 'landscape' in match[1]:
            continue
        assert not attachment['isAssociatedWithFailure'], 'Cannot publish failed-test captures'
        source = args.attachments / attachment['exportedFileName']
        data = source.read_bytes()
        assert data[:8] == b'\x89PNG\r\n\x1a\n', 'Expected original PNG'
        width, height = struct.unpack('>II', data[16:24])
        expected = (2064, 2752) if args.device.startswith('iPad') else (1320, 2868)
        assert (width, height) == expected, (name, width, height)
        dest = folder / (match[1] + '.png')
        assert dest.name not in seen, 'Duplicate named capture'
        seen.add(dest.name)
        shutil.copy2(source, dest)
        assert dest.read_bytes() == data
required = {f'{i:02}-{name}.png' for i, name in enumerate(['home', 'folders', 'editor', 'background', 'selection', 'export', 'settings', 'home-actions'], start=1)}
assert required <= seen, 'Incomplete capture set: ' + str(required - seen)
entries = []
for p in sorted((out / 'ko-KR').rglob('*.png')):
    data = p.read_bytes()
    width, height = struct.unpack('>II', data[16:24])
    entries.append({'file': str(p.relative_to(out)), 'appVersion': '1.0.2', 'build': '4', 'width': width, 'height': height, 'sha256': hashlib.sha256(data).hexdigest()})
(out / 'manifest.json').write_text(json.dumps(entries, ensure_ascii=False, indent=2) + '\n')
cards = ''.join(f'<a href="{e["file"]}"><img src="{e["file"]}" loading="lazy"><span>{e["file"]}</span></a>' for e in entries)
(out / 'index.html').write_text('<!doctype html><html lang="ko"><meta charset="utf-8"><title>TCON 1.0.2 captures</title><style>body{font-family:sans-serif;margin:32px;background:#eef1fc;color:#1b34a8}main{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:24px}a{display:block;font-size:12px;overflow-wrap:anywhere}img{width:100%;display:block}span{display:block;margin-top:8px}</style><h1>TCON Maker 1.0.2 (4)</h1><p>Original app captures / iPhone and iPad</p><main>' + cards + '</main></html>')
print(f'Preserved {len(seen)} original captures for {args.device}')
