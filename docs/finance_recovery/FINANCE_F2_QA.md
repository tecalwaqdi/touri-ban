# Finance F2 — Human QA Checklist

**Preview channel:** `admin-finance-f2`  
**Production:** DO NOT deploy

## Safari / desktop

- [ ] Finance Hub loads without blank white page
- [ ] Summary shows completed / documented / partial counts honestly
- [ ] Partial trips show `—` not fabricated zeros
- [ ] Money movement table scrolls horizontally without overflow crash
- [ ] Trip details drawer sections A–F in Arabic
- [ ] No raw enums (`DRIVER_PAYS_COMPANY`, `COMPLETE`, `draft` English)
- [ ] Settlements list: due / paid / remaining visible
- [ ] Settlement details: اعتماد التسوية / تسجيل دفعة (no Preview/Ledger English)
- [ ] Refresh retains last valid data (no full wipe flicker)
- [ ] RTL + Cairo + teal hierarchy

## Country Agent (if available)

- [ ] Only `/adminFinanceAgents` finance entry
- [ ] No other-country totals
- [ ] Missing historical agent shows «الوكيل التاريخي غير محدد»

## Filters

- [ ] Date presets change summary + table together
- [ ] Payment / collection / quality filters apply to table only
