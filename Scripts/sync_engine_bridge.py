"""Update the native adapter in the bundled HTML without touching upstream algorithms."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
path=root/'TCONMaker/Resources/Engine/engine.html'
html=path.read_text()
start=html.index('// Native adapter. Original rendering/model functions above are preserved.')
end=html.index('window.__idphoto={items,S,get modelOK(){return modelOK}};',start)
bridge=(root/'Scripts/native-bridge.js').read_text().rstrip()+'\n'
updated=html[:start]+bridge+html[end:]
if '--check' in sys.argv:
    if html!=updated:raise SystemExit('Native adapter differs; run python3 Scripts/sync_engine_bridge.py')
    print('Native adapter is synchronized.')
else:path.write_text(updated)
