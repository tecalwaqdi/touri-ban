# Driver iOS App Store Audit

**Date:** 2026-08-06  
**App path:** `admin/mndob-main`  
**Access:** No App Store Connect API in this environment — Connect checklist is manual.

## Project facts (from repo)

| Item | Customer (`ara_oatan_app`) | Driver (`mndob-main`) |
|------|----------------------------|------------------------|
| Bundle ID | `com.mycompany.araoatanapp2` | `com.mycompany.mndob3` |
| CFBundleDisplayName | `Touri Taxi` | `توري تأكسي - للمندوب` (Arabic only) |
| CFBundleName | `Touri Taxi` | `MNDOB` |
| CFBundleLocalizations | en, ar, ru, ky, … | **en, ar only** (missing ru/ky) |
| Docs package note | SoT mentions `mndob2` | Project uses **`mndob3`** — verify Connect matches **mndob3** |

## Likely causes (ordered)

1. **ASO / naming:** Customer English name is `Touri Taxi`. Driver store listing may still be Arabic-only or lack English name/keywords → search for “Touri Taxi” surfaces customer only.
2. **Availability:** App not released in Kyrgyzstan / not Ready for Sale.
3. **TestFlight-only** build never promoted to App Store.
4. **Bundle ID mismatch** if Connect app was created as `mndob2` but binary is `mndob3`.
5. **Indexing delay** after first release.
6. **Removed from Sale** or region-restricted.

Flutter code alone **cannot** fix App Store search ranking.

## Recommended Store metadata (proposal — do not apply without approval)

| Field | Suggestion |
|-------|------------|
| Name (EN) | **Touri Taxi Driver** or **Touri Taxi Captain** |
| Name (RU) | Touri Taxi Водитель |
| Subtitle (EN) | Driver app for Touri Taxi |
| Keywords | taxi, driver, captain, kyrgyzstan, bishkek, tour |
| Differentiate | Never use identical English name as customer app |

## App Store Connect checklist

1. [ ] Separate app record exists for driver
2. [ ] Bundle ID = `com.mycompany.mndob3` (exact)
3. [ ] Status Ready for Distribution (not Draft / Removed)
4. [ ] Available in Kyrgyzstan (+ target countries)
5. [ ] Version live on App Store (not TestFlight only)
6. [ ] English localization filled (name, subtitle, description, keywords)
7. [ ] Russian localization filled
8. [ ] Kyrgyz if supported
9. [ ] Primary category appropriate (Travel / Navigation)
10. [ ] Privacy nutrition labels complete
11. [ ] Age rating set
12. [ ] Pricing / availability configured
13. [ ] Screenshots for required sizes
14. [ ] No name collision with customer “Touri Taxi”

## In-repo follow-ups (optional, not Store publish)

- Set English `CFBundleDisplayName` e.g. `Touri Taxi Driver` (requires rebuild).
- Add `ru` / `ky` to `CFBundleLocalizations`.
- Align documentation that still says `mndob2`.

## Verdict

**Most probable:** English App Store metadata for the driver app is missing or not distinct, so search “Touri Taxi” returns the customer app. **Next step:** App Store Connect owner verifies listing status, English name, and Bundle ID `com.mycompany.mndob3`.
