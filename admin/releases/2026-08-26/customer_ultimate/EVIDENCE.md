# Customer Ultimate — Step evidence (2026-08-26)

## STEP 1 Git
See STEP01_GIT.txt — mixed dirty tree; only Customer profile/payment + payment-api + firestore rules touched for this closure.

## STEP 2 Version
PUBSPEC was 9.1.24+35 → bumped to **9.1.24+36**
Bundle: com.mycompany.araoatanapp2
ImageNotification CURRENT_PROJECT_VERSION synced to 36

## ROOT CAUSE SUMMARY

### FAILURE A — Browser first
ROOT_CAUSE_BROWSER_FIRST = `MOBILE_PAYMENT_MODE` defaulted to `hpp` + `TouryPaymentExperienceService.forceHostedPaymentPage` short-circuit + `OPEN_PAYMENT_IN_EXTERNAL_BROWSER=true`
FIXED in source: default `MOBILE_PAYMENT_MODE=sdk`

### FAILURE B — N-Genius order retrieval
HPP_RETRIEVAL_ROOT_CAUSE = stale HPP reuse without TTL (sessions hours old still returned same paypage code)
FIXED in local payment-api (15m TTL + forceRefreshHpp + client unique retry key)
PRODUCTION_NATIVE_FIELDS_IN_SESSIONS = MISSING → Render not yet deployed with SDK payload

### FAILURE C/D/E — Phone/photo + Storage message
ROOT_CAUSE = Firestore `user` update OR-chain exceeded 1000-expression limit → all owner profile writes denied; Storage upload often OK; Firestore photo_url/phone update failed; uploadErrorMessage mapped Firestore permission-denied → Storage wording
FIXED: split allow update/create statements; deployed Firestore rules; profile save writes only safe keys; touryProfileErrorMessage separates Storage vs Firestore

## DEPLOYMENTS
FIRESTORE_RULES_DEPLOYED = true (earlier this session)
STORAGE_RULES_DEPLOYED = already up to date (re-released)
PAYMENT_API_RENDER_DEPLOYED = false → OWNER_ACTION_REQUIRED

## PHYSICAL
No iPhone USB/wireless detected at closure time → PHYSICAL_DEVICE_REQUIRED
