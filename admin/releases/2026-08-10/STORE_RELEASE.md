# Store Release Pack — 2026-08-10 (post-fixes)

## Render payment — LIVE (not blocked on Firebase)

| Item | Value |
|------|--------|
| URL | `https://touri-ban.onrender.com` |
| Health | `ok: true`, `ngeniusEnv: production` |
| Client defines | `PAYMENT_BACKEND=external_api` + `PAYMENT_API_BASE_URL=https://touri-ban.onrender.com` |

Firebase Functions migration is **optional later**. Store releases must not wait on it.

---

## Apps

| App | Bundle / App ID | Version |
|-----|-----------------|---------|
| Customer (`ara_oatan_app`) | iOS `com.mycompany.araoatanapp2` · Android `com.mycompany.araoatanapp` | **9.1.21+29** |
| Driver (`mndob-main`) | iOS `com.mycompany.mndob3` · Android `com.mycompany.mndob2` | **2.0.5+12** |

Team: `7XPP94HATF`

---

## Artifact status

| Artifact | Status | Path / action |
|----------|--------|----------------|
| Render API | **Live** | https://touri-ban.onrender.com/health |
| Driver App Store IPA | **Ready** | `admin/releases/2026-08-10/driver/MNDOB.ipa` |
| Customer App Store IPA | **Needs Xcode Apple ID** | Xcode → Settings → Accounts → team login → `admin/scripts/build_customer_ipa.sh` |
| Driver Play AAB | **Needs SDK + keystore** | `mndob-main/android/key.properties` + `.jks` |
| Customer Play AAB | **Needs SDK + keystore** | `ara_oatan_app/android/key.properties` + `.jks` |

---

## Included in builds

- Driver: Firestore assigned-driver reads, order-details layout fix, chat overflow fix
- Customer: Render payments + cash fallback + external browser
- Production APNs

---

## Finish in ~5 minutes (this Mac)

### 1) Customer IPA
1. Open **Xcode → Settings → Accounts**
2. Sign in Apple ID for team `7XPP94HATF`
3. Download Manual Profiles
4. `admin/scripts/build_customer_ipa.sh`

### 2) Play AABs
1. Install Android SDK → `flutter config --android-sdk ~/Library/Android/sdk`
2. Place upload keystores + `key.properties` (same keys as previous Play uploads)
3. `admin/scripts/build_store_releases.sh`

Customer dart-defines (already in scripts):
```
ENABLE_ONLINE_PAYMENT=true
PAYMENT_BACKEND=external_api
PAYMENT_API_BASE_URL=https://touri-ban.onrender.com
OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true
TOURY_CLIENT_CASH_FALLBACK=true
```
