# URJA ONE Backend - Production Deployment & Scalability Guide

This guide covers production deployment for the **URJA ONE Fastify Backend** using **Vercel** or **Docker / Containerized Runtimes** (AWS ECS, Google Cloud Run, Render, Fly.io, DigitalOcean).

---

## 1. Environment Variables Configuration

Configure the following environment variables in your deployment dashboard (e.g. Vercel Project Settings > Environment Variables, or Docker `.env`):

| Variable Name | Required | Default / Example | Purpose |
|---|:---:|---|---|
| `NODE_ENV` | **Yes** | `production` | Enables production optimizations & logging |
| `PORT` | No | `3000` | Port for the HTTP server to listen on (auto-set by Vercel/Cloud Run) |
| `HOST` | No | `0.0.0.0` | Bind host address (must be `0.0.0.0` for containers) |
| `JWT_SECRET` | **Yes** | `min_32_characters_long_secure_random_key` | Secret key used for signing citizen JWT tokens |
| `GOOGLE_CLIENT_ID` | Optional | `382767...apps.googleusercontent.com` | Google OAuth Web Client ID for JWT verification |
| `CORS_ORIGIN` | No | `*` | Allowed origins (e.g. `https://your-frontend.vercel.app` or `*`) |
| `REDIS_URL` | Optional | `redis://localhost:6379` | In-memory atomic cache for high-throughput scaling |
| `DATABASE_URL` | Optional | `postgresql://user:pass@host:5432/urjavatika` | PostgreSQL connection string for ACID persistence |
| `IMAGEKIT_PUBLIC_KEY` | Optional | `public_...` | ImageKit public key for media avatar signatures |
| `IMAGEKIT_PRIVATE_KEY` | Optional | `private_...` | ImageKit private key for media HMAC signatures |
| `IMAGEKIT_URL_ENDPOINT` | Optional | `https://ik.imagekit.io/urjavatika` | ImageKit CDN endpoint URL |

---

## 2. Deploying on Vercel

### Option A: Via GitHub Integration (Zero-Touch Continuous Deployment)
1. Push your code to your GitHub repository (`main` branch or feature branch).
2. Go to [Vercel Dashboard](https://vercel.com/new).
3. Import your GitHub repository (`vivek3658/iit-gandhinagar-hackathon`).
4. Set the Root Directory to `./` (root).
5. In **Environment Variables**, add:
   - `NODE_ENV` = `production`
   - `JWT_SECRET` = `<your-strong-secret-key>`
   - `GOOGLE_CLIENT_ID` = `<your-web-client-id>`
6. Click **Deploy**. Vercel will automatically run `npm run build` using `vercel.json` and deploy the Fastify backend as a global serverless API.

### Option B: Via Vercel CLI
```bash
# 1. Install Vercel CLI (if not already installed)
npm i -g vercel

# 2. Login and deploy
vercel login
vercel --prod
```

---

## 3. Deploying with Docker

### Building the Production Docker Image
```bash
# Build multi-stage minimal Alpine image
docker build -t urja-backend:latest .

# Run container standalone
docker run -d \
  --name urja-backend \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e JWT_SECRET="your_secure_32_char_jwt_secret_key" \
  urja-backend:latest
```

### Running the Horizontally-Scaled Microservices Cluster (Docker Compose)
To launch the 4-instance cluster with Redis atomic queue and PostgreSQL:
```bash
# Start cluster in background
docker compose up -d

# Verify running services
docker compose ps

# Check cluster logs
docker compose logs -f
```

---

## 4. Connecting the Flutter Mobile Client to the Deployed Backend

When compiling or running the Flutter app against the deployed production backend, supply the `API_BASE_URL` via `--dart-define` so no secrets are committed in git:

```bash
# For local physical device over LAN:
flutter run --dart-define=API_BASE_URL=http://10.17.14.80:3000/api/v1

# For production deployed backend on Vercel / Cloud:
flutter run --dart-define=API_BASE_URL=https://your-backend.vercel.app/api/v1
```

---

## 5. Health Check & Monitoring

Once deployed, verify the server status:
```bash
curl https://your-backend.vercel.app/health
# Response:
# {"status":"ok","uptime":...,"timestamp":...}
```
