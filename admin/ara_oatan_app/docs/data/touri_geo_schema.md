# Touri Geo Schema (ideal ↔ Firestore)

## Ideal landmark fields (import package)

See pilot JSON/JS objects under `firebase/tools/geo_import/datasets/pilots/`.

Key ideal fields: `id`, `slug`, `wikidataId`, `osmId`, multilingual `names` / `shortDescriptions`, `location`, `images[]` with license metadata, `sources[]`, `verification`.

## Firestore write mapping (preview only)

| Ideal | `mkan` field |
|---|---|
| names.ar | `naim` |
| names.* | `names_i18n` |
| shortDescriptions.ar | `osf` |
| shortDescriptions.* | `osf_i18n` |
| location | `Location` |
| region | `id_cit` → `cities/{region}` |
| city | `id_vill` → `villages/{city}` |
| country | `Rev_dolh` → `countries/{id}` |
| category | `tsnef` |
| commons image ref | `img1` as `commons://FileName` until Storage pipeline approved |
| verification | `verification_status`, `verification_confidence`, `acctev` |

Languages required in content maps: **ar, en, ru, ky, uz**.

## Vehicle catalog

Deferred to later phase after geo pilot approval. Existing `type_car` + Admin `names_i18n` remain.
