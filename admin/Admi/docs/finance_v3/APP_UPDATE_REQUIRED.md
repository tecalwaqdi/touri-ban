# App Update Required?

## Customer App (`ara_oatan_app`)

**Required for Finance V3 foundations:** NO.

Continues to write/read existing order majors and payment fields. Server/Admin may add additive snapshot fields later without forcing update.

## Driver App (`mndob-main`)

**Required for Finance V3 foundations:** NO.

Cash confirm remains `confirmCashCollectionV2`. No contract break in this phase.

## If future write of `financial_snapshot` on complete

Prefer Cloud Function on completion so apps need no change.  
Only if client must send extra fields → document here before forcing store update.
