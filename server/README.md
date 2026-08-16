# Falimy API (Node.js + MongoDB)

## Setup

### 1. MongoDB

**Option A — Homebrew (macOS):**
```bash
brew tap mongodb/brew
brew trust mongodb/brew
brew install mongodb-community@7.0
brew services start mongodb-community@7.0
```

**Option B — Docker:**
```bash
cd server && docker compose up -d
```

**Option C — MongoDB Atlas:** put your connection string in `.env` as `MONGODB_URI`.

### 2. API server

```bash
cd server
cp .env.example .env
npm install
npm run dev
```

API: `http://localhost:3000` · Health: `GET /health`

## Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/auth/sign-up` | No | Register |
| POST | `/api/auth/sign-in` | No | Login |
| GET | `/api/auth/me` | Yes | Current user + profile |
| GET | `/api/profile` | Yes | Get family profile |
| PUT | `/api/profile` | Yes | Save family profile |
| DELETE | `/api/profile` | Yes | Clear profile |
| POST | `/api/invites` | Yes | Create family invite |

Images stay on **Cloudinary** (uploaded from the Flutter app). MongoDB stores the Cloudinary URL in `photoPath`.

## Flutter

Default API URL:
- iOS simulator / desktop → `http://localhost:3000`
- Android emulator → `http://10.0.2.2:3000`

Override:
```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:3000
```

## Deploy to Fly.io (public API for remote users)

1. **MongoDB Atlas** — Network Access → allow `0.0.0.0/0` (or Fly egress IPs).  
   Put the Atlas URI in `server/.env` as `MONGODB_URI` and set `USE_MEMORY_MONGO=false`.

2. **Login & deploy**
```bash
fly auth login
cd server
chmod +x deploy-fly.sh
./deploy-fly.sh
```

3. **Point the app at the public URL** (example):
```bash
flutter run --dart-define=API_BASE_URL=https://falimy-api.fly.dev
flutter build apk --dart-define=API_BASE_URL=https://falimy-api.fly.dev
```

Health check: `GET https://falimy-api.fly.dev/health`

**Note:** CashBook / Financial data stays on each phone. Hosting only covers auth, profile, family tree, and invites.
