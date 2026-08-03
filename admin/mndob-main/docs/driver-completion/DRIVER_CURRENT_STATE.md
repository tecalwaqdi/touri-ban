# DRIVER_CURRENT_STATE

See also: [PHASE1_FINDINGS.md](./PHASE1_FINDINGS.md) (authoritative Phase 1 answers).

## Identity

| Item | Value |
|------|--------|
| Driver | `d:\Projects\ara\admin\mndob-main` · `com.mycompany.mndob2` / iOS `com.mycompany.mndob3` |
| Customer | `d:\Projects\ara\admin\ara_oatan_app` · `com.mycompany.araoatanapp` |
| Admin | `d:\Projects\ara\admin\Admi` · `com.mycompany.tutorialmultilanguageapp` |
| Firebase (all) | `tutorial-multi-language-70gx4j` |
| Canonical firebase folder | `ara_oatan_app/firebase` |
| Flutter | 3.44.4 |

## Production registration

`regdrever` only (email+password). Wasl `NewDriverRegistration` = legacy.

## Blocking defects (Phase 2 target)

Session/router: anonymous guest + auto Regdrever + draft restore last step.

## Deploy policy

**No Production publish** until Phase gates pass and Project ID confirmed with operator.
