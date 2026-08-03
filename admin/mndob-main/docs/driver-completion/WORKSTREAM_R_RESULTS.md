# WORKSTREAM R RESULTS — Release readiness

**Date:** 2026-07-28  
**Deploy / Store upload:** None  
**Device QA:** TBD

## Commands run

- `flutter test` → **117 passed**
- `flutter analyze` (touched paths) → infos/warnings only (0 errors)
- `flutter build apk --release` → **SUCCESS**
- `flutter build appbundle --release` → (see below)

## Artifacts

| Artifact | Path | Size | SHA-256 |
|----------|------|------|---------|
| APK | `mndob-main/build/app/outputs/flutter-apk/app-release.apk` | 102717792 (~98.0MB) | `3C29E92B6322DF810FD604E95B0DD4FCCB879372DDACCF345F80907C15955147` |
| AAB | `mndob-main/build/app/outputs/bundle/release/app-release.aab` | 81105091 (~77.3MB) | `9C6A65E93822809B3774EE74A5DD02D2BB9220251F75BD0C6F24490ECC7F5B3B` |

## Identity

- Package: `com.mycompany.mndob2`
- version: `2.0.2+9`
- Firebase: `tutorial-multi-language-70gx4j`
- Signing: `android/key.properties` **absent** — not store-upload ready

## Gate

Release **build produced locally**. **Not** store-ready. **Not** Production Ready.
