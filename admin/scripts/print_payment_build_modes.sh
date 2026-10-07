#!/usr/bin/env bash
# Print payment build mode separation (no build).
set -euo pipefail
cat <<'EOF'
TOURi TAXI — Payment build modes

PRODUCTION_HPP (store / proven)
  Scripts: build_customer_ipa.sh, build_customer_aab.sh, build_store_releases.sh,
           build_and_upload_*.sh, upload_ios_store_ipas.sh
  Defines:
    MOBILE_PAYMENT_MODE=hpp
    OPEN_PAYMENT_IN_EXTERNAL_BROWSER=false
  Behavior: Hosted Payment Page in-app WebView — store / production UX.

QA_NATIVE_SDK (device QA only — no store production publish)
  Scripts:
    admin/scripts/build_customer_ios_qa_native_sdk.sh
    admin/scripts/build_customer_android_qa_native_sdk.sh
  Defines:
    MOBILE_PAYMENT_MODE=sdk
    OPEN_PAYMENT_IN_EXTERNAL_BROWSER=false
  Behavior: NISdk / Android PaymentClient primary; HPP WebView fallback only.
  Do NOT App Store submit / Play production publish from QA scripts.

Promote SDK to production defaults only after SAFE_TO_PROMOTE_SDK=YES.
EOF
