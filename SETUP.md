# Local Backend Setup Guide: UrjaVatika

This guide details instructions for setting up, running, testing, and developing the **UrjaVatika Fastify v5 Backend** on your local machine.

---

## 1. Prerequisites
- **Node.js**: v20.x or v22.x LTS (`node -v`)
- **npm**: v10.x or higher (`npm -v`)
- **Git**: Installed and initialized on `feature/backend`
- *(Optional for full integration)*:
  - **PostgreSQL 16**: Relational database for persistent citizen logs & auth.
  - **Redis 7**: In-memory store for high-throughput leaderboards, nudges, and mascot state.

---

## 2. Environment Configuration
The project strictly enforces validated environment variables via `@fastify/env` or TypeBox/Zod schemas.

1. Copy the example environment template:
   ```bash
   cp .env.example .env
   ```
2. Open `.env` and verify the settings:
   ```env
   # Server Config
   PORT=3000
   HOST=0.0.0.0
   NODE_ENV=development
   LOG_LEVEL=info

   # Security
   JWT_SECRET=super-secret-jwt-key-for-local-dev-min-32-chars!
   CORS_ORIGIN=*

   # Persistence
   DATABASE_URL=postgresql://postgres:postgres@localhost:5432/urjavatika?schema=public
   REDIS_URL=redis://localhost:6379
   ```
> [!IMPORTANT]
> Never commit `.env` or sensitive credentials to Git. Always update `.env.example` when introducing new configuration variables.

---

## 3. Installation
Install project dependencies:
```bash
npm install
```

---

## 4. Running the Application

### Development Mode (with hot-reload)
```bash
npm run dev
```
The server will boot on `http://localhost:3000`. Fastify's built-in Pino logger will output pretty-printed logs in development mode.

### Production Build & Run
Compile TypeScript to JavaScript and run the optimized bundle:
```bash
npm run build
npm start
```

### Docker Containerized Cluster (4 Replicas + Redis + Postgres + NGINX)
Run the entire production-grade cluster locally using Docker:
```bash
# Build and boot the cluster with 4 Fastify app instances (1 CPU core & 2GB RAM each)
docker compose up --build -d

# Check cluster status
docker compose ps

# View live aggregated logs
docker compose logs -f app
```
The cluster will be accessible at:
- **API Gateway & Swagger UI:** `http://localhost/docs`
- **Healthcheck:** `http://localhost/health`
- **PostgreSQL:** `localhost:5432`
- **Redis:** `localhost:6379`

---

## 5. Verification & Health Check
Open your browser or run curl to verify that the server is operational:
```bash
curl -i http://localhost:3000/health
```
Expected response:
```json
{
  "status": "ok",
  "timestamp": "2026-10-29T14:30:00.000Z",
  "uptime": 1.25,
  "service": "urjavatika-backend"
}
```

To verify gzip/brotli compression:
```bash
curl -H "Accept-Encoding: gzip, br" -i http://localhost:3000/health
```

---

## 6. Testing & Quality Assurance

### Run Unit & Integration Tests (Vitest)
```bash
npm test
```
Tests use `fastify.inject()` to execute end-to-end HTTP pipelines in-memory without binding external network sockets.

### Linting & Formatting Check
```bash
npm run lint
```
Enforces TypeScript strict mode and formatting standards.

---

## 7. Project Structure
In adherence to `AGENTS.md` and `.agent/rules/fastify-backend.md`:
```
src/
├── app.ts            # Builds and exports the configured Fastify instance (no listen, injectable)
├── server.ts         # Entry point: imports app, handles shutdown signals, calls listen
├── config/           # Environment validation schema (config/env.ts)
├── plugins/          # Fastify plugins (helmet, cors, compress, sensible, rate-limit)
├── modules/          # Feature-based domain modules
│   └── <name>/
│       ├── <name>.schema.ts      # TypeBox schemas (Body, Params, Query, Response)
│       ├── <name>.service.ts     # Business logic & data queries
│       ├── <name>.controller.ts  # HTTP request/reply handlers
│       └── <name>.routes.ts      # Endpoint declarations & schema registrations
├── utils/            # Helper utilities and serializers
└── types/            # App-wide ambient TypeScript interfaces
test/                 # Vitest test suites executing via app.inject()
```
