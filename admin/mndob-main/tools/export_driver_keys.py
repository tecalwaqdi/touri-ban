import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
text = (ROOT / "lib/flutter_flow/internationalization.dart").read_text(encoding="utf-8")
keys = sorted(
    {
        m.group(1).replace("\\'", "'")
        for m in re.finditer(r"'en': '((?:\\'|[^'])*)'", text)
        if m.group(1).strip()
    }
)
out = ROOT / "tools" / "driver_en_keys.json"
out.write_text(json.dumps(keys, ensure_ascii=False, indent=2), encoding="utf-8")
print(len(keys), "keys ->", out)
