#!/usr/bin/env bash
# Deploy Touri payment-api to Firebase Functions (paymentApi).
# Prerequisites:
#   1) firebase login --reauth
#   2) Secrets set once:
#        firebase functions:secrets:set NGENIUS_API_KEY --project tutorial-multi-language-70gx4j
#        firebase functions:secrets:set NGENIUS_OUTLET_REF --project tutorial-multi-language-70gx4j
#        firebase functions:secrets:set NGENIUS_WEBHOOK_SECRET --project tutorial-multi-language-70gx4j
#
# Deploy from this package directory (Firebase forbids sources outside project dir).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="${FIREBASE_PROJECT:-tutorial-multi-language-70gx4j}"

echo "==> Build payment-api"
cd "$ROOT"
npm ci
npm run build

echo "==> Deploy functions:payment-api (project=$PROJECT)"
# firebase.json + .firebaserc live in this package
firebase deploy --only functions:payment-api --project "$PROJECT"

echo ""
echo "URL: https://us-central1-${PROJECT}.cloudfunctions.net/paymentApi"
echo "Health: curl -sS https://us-central1-${PROJECT}.cloudfunctions.net/paymentApi/health"
echo "Webhook: https://us-central1-${PROJECT}.cloudfunctions.net/paymentApi/webhooks/ngenius"
echo ""
echo "NOTE: Production client defaults stay on Render (touri-ban.onrender.com)."
echo "Firebase paymentApi is Future/Legacy/Rollback only. To point a build here:"
echo "  --dart-define=PAYMENT_BACKEND=external_api \\"
echo "  --dart-define=PAYMENT_API_BASE_URL=https://us-central1-${PROJECT}.cloudfunctions.net/paymentApi"
echo ""
echo "Flutter:"
echo "  --dart-define=ENABLE_ONLINE_PAYMENT=true"
echo "  --dart-define=PAYMENT_BACKEND=external_api"
echo "  --dart-define=PAYMENT_API_BASE_URL=https://us-central1-${PROJECT}.cloudfunctions.net/paymentApi"
