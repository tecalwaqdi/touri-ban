# Driver auth error keys (customer + driver shared convention)

Add to driver app langs when wiring UI; codes used for mapping:

| Code | Meaning |
|------|---------|
| driver_auth_invalid_phone | Bad +996 / national length |
| driver_auth_invalid_otp | OTP failed |
| driver_auth_session_expired | Token expired |
| driver_profile_not_found | No mndob doc |
| driver_country_not_supported | ISO not in dialByIso |
| driver_permission_denied | Rules blocked |
| driver_pending_review | Awaiting admin |
| driver_suspended | Suspended |
| driver_network_error | Network |
| driver_unknown_error | Fallback |

**Phone:** `DriverPhoneNumberService` already supports `KG` → `996`, national length 9.

**Remaining:** Device QA for OTP + App Check + CF approve path (see MASTER_BLOCKERS). No deploy in this pass.
