# Missing Dynamic Translations

Content that still depends on admin/Firestore multi-locale maps or Google place names.

| Source | Field pattern | Action |
|--------|---------------|--------|
| Landmarks / places | `names_i18n.{ar,en,ru,ky}` | Ensure admin fills all four; client already prefers selected locale |
| Regions / villages | `osf_i18n` / geo i18n helpers | Same |
| Admin push composer | Free-text title/body | Prefer notification **codes** + templates; avoid typing EN-only |
| Order `halh_text` legacy | Arabic strings | Keep writing for driver compatibility; **display** via BookingStatusLocalizer; prefer `status_code` |
| Google Places results | Place/street names | Do not invent translations; labels stay localized |
| Map tiles language | SDK / OS locale | May require app restart after language change; UI chrome is localized |

When a Firestore i18n map lacks the user language, show a generic localized message and log the missing key for ops — do not silently show English inside ru/ky.
