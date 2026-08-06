#!/usr/bin/env bash
# Run Admin Web Dashboard locally (path URL strategy).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PORT="${1:-8080}"
HOST="${2:-127.0.0.1}"

echo "==> Admin Web Dashboard"
echo "    Local URL: http://${HOST}:${PORT}/"
echo "    Login:     http://${HOST}:${PORT}/homePage"
echo "    Dashboard: http://${HOST}:${PORT}/home22Dashboard"
echo ""

flutter pub get
flutter run -d web-server --web-hostname="$HOST" --web-port="$PORT"
