#!/usr/bin/env bash
# Temporary public URL via Cloudflare Tunnel (Mac must stay on).
# Good for testing with someone in UAE without paying for hosting.
set -euo pipefail

cd "$(dirname "$0")"

if ! curl -sf http://127.0.0.1:3000/health >/dev/null; then
  echo "Starting local API..."
  npm run start >/tmp/falimy-api.log 2>&1 &
  sleep 2
fi

if ! curl -sf http://127.0.0.1:3000/health >/dev/null; then
  echo "ERROR: API not reachable on http://127.0.0.1:3000"
  echo "Start it with: npm run dev"
  exit 1
fi

echo "API is up. Opening Cloudflare quick tunnel..."
echo "Copy the https://....trycloudflare.com URL that appears below."
echo "Then run Flutter with:"
echo '  flutter run --dart-define=API_BASE_URL=https://THAT-URL'
echo ""

exec cloudflared tunnel --url http://127.0.0.1:3000
