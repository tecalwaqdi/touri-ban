import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
text = (ROOT / "lib/flutter_flow/internationalization.dart").read_text(encoding="utf-8")
driver_keys = {
    m.group(1).replace("\\'", "'")
    for m in re.finditer(r"'en': '((?:\\'|[^'])*)'", text)
    if m.group(1).strip()
}

for lang_path in sorted((ROOT / "assets/langs").glob("*.json")):
    if lang_path.stem in ("en", "ar"):
        continue
    data = json.loads(lang_path.read_text(encoding="utf-8"))
    untrans = [k for k in driver_keys if k in data and data[k] == k]
    print(f"{lang_path.name}: {len(untrans)} driver strings still English")
