# Manual Payment QA Matrix

**Status:** Not executed on devices in this migration phase.  
Mark cases only after real device/sandbox runs.

| ID | Case | Android | iOS | ar | en | ru | ky | Result |
|----|------|---------|-----|----|----|----|----|--------|
| M01 | Cash booking create | | | | | | | |
| M02 | Card create session (sandbox) | | | | | | | |
| M03 | Visa 3DS success | | | | | | | |
| M04 | Mastercard 3DS success | | | | | | | |
| M05 | Mada (if outlet supports) | | | | | | | |
| M06 | 3DS failure | | | | | | | |
| M07 | User cancel | | | | | | | |
| M08 | Kill app mid-payment | | | | | | | |
| M09 | Network loss | | | | | | | |
| M10 | Double tap create | | | | | | | |
| M11 | Delayed webhook | | | | | | | |
| M12 | Duplicate webhook | | | | | | | |
| M13 | Return URL ok but unpaid | | | | | | | |
| M14 | Paid but return URL fails | | | | | | | |
| M15 | Driver sees paid online only | | | | | | | |
| M16 | Driver sees cash | | | | | | | |
| M17 | Admin status visible | | | | | | | |
| M18 | Refund (admin) | | | | | | | |
| M19 | SA / KG / RU / UZ currency | | | | | | | |

Countries/currencies must match live Firestore country documents.
