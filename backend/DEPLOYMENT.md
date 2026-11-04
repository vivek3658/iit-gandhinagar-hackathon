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
| `ADMIN_USERNAME` | Optional | `urjaone` | Username for the initial platform administrator login |
| `ADMIN_EMAIL` | Optional | `admin@example.com` | Email for the initial platform administrator login; either email or username can identify the platform administrator |
| `ADMIN_PASSWORD_HASH` | Optional | `scrypt$<salt-base64>$<hash-base64>` | 64-byte scrypt password hash; plaintext admin passwords are never stored |
| `CRON_SECRET` | Required for scheduled campaign delivery | Random secret of at least 32 characters | Authorizes the scheduled outbox-dispatch endpoint |
| `GOOGLE_CLIENT_ID` | Optional | `382767...apps.googleusercontent.com` | Google OAuth Web Client ID for JWT verification |
| `CORS_ORIGIN` | No | `*` | Allowed origins (e.g. `https://your-frontend.vercel.app` or `*`) |
| `REDIS_URL` | Optional | `redis://localhost:6379` | In-memory atomic cache for high-throughput scaling |
| `DATABASE_URL` | Optional | `postgresql://user:[YOUR-PASSWORD]@host:5432/urjavatika` | PostgreSQL connection string for ACID persistence |
| `MONGODB_URL` | Optional | `mongodb://localhost:27017/urja` | Optional MongoDB integration; otherwise the plugin reports in-memory fallback mode |
| `RABBITMQ_URL` | Optional | `amqp://localhost:5672` | Optional RabbitMQ task queue; otherwise the plugin uses its local mock |
| `IMAGEKIT_PUBLIC_KEY` | Optional | `public_...` | ImageKit public key for media avatar signatures |
| `IMAGEKIT_PRIVATE_KEY` | Optional | `private_...` | ImageKit private key for media HMAC signatures |
| `IMAGEKIT_URL_ENDPOINT` | Optional | `https://ik.imagekit.io/urjavatika` | ImageKit CDN endpoint URL |

Production requires a reachable PostgreSQL `DATABASE_URL`; local development may omit it and use in-memory state. The backend connects directly to PostgreSQL and does not use Supabase REST API credentials. If Supabase hosts your PostgreSQL database, use its PostgreSQL connection string only; `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are not used.

Platform-admin login at `POST /api/v1/admin/auth/login` is available after both admin variables are set. Generate a password hash on a trusted machine with Node.js:

```js
const { randomBytes, scryptSync } = require('node:crypto');
const salt = randomBytes(16);
const hash = scryptSync(process.env.ADMIN_INITIAL_PASSWORD, salt, 64);
console.log(`scrypt$${salt.toString('base64')}$${hash.toString('base64')}`);
```

Set `ADMIN_INITIAL_PASSWORD` only in the local shell for this command, store the printed hash as the deployment secret `ADMIN_PASSWORD_HASH`, then remove the plaintext variable. Admin JWTs expire after 15 minutes. Create provider/city tenant admins through the platform-admin API after the initial platform account can sign in. Citizen notification and household-analytics consent defaults to off. Campaigns due now are delivered to opted-in users during creation; future campaigns use the scheduled dispatcher. No push delivery is configured. Government household metrics include only aggregated totals from citizens who opted in; identifiable device records are not included.

Generate `CRON_SECRET` with a cryptographically secure random generator (at least 32 characters). The Hobby-compatible Vercel Cron in `vercel.json` runs daily at 12:30 UTC (18:00 India time) and invokes the due-notification dispatcher; the Vercel deployment must have the same `CRON_SECRET` value set as an environment variable. Due campaign messages are delivered at the next daily run. When hosting elsewhere, configure an equivalent scheduler to send `Authorization: Bearer <CRON_SECRET>` to `POST /api/v1/notifications/internal/dispatch-due`.

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
   - `DATABASE_URL` = `<your PostgreSQL connection string>`
6. Click **Deploy**. Vercel will automatically run `npm run build` using `vercel.json` and deploy the Fastify backend as a global serverless API.

`DATABASE_URL` must be the PostgreSQL connection string from your database provider (for Supabase on Vercel, use its pooler connection string). Set it in Vercel's Environment Variables for the deployment environment and redeploy after changing it. Do not include surrounding quotes or placeholder brackets; URL-encode reserved characters in the username or password.

The Next.js operator console lives in `frontend/` and should be deployed as its own Vercel project with the Root Directory set to `frontend`. Configure `URJA_API_URL` there to the backend origin (for example `https://urjaone.vercel.app`, with no `/api/v1` suffix). The console's server routes proxy API calls and hold admin JWTs in HttpOnly cookies; do not expose admin credentials or tokens through `NEXT_PUBLIC_*` variables.

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

### Running the Docker Compose Stack
The Compose file starts two API containers, Redis, and PostgreSQL. It does not start MongoDB or RabbitMQ. To run only one API container with Redis and PostgreSQL on a constrained local Docker host (1 vCPU / 2 GB RAM):
```bash
docker compose up -d backend-1 redis postgres

# Verify running services
docker compose ps

# Check cluster logs
docker compose logs -f
```

This setup is for local functional testing only. It has no configured CPU or memory limits and is not a benchmark or verified capacity rating. Swagger UI is available at `http://localhost:3000/docs`; the OpenAPI JSON is at `http://localhost:3000/docs/json`.

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
