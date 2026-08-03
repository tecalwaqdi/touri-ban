# Kyrgyzstan regions & landmarks (2026-07-19)

## Published to Firebase `tutorial-multi-language-70gx4j`

### Regions (`cities` collection) — 9
| ID | Arabic | English | Kyrgyz |
|----|--------|---------|--------|
| `kg-bishkek` | مدينة بيشكيك | Bishkek City | Бишкек шаары |
| `kg-chuy` | إقليم تشوي | Chuy Region | Чүй облусу |
| `kg-issyk-kul` | إقليم إيسيك كول | Issyk-Kul Region | Ысык-Көл облусу |
| `kg-naryn` | إقليم نارين | Naryn Region | Нарын облусу |
| `kg-talas` | إقليم تالاس | Talas Region | Талас облусу |
| `kg-jalal-abad` | إقليم جلال آباد | Jalal-Abad Region | Жалал-Абад облусу |
| `kg-osh` | إقليم أوش | Osh Region | Ош облусу |
| `kg-osh-city` | مدينة أوش | Osh City | Ош шаары |
| `kg-batken` | إقليم باتكين | Batken Region | Баткен облусу |

### Villages / routes (`villages`)
- `city_bishkek`, `city_osh`
- `kg-*-main` for each oblast

### Landmarks (`mkan`)
- **180** curated landmarks published (20 × 9)
- Each has `names_i18n` for **ar / en / ru / ky**
- Linked via `id_cit` → region, `id_vill` → village, `Rev_dolh` → `countries/kyrgyzstan`
- Verified active counts: each village ≥ 20 (Chuy / Bishkek slightly higher due to earlier curated docs)

## Scripts
```bash
cd admin/Admi/firebase/scripts
node seed_kyrgyzstan_full_client.js --dry-run
node seed_kyrgyzstan_full_client.js --apply
```

Data: `kyrgyzstan_landmarks_20.json`  
Report: `kyrgyzstan_seed_report.json`
