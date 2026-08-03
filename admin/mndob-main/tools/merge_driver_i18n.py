import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADMIN = ROOT.parent / "ara_oatan_app"
INTL = ROOT / "lib/flutter_flow/internationalization.dart"
LANG_DIR = ROOT / "assets/langs"

text = INTL.read_text(encoding="utf-8")
blocks = re.findall(
    r"'([a-z0-9]+)':\s*\{([^}]+)\}",
    text,
    flags=re.IGNORECASE,
)

pairs: dict[str, dict[str, str]] = {}
for _key, body in blocks:
    en = re.search(r"'en': '((?:\\'|[^'])*)'", body)
    ar = re.search(r"'ar': '((?:\\'|[^'])*)'", body)
    if not en:
        continue
    en_val = en.group(1).replace("\\'", "'")
    ar_val = ar.group(1).replace("\\'", "'") if ar else en_val
    if en_val.strip():
        pairs[en_val] = {"en": en_val, "ar": ar_val}

lang_files = list(LANG_DIR.glob("*.json"))
client_lang_dir = ADMIN / "assets/langs"

for lang_path in lang_files:
    data = json.loads(lang_path.read_text(encoding="utf-8"))
    client_data: dict[str, str] = {}
    client_path = client_lang_dir / lang_path.name
    if client_path.exists():
        client_data = json.loads(client_path.read_text(encoding="utf-8"))

    is_ar = lang_path.stem == "ar"
    added = 0
    for en_val, langs in pairs.items():
        if en_val in data:
            continue
        if is_ar:
            data[en_val] = langs["ar"]
        elif lang_path.stem == "en":
            data[en_val] = langs["en"]
        elif en_val in client_data:
            data[en_val] = client_data[en_val]
        else:
            data[en_val] = langs["en"]
        added += 1

    lang_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"{lang_path.name}: added {added}, total {len(data)}")

print(f"merged {len(pairs)} driver strings")
