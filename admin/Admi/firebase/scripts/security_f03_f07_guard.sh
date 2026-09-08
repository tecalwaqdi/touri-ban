#!/usr/bin/env bash
# Minimal F03/F07 regression guard — fails if approved security markers disappear.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
RULES="$ROOT/admin/Admi/firebase/firestore.rules"
VERIFY="$ROOT/admin/services/payment-api/src/lib/auth/verify.ts"
SUMMARY="$ROOT/admin/Admi/firebase/functions/driver_financial_summary_v2.js"

fail() { echo "SECURITY_GUARD_FAIL: $*" >&2; exit 1; }

grep -q 'function agentCommercialRatesUnchanged' "$RULES" || fail "Agent_total lock missing"
grep -q 'function canReadSettlementChild' "$RULES" || fail "settlement child scope missing"
grep -q 'GLOBAL CAR CATALOG' "$RULES" || fail "type_car GLOBAL policy missing"
grep -q 'allow create, update, delete: if isSuperAdmin()' "$RULES" || fail "type_car Super Admin only missing"
# Country Admin must not write type_car in the type_car match block
python3 - <<PY
from pathlib import Path
text = Path("$RULES").read_text()
i = text.find("match /type_car/{document}")
block = text[i:i+400]
if "isCountryAdmin()" in block:
    raise SystemExit("type_car block still grants isCountryAdmin()")
print("type_car_block_ok")
PY

grep -q 'resolveFinanceAccess' "$VERIFY" || fail "Payment resolveFinanceAccess missing"
grep -q 'assertResourceCountryAccess' "$VERIFY" || fail "Payment country assert missing"
# rule===2 must not be treated as global admin (old pattern)
if grep -n 'rule === 1 || rule === 2' "$VERIFY" >/dev/null; then
  fail "Payment API still treats rule===2 as global"
fi

grep -q 'assertDriverSummaryCountryScope' "$SUMMARY" || fail "driver summary country scope missing"

echo "SECURITY_GUARD_PASS"
