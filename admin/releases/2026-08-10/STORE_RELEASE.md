# Store Release Pack — 2026-08-10 (wallet + accept fixes)

## Apps

| App | Bundle / App ID | Version |
|-----|-----------------|---------|
| Customer (`ara_oatan_app`) | iOS `com.mycompany.araoatanapp2` · Android `com.mycompany.araoatanapp` | **9.1.22+30** |
| Driver (`mndob-main`) | iOS `com.mycompany.mndob3` · Android `com.mycompany.mndob2` | **11.1.2+14** |

Display name (driver): **Touri Taxi Driver**  
Team: `7XPP94HATF`

## Artifact status

| Artifact | Status | Path |
|----------|--------|------|
| Customer App Store IPA | **Ready + uploaded** | `admin/releases/2026-08-10/customer/Touri Taxi.ipa` |
| Customer ASC upload | **Succeeded** | Delivery UUID `f9c4d82c-21f5-4087-af80-56b13964cfc4` |
| Driver App Store IPA | **Ready + uploaded** | `admin/releases/2026-08-10/driver/MNDOB.ipa` |
| Driver ASC upload | **Succeeded** | Delivery UUID `fe554489-ae5a-4f3d-b306-039b1162f20d` |
| Driver / Customer Play AAB | **Blocked — upload keystore** | Android SDK+JDK ready; need `key.properties` + `.jks` |
| Render payments | **Live** | https://touri-ban.onrender.com |

## Notes

- Driver marketing version bumped `2.0.6` → `11.1.2` (ASC required > approved `11.1.1`).
- ImageNotification extension version aligned to `11.1.2` / `14`.
- Non-blocking warning: MinimumOSVersion 14.0 (required ≥15.0 from Spring 2027).
