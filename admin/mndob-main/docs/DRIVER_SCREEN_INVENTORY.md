# Driver App Screen Inventory — mndob-main

**App:** `d:\Projects\ara\admin\mndob-main`  
**Package:** Android `com.mycompany.mndob2` / iOS `com.mycompany.mndob3`  
**Firebase:** `tutorial-multi-language-70gx4j`  
**Branch:** `fix/driver-production-hardening`

## Bottom navigation

| Tab | Route | Widget | Purpose |
|-----|-------|--------|---------|
| home | `/home` | HomeWidget | Map, online, daily stats |
| Now | `/neworder` | NowWidget | Available orders |
| Accepted | `/Accepted` | AcceptedWidget | Active trips |
| Completed | `/Completed` | CompletedWidget | Finished trips |
| cansel | `/cansel` | CanselWidget | Cancelled trips |
| Profile07 | `/profile07` | Profile07Widget | Account |

## Production routes

| Screen | Path | File | Auth | Connected |
|--------|------|------|------|-----------|
| Login | `/login1` | `lib/login1/login1_widget.dart` | no | yes |
| Home | `/home` | `lib/home/home_widget.dart` | yes | yes |
| Now | `/neworder` | `lib/now/now_widget.dart` | yes | yes |
| Accepted | `/Accepted` | `lib/accepted/accepted_widget.dart` | yes | yes |
| Completed | `/Completed` | `lib/completed/completed_widget.dart` | yes | yes |
| Cancelled | `/cansel` | `lib/cansel/cansel_widget.dart` | yes | yes |
| Profile | `/profile07` | `lib/profile07/profile07_widget.dart` | yes | yes |
| Trip detail | `/tfaselOrser` | `lib/tfasel_orser/tfasel_orser_widget.dart` | yes | yes (primary) |
| Chat | `/chat` | `lib/chat/chat_widget.dart` | no* | yes |
| Wallet | `/driverWallet` | `lib/driver_wallet/driver_wallet_widget.dart` | yes | yes |
| Bank | `/updetBank` | `lib/updet_bank/updet_bank_widget.dart` | no* | yes |
| Support | `/suport` | `lib/suport/suport_widget.dart` | no* | yes |
| Profile update | `/profileUpdatePage` | `lib/profile_update_page/...` | no* | yes |
| Registration | `/regdrever` | `lib/regdrever/regdrever_widget.dart` | no | yes |
| New registration | `/newDriverRegistration` | `lib/new_driver_registration/...` | no | legacy |
| Company reg | `/regCompne` | `lib/reg_compne/...` | no | partial |
| Track map | `/ttb3` | `lib/ttb3/ttb3_widget.dart` | no* | yes |
| Villages | `/listvill` | `lib/listvill/listvill_widget.dart` | no | picker |

\* typically used while logged in.

## Legacy / demo (keep out of production UX)

| Route | Note |
|-------|------|
| `/tfaselCopy` | Old trip detail — do not navigate from production |
| `/dashboard5`, `/hgzCopy`, `/hgzmgbol`, `/hgzmktml` | Legacy lists |
| `/demoAI1`, `/dfddf`, `/sfdf`, `/taimrDemo` | Demos |
| `/mktmlh` | Completed alt |

## Order-flow components

| Component | File | Role |
|-----------|------|------|
| DriverNewOrderListener | `lib/components/driver_new_order_listener.dart` | FCM/incoming sheet |
| DriverRideRequestSheet | `lib/components/driver_ride_request_sheet.dart` | Accept/reject |
| DriverTripDetailsBanner | `lib/components/driver_trip_details_banner.dart` | Arrive CTA |
| DriverHomeMapPanel | `lib/components/driver_home_map_panel.dart` | Home map + status |
| DriverTripService | `lib/core/driver_trip_service.dart` | Accept/arrive/start/complete/cancel |
| DriverOnlineState | `lib/core/driver_online_state.dart` | Online gate |

## Root gaps addressed in this hardening pass

1. Missing production Go Offline  
2. Cancel without `cancelled_by_driver` / wrong `ActiveOrder`  
3. Start hidden after Arrive  
4. Complete locked behind 30 minutes  
5. Online chip comparing `settings.ngl`  
6. List filters on Arabic only  
7. Wallet currency hardcoded SAR  
8. Hardcoded Arabic trip messages  

## Firestore rules (local sync — no deploy in this pass)

Canonical: `ara_oatan_app/firebase/firestore.rules`  
Mirrors: `mndob-main/firebase/firestore.rules`, `Admi/firebase/firestore.rules`

- `type_car` public read (registration catalog)
- `driverCanClaimOrder` / `driverCanAdvanceTrip` / `driverCanCompleteCashCollection` cover accept → cancel path
- **Do not deploy** until Production Project ID is confirmed (`tutorial-multi-language-70gx4j`)
