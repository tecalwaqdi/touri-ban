# Deployment Plan (NOT EXECUTED)

## Safe order (when Ara approves)

1. Confirm Firestore backup available.
2. Deploy Functions (read-only + flags first): accounting, scan, snapshot validators.
3. Deploy Admin Hosting (V3 UI reads).
4. Verify SOURCE=FIREBASE=RENDER version parity.
5. Enable write flags one-by-one with controlled fixtures.
6. Never enable online payment solely because code exists.

## This session

**No Production deploy performed for Finance V3.**
