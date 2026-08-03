# DRIVER_SCREEN_INVENTORY

**App:** `mndob-main` · **Package:** `com.mycompany.mndob2` / `com.mycompany.mndob3`

## Production navigation shell (`NavBarPage`)

| Tab | Route name | Path | File | Purpose | Status |
|-----|------------|------|------|---------|--------|
| home | `home` | `/home` | `lib/home/home_widget.dart` | Map, Go Online, stats | PARTIAL — online gated; UI needs redesign later |
| Now | `Now` | `/neworder` | `lib/now/now_widget.dart` | Incoming / available orders | PARTIAL |
| Accepted | `Accepted` | `/Accepted` | `lib/accepted/accepted_widget.dart` | Active trips | PARTIAL |
| Completed | `Completed` | `/Completed` | `lib/completed/completed_widget.dart` | History | PARTIAL |
| Cancelled | `cansel` | `/cansel` | `lib/cansel/cansel_widget.dart` | Cancelled | PARTIAL |
| Profile | `Profile07` | `/profile07` | `lib/profile07/profile07_widget.dart` | Account | PARTIAL |

## Auth & registration

| Screen | Route | File | Purpose | Status |
|--------|-------|------|---------|--------|
| Auth gate (root `/`) | `_initialize` | `lib/components/driver_auth_gate.dart` | Session → Login/Home | FIXED (P2) — must never auto-open Regdrever |
| Login | `Login1` `/login1` | `lib/login1/login1_widget.dart` | Email/password | PARTIAL — validators + error map added |
| Register | `regdrever` `/regdrever` | `lib/regdrever/regdrever_widget.dart` | 4-step signup + Country/Region/City cascade | FIXED (P4 code) — expiry docs Deferred; device TBD |
| Pending approval | `DriverPendingApproval` | `lib/driver_pending_approval/...` | Under review UI | PARTIAL — not primary post-reg (Home preferred) |
| Wasl reg (LEGACY) | `NewDriverRegistration` | `lib/new_driver_registration/...` | Old flow | DO NOT USE in production UX |
| Company reg | `reg_compne` | `lib/reg_compne/...` | Company | OUT OF SCOPE for driver consumer flow |

## Trip & ops

| Screen | Route | File | Status |
|--------|-------|------|--------|
| Trip detail | `TfaselOrser` `/tfaselOrser` | `lib/tfasel_orser/tfasel_orser_widget.dart` | PARTIAL — status_code gates added |
| Chat | `Chat` `/chat` | `lib/chat/chat_widget.dart` | PARTIAL |
| Track | `ttb3` `/ttb3` | `lib/ttb3/ttb3_widget.dart` | PARTIAL |
| Wallet | `DriverWallet` | `lib/driver_wallet/...` | PARTIAL — currency by country |
| Bank update | `UpdetBank` | `lib/updet_bank/...` | PARTIAL |
| Support | `suport` | `lib/suport/...` | PARTIAL |
| Profile update | `ProfileUpdatePage` | `lib/profile_update_page/...` | PARTIAL |
| Village picker | `listvill` | `lib/listvill/...` | PARTIAL |

## Components (critical)

| Component | File | Role |
|-----------|------|------|
| DriverAuthGate | `lib/components/driver_auth_gate.dart` | Root session router |
| DriverNewOrderListener | `lib/components/driver_new_order_listener.dart` | Incoming order |
| DriverRideRequestSheet | `lib/components/driver_ride_request_sheet.dart` | Accept/reject |
| DriverHomeMapPanel | `lib/components/driver_home_map_panel.dart` | Map + online chip |
| DriverLocationWakeScope | `lib/components/driver_location_wake_scope.dart` | Resume location/trip |
| ListTypeCarWidget | `lib/components/list_type_car_widget.dart` | Vehicle type picker |
| DriverRegLocationMap | `lib/components/driver_reg_location_map.dart` | Reg GPS |

## Core services

| Service | File |
|---------|------|
| DriverLifecycleState | `lib/core/driver_lifecycle_state.dart` |
| DriverSessionRouter | `lib/core/driver_session_router.dart` |
| DriverOnlineState | `lib/core/driver_online_state.dart` |
| DriverEligibilityService | `lib/core/driver_eligibility_service.dart` |
| DriverTripService | `lib/core/driver_trip_service.dart` |
| DriverLiveLocationService | `lib/core/driver_live_location_service.dart` |
| DriverAuthErrors | `lib/core/driver_auth_errors.dart` |
| DriverPhoneNumberService | `lib/core/driver_phone_number_service.dart` |
| DriverRegistrationDraft | `lib/core/driver_registration_draft.dart` |
| TourySystemStatusCodes | `lib/core/toury_system_status_codes.dart` |

## Legacy / demo (exclude from production QA path)

`tfaselCopy`, `dashboard5`, `hgzCopy`, `hgzmgbol`, `hgzmktml`, `demoAI1`, `dfddf`, `sfdf`, `taimrDemo`, `mktmlh`

## Missing vs full product brief (Phase 1 gap list)

- Dedicated Onboarding (first launch only)
- Full multi-step register (docs upload, review screen, region/city pickers as separate steps)
- Phone OTP production path
- Atomic accept Cloud Function verification
- Shared status package across apps
- Full Design System (Uber/Careem-inspired) — Phase 12 only after functions work
