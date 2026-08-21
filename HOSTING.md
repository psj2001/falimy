# Deploy Falimy API on Render (step-by-step)

## 0. One-time prerequisites

1. **MongoDB Atlas** → Network Access → Add IP → **Allow Access from Anywhere** (`0.0.0.0/0`).
2. Keep your Atlas URI handy (from `server/.env` → `MONGODB_URI`). Never commit `.env`.

## 1. Push this repo to GitHub

In Terminal:

```bash
cd /Users/pranavps/Documents/falimy

# Fix GitHub login (opens browser)
gh auth login

# Create private repo + push
gh repo create falimy --private --source=. --remote=origin --push
```

If the repo already exists on GitHub:

```bash
git remote add origin https://github.com/YOUR_USER/falimy.git
git push -u origin main
```

## 2. Create the Render service

1. Open [https://dashboard.render.com](https://dashboard.render.com) and sign in (GitHub).
2. **New** → **Blueprint**.
3. Connect the **falimy** repo.
4. Render reads `render.yaml` and prompts for **MONGODB_URI** — paste your Atlas string.
5. Click **Apply**. Wait until status is **Live**.

The live API URL is:

`https://falimy-xhap.onrender.com`

Check health:

`https://falimy-xhap.onrender.com/health` → `{"ok":true,"service":"falimy-api"}`

### Manual create (if Blueprint fails)

**New** → **Web Service** → pick repo →:

| Setting | Value |
|--------|--------|
| Root Directory | `server` |
| Runtime | Node |
| Build Command | `npm ci --omit=dev` |
| Start Command | `node src/index.js` |
| Instance | Free |
| Region | Oregon |

Env vars:

- `NODE_ENV` = `production`
- `USE_MEMORY_MONGO` = `false`
- `MONGODB_URI` = *(your Atlas URI)*
- `JWT_SECRET` = *(long random string)*
- `JWT_EXPIRES_IN` = `365d`

## 3. Point Flutter at Render

```bash
flutter run --dart-define=API_BASE_URL=https://falimy-xhap.onrender.com
flutter build apk --dart-define=API_BASE_URL=https://falimy-xhap.onrender.com
```

## Notes

- Free Render services **sleep** after ~15 min idle; first request can take 30–60s.
- The app keeps you signed in if the API is asleep or the network fails. It only signs you out when the session token is actually invalid.
- CashBook data stays on each phone; only auth/profile/family/invites use this API.
