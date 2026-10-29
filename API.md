# UrjaVatika API Documentation

Backend API specification for the **UrjaVatika GEDA Mission LiFE Citizen Engagement Platform** (Problem Statement: `HC26-GEDA01`).

---

## 1. Global API Conventions

### Base URL
- Local Development: `http://localhost:3000/api/v1`
- Root Healthcheck: `http://localhost:3000/health`

### Headers & Content Types
- `Content-Type: application/json`
- `Accept: application/json`
- `Authorization: Bearer <jwt-token>` (for authenticated routes)

### Request & Response Compression
To minimize latency and bandwidth for millions of citizens on mobile and rural cellular networks:
- **Client Request:** Clients can send compressed bodies using `Content-Encoding: gzip` or `Content-Encoding: br`.
- **Server Response:** The server automatically compresses payloads using `@fastify/compress` supporting **Brotli (`br`)** (preferred) and **Gzip (`gzip`)** when the request includes `Accept-Encoding: br, gzip`. Payloads under 1 KB bypass compression to eliminate CPU overhead.

### Standard Success Response Envelope
All success payloads return the schema-validated data directly with optimal serializer throughput (`fast-json-stringify`):
```json
{
  "success": true,
  "data": { ... }
}
```

### Standard Error Response Shape
All error responses adhere strictly to the centralized error handler contract:
```json
{
  "statusCode": 400,
  "error": "Bad Request",
  "message": "Detailed human-readable error description"
}
```

Common status codes:
- `200 OK`: Request succeeded.
- `201 Created`: Resource successfully created.
- `204 No Content`: Successful request with no body returned.
- `400 Bad Request`: Validation failure on body, query, or params.
- `401 Unauthorized`: Missing or invalid JWT token.
- `403 Forbidden`: Insufficient permissions (e.g. non-admin accessing state KPI analytics).
- `404 Not Found`: Resource does not exist.
- `409 Conflict`: Unique constraint violation (e.g. duplicate mobile number).
- `429 Too Many Requests`: Rate limit exceeded.
- `500 Internal Server Error`: Unexpected server issue (sanitized in production, no stack traces leaked).

---

## 2. Core & System Endpoints

### Health & Readiness Check
- **`GET /health`**
  - **Description:** Verifies service uptime, database readiness, and memory usage.
  - **Authentication:** Public
  - **Response (200 OK):**
    ```json
    {
      "status": "ok",
      "timestamp": "2026-10-29T14:30:00.000Z",
      "uptime": 124.5,
      "service": "urjavatika-backend"
    }
    ```

---

## 3. Modular Feature Endpoints (Roadmap)

### Module 1: Authentication (`/api/v1/auth`)
- **`POST /api/v1/auth/register`**: Register new citizen with mobile number, DISCOM circle, and consumer ID.
- **`POST /api/v1/auth/login`**: Authenticate citizen via OTP or credentials, return JWT access token.
- **`GET /api/v1/auth/me`**: Retrieve active citizen profile and role credentials.

### Module 2: Profile & Citizen Baseline (`/api/v1/profile`)
- **`GET /api/v1/profile`**: Retrieve citizen profile, selected mascot, and household energy profile.
- **`PUT /api/v1/profile`**: Update household size, appliances, and DISCOM circle.

### Module 3: Energy Footprint Tracker (`/api/v1/footprint`)
- **`POST /api/v1/footprint/calculate`**: Calculate baseline carbon footprint from monthly kWh and tariff slab.
- **`GET /api/v1/footprint/history`**: Get monthly historical carbon emissions and reduction trajectory.

### Module 4: Gamified Mascot & Companion (`/api/v1/mascot`)
- **`GET /api/v1/mascot/state`**: High-velocity endpoint retrieving current mood, energy level, and dialogue.
- **`POST /api/v1/mascot/interact`**: Log citizen tap, hydration, or green tip read, updating mascot vitality.

### Module 5: Urja Vatika Virtual Garden (`/api/v1/garden`)
- **`GET /api/v1/garden/plot`**: Fetch 3x3 virtual green energy plot state (solar plants, wind chimes, flora).
- **`POST /api/v1/garden/water`**: Water plot using earned green energy points to advance plant bloom cycle.

### Module 6: DISCOM Peak Nudges & Micro-Tasks (`/api/v1/nudges`)
- **`GET /api/v1/nudges/active`**: Retrieve real-time grid alerts (e.g. shift load between 6:30 PM - 9:30 PM).
- **`POST /api/v1/nudges/commit`**: Citizen commits to shifting AC/washing machine during peak window.
- **`POST /api/v1/tasks/complete`**: Verify and reward completed micro-habit (e.g. turned off idle geyser).

### Module 7: Solar Feasibility & PM Surya Ghar (`/api/v1/solar`)
- **`POST /api/v1/solar/feasibility`**: Estimate rooftop solar capacity (kW), subsidy under PM Surya Ghar Muft Bijli Yojana, and ROI.
- **`GET /api/v1/solar/vendors`**: List empanelled GEDA solar vendors by Gujarat district.

### Module 8: Leaderboards & Community Impact (`/api/v1/leaderboard`)
- **`GET /api/v1/leaderboard/district`**: Sub-millisecond district ranking across Gujarat's 33 districts.
- **`GET /api/v1/leaderboard/ward`**: Ward-level community ranking.

### Module 9: State Administration & DISCOM Despatch (`/api/v1/admin`)
- **`GET /api/v1/admin/kpis`**: State-wide aggregated megawatt load shed and CO2 prevented.
- **`POST /api/v1/admin/broadcast-alert`**: Broadcast regional peak demand response alert to citizens.
