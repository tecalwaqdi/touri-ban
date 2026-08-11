# Kyrgyzstan QA — Final Report

**Date:** 2026-08-06  
**Deployed:** Nothing (no Firebase, no stores)

---

## Root causes

| Issue | Root cause | Fix |
|-------|------------|-----|
| Cancel permission error | First cancel write omitted `status_code=cancelled` required by rules | Single merge write with `status_code` + legacy fields |
| Mixed AR/EN error | Hardcoded Arabic + raw `FirebaseException.message` | Translation keys only |
| English Cancel in RU | FF map `hjqgpu0l.ru` was English; button used FF | Fixed map + `.tr('Cancel Order')` |
| ر.س on KG order | Hardcoded `currency: 'ر.س'` in order details; create stored `SAR` | `TouryCurrency` + create fields from country |
| Driver App Store | Metadata / Connect — not code | Audit doc only |
| Driver auth | Partially supported (+996 exists); live blockers = deploy/device | Notes + MASTER_BLOCKERS |

---

## Acceptance vs status

| Criterion | Status |
|-----------|--------|
| Cancel without permission error (after rebuild + same rules) | **Code fixed** — needs device QA |
| No raw Firebase messages on cancel | **Fixed** |
| Cancel button localized ru/ky | **Fixed** |
| KGS/сом display (new orders + session) | **Fixed** |
| currency_code on new cash creates | **Fixed** (client; CF when deployed) |
| Admin currency catalog UI | **Not done** (plan only) |
| Wallet multi-currency split | **Not done** (plan only) |
| Driver full auth device matrix | **Needs device** |
| App Store driver discoverability | **Needs Connect** |
| flutter analyze on touched files | **Clean** |
| Unit tests currency/cancel | **4 passed** |

---

## Commands run

```bash
cd admin/ara_oatan_app
flutter analyze lib/core/toury_customer_order_actions.dart \
  lib/core/toury_currency.dart lib/core/toury_booking_service.dart \
  lib/order/tfasel_order/tfasel_order_widget.dart
# No issues found

flutter test test/core/toury_currency_cancel_test.dart
# All tests passed! (4)
```

Full three-app `flutter test` / emulator rules suite: **not fully re-run** in this pass (time); focused regression above.

---

## External actions required

1. **Firebase rules deploy** (optional for cancel — client now matches existing rule; deploy to pick up `cancelled_by_customer` alias + any mirror sync). Source: `admin/ara_oatan_app/firebase`.
2. **Firebase functions deploy** when Blaze available — for server cash create currency.
3. **Rebuild / redistribute customer app** so cancel + currency UI ship.
4. **App Store Connect** — English name “Touri Taxi Driver”, Bundle `com.mycompany.mndob3`, KG availability.
5. **Device QA** in KG: create cash → cancel → confirm driver pool hides order; currency shows сом/KGS.
6. **Currency dry-run** with real SA when ready — do not apply blindly.

## Rollback

Revert the listed Dart/rules/function commits; additive Firestore fields can remain.

## Remaining risks

- Old orders with `currency: SAR` may still show SAR symbol until session/country override or migration.
- Full UI i18n audit beyond order details not exhaustive.
- Admin currency picker and wallet ledger not implemented.
- Cancel notification to assigned driver not added (order was pending_driver in screenshot).
