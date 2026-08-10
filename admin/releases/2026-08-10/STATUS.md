# Store + Render status — 2026-08-10

## Render (payment) — LIVE, do not wait on Firebase

- **URL:** https://touri-ban.onrender.com
- **Health:** `ok: true`, `ngeniusEnv: production`, keys/outlet/webhook/firebase configured
- Customer store builds already use:
  - `PAYMENT_BACKEND=external_api`
  - `PAYMENT_API_BASE_URL=https://touri-ban.onrender.com`
  - cash fallback + external browser
- Firebase Functions cutover is **optional later** — not a store blocker

## App Store / Play

| App | Version | App Store IPA | Play AAB |
|-----|---------|---------------|----------|
| Driver | 2.0.5+12 | **Ready** `releases/2026-08-10/driver/MNDOB.ipa` | Needs Android SDK + upload keystore |
| Customer | 9.1.21+29 | Needs Xcode Apple ID (Accounts) then `build_customer_ipa.sh` | Needs Android SDK + upload keystore |

## Unblock remaining builds (this Mac)

1. **Xcode → Settings → Accounts** → sign in team `7XPP94HATF` → Download profiles → `admin/scripts/build_customer_ipa.sh`
2. Install Android SDK + place `android/key.properties` + `.jks` for both apps → `admin/scripts/build_store_releases.sh`
