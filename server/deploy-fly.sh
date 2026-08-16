#!/usr/bin/env bash
# Deploy Falimy API to Fly.io.
# Prerequisites: flyctl installed, `fly auth login`, MongoDB Atlas URI ready.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="${FLY_APP_NAME:-falimy-api}"
REGION="${FLY_REGION:-sin}"

if ! flyctl auth whoami >/dev/null 2>&1; then
  echo "Not logged in. Opening Fly login..."
  flyctl auth login
fi

# Create the app if it does not exist yet.
if ! flyctl status -a "$APP_NAME" >/dev/null 2>&1; then
  echo "Creating Fly app '${APP_NAME}' in region ${REGION}..."
  if [[ "$APP_NAME" != "falimy-api" ]]; then
    sed -i.bak "s/^app = .*/app = \"$APP_NAME\"/" fly.toml
    rm -f fly.toml.bak
  fi
  # Prefer launch from fly.toml; fall back to apps create.
  if ! flyctl apps create "$APP_NAME" --org personal; then
    echo "Retrying app create without --org..."
    flyctl apps create "$APP_NAME"
  fi
fi

if [[ -z "${MONGODB_URI:-}" ]]; then
  if [[ -f .env ]]; then
    MONGODB_URI="$(grep -E '^MONGODB_URI=' .env | cut -d= -f2-)"
    JWT_SECRET="$(grep -E '^JWT_SECRET=' .env | cut -d= -f2-)"
    JWT_EXPIRES_IN="$(grep -E '^JWT_EXPIRES_IN=' .env | cut -d= -f2- || true)"
  fi
fi

if [[ -z "${MONGODB_URI:-}" ]]; then
  echo "ERROR: Set MONGODB_URI (Atlas connection string) in server/.env or the environment."
  exit 1
fi

JWT_SECRET="${JWT_SECRET:-$(openssl rand -hex 32)}"
JWT_EXPIRES_IN="${JWT_EXPIRES_IN:-30d}"

echo "Setting Fly secrets..."
flyctl secrets set \
  -a "$APP_NAME" \
  MONGODB_URI="$MONGODB_URI" \
  JWT_SECRET="$JWT_SECRET" \
  JWT_EXPIRES_IN="$JWT_EXPIRES_IN" \
  USE_MEMORY_MONGO=false \
  NODE_ENV=production

echo "Deploying..."
flyctl deploy -a "$APP_NAME" --ha=false

URL="https://${APP_NAME}.fly.dev"
echo ""
echo "Deployed: $URL"
echo "Health:   $URL/health"
echo ""
echo "Build the Flutter app with:"
echo "  flutter build apk --dart-define=API_BASE_URL=$URL"
echo "  flutter run --dart-define=API_BASE_URL=$URL"
