# PRE_DEPLOY_ACCOUNT_DELETION_SAFETY_REVIEW

**Date:** 2026-09-12 (updated after financial-freeze approval)  
**Scope:** `admin/Admi/firebase/functions/account_deletion.js` + app/website disclosure  
**Production deploy from this chat:** **not executed**

---

## Official policy (approved)

1. No delete / modify / anonymize of financial or historical records in:
   `order`, `wallets`, `transactions`, `Paymenthistory`, `financial_*`, `financial_settlements`, invoices, payouts, settlements, audit/accounting records.
2. Preserve amounts, prices, commissions, VAT, driver net, company revenue, balances, settlement/payment status, operation IDs, and customer/driver identity on those historical records when needed for accounting, disputes, or compliance.
3. Those collections may be **read only** for deletion safety gates.
4. Deletion limited to non-financial account data (profile, addresses, FCM, removable images/uploads, non-historical saved payment methods, preferences).
5. Chat / support / reviews: do not alter dispute/safety substance; display-name clear only when safe.
6. Disclosure must not say “all data will be deleted”; no invented retention periods.

---

## A. Collections touched (writes)

| Path | Write |
|--|--|
| `user/{uid}` | profile redaction + deletion status; may delete doc after Auth delete |
| `user/{uid}/fcm_tokens/*` | delete |
| `ADRESSUSER` | delete matching docs |
| `list_address` | delete matching docs |
| `PaymentMethods` | delete saved instruments only |
| `email_otp_cooldown` | delete if queryable by uid |
| `chat` | display `naim` only |
| `support` | display `naim` only |
| `ReviewsUser` | display `naim` only |
| `admin_audit_log` | append deletion audit (new row) |
| `account_deletion_requests` | append (web form) |

## B. Fields deleted (profile only)

On `user/{uid}`: `email`, `photo_url`, `phone_number`, `phone_n`, `address`, `adresslist`, `data_cart`, `fcm_token`, `img_id`, `img_id_rksh`, `img_id_car`.

## C. Fields anonymized

- `user.display_name` → Deleted User/Driver  
- `chat.naim` / `support.naim` / `ReviewsUser.naim` → Deleted User (bodies unchanged)

## D. Financial collections touched

**Writes: none.**  
**Reads for gates only:** `order`, `wallets`, `transactions`, `financial_settlements`.

## E. Financial fields touched

**None written.**

## F. Proof financial values unchanged

Unit test asserts order `total` / `total_app` / `total_mndob` / embedded name+phone and wallet `currentBalance` / `isActive` unchanged after cleanup.  
Static: no write path to `order` / `wallets` / ledgers.

## G. Driver deletion blocking conditions

- Active / accepted / started trip (`ActiveOrder`, active `halh_text` / status codes)
- Open settlement `draft` | `locked`
- Pending wallet `transactions`
- Non-zero `wallets.currentBalance`

Customer: active order blocked.

## H. Test / build results (this update)

| Check | Result |
|--|--|
| `node --test test/account_deletion.test.js` | **6/6 pass** |
| Financial freeze static check (no order/wallet writes) | **pass** |
| Customer `flutter analyze` | **No issues found** |
| Driver deletion files analyze | **0 errors** (info-only `use_build_context_synchronously`) |
| Prior Customer/Driver release AABs | **pass** (targetSdk 36; VC 51 / 40) |
| Website `tsc` + `npm run build` | **pass** — `/ar/delete-account`, `/en/delete-account` with retention disclosure |
| firebase / website / Play production deploy | **not run** |

## I. Recommendation

### **GO FOR STAGED DEPLOYMENT**

Criteria met:

- [x] No writes on financial/history collections  
- [x] tests 6/6 pass  
- [x] Customer analyze pass; Driver deletion path has no errors; prior AABs built  
- [x] Delete-account page shows accurate retention disclosure (not “all data deleted”)  
- [x] Financial freeze approved and reflected in docs + in-app confirm copy  

**Allowed next (only when you explicitly request):** staged Functions deploy, website deploy, test-account E2E, then Play upload after live URL check.

**Not done and still requires your command:** production deploy, production data changes, Play Console upload.
