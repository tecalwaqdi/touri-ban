# Touri Geo Sources

## Priority order

1. Government / official tourism & ISO references  
2. Open databases: Wikidata, OpenStreetMap, UNESCO  
3. Wikimedia Commons (licensed images only)  
4. Google Places / Geocoding / Routes — **verification only**, keys via secrets/env, never client-side secrets; photos only per Google ToS (no unlawful storage)

## Pilot sources used (Makkah Region)

| Entity type | Providers | Notes |
|---|---|---|
| Country SA | ISO 3166, Wikidata Q851 | ISO2 SA / ISO3 SAU / SAR |
| Region | ISO 3166-2 `SA-02`, MoI naming | Administrative region |
| Cities | Wikidata (Makkah Q5806, Jeddah Q374365, Taif Q244074) | Mapped to `villages` |
| Landmarks | Wikidata P625 + labels + Commons P18 | Dual-source preferred |
| Images | Wikimedia Commons extmetadata | PD / CC BY / CC BY-SA only |

## Explicitly rejected for pilot Storage upload

- Google Images scrape results  
- Unlicensed web photos  
- Google Places photo binary storage without ToS-compliant pipeline  
- AI-generated “fake” landmarks or coordinates

## Rate limiting

Wikidata/Commons queried at ~1 req/sec with identifiable User-Agent.  
Checkpoints cached under `firebase/tools/geo_import/checkpoints/`.
