# UrjaVatika API

The generated OpenAPI document at `GET /docs/json` is the authoritative reference for current routes, request/response schemas, and authentication. This file summarizes user-facing behavior and production limitations.

## Conventions

- Local base URL: `http://localhost:3000/api/v1`
- Authenticated routes require `Authorization: Bearer <access-token>`.
- Success and error payloads follow the route's generated OpenAPI schema.
- Production requires PostgreSQL. Configure `DATABASE_URL` and the other required environment variables described in [backend/DEPLOYMENT.md](./backend/DEPLOYMENT.md).

## Persisted citizen data

These routes require a citizen token and PostgreSQL:

| Method and path | Behavior |
|---|---|
| `GET /api/v1/readings` | List the signed-in citizen's utility readings. |
| `POST /api/v1/readings` | Add an electricity, water, or gas reading. Its provenance is `USER_ENTERED`, not provider-verified. |
| `GET /api/v1/vehicles` | List the citizen's vehicles. |
| `POST /api/v1/vehicles` | Add a citizen-entered vehicle; no government registration lookup is performed. |
| `PUT /api/v1/vehicles/:vehicleId` | Update a citizen-owned vehicle. |
| `DELETE /api/v1/vehicles/:vehicleId` | Soft-delete a citizen-owned vehicle. |
| `GET /api/v1/trips` | List citizen-confirmed trip summaries. |
| `POST /api/v1/trips` | Submit an idempotent, citizen-confirmed trip summary. Raw GPS coordinates are neither accepted nor stored. CO₂e is unknown unless a validated calculation is configured. |
| `GET /api/v1/analytics/dashboard` | Return the citizen's stored utility readings and explicit data-availability flags. |
| `GET /api/v1/analytics/carbon` | Alias for the analytics dashboard. |
| `GET /api/v1/quests/daily` | Get daily self-reported tasks and streak state. |
| `POST /api/v1/quests/claim/:questId` | Claim a task's coin reward. This is not independent verification that the action occurred. |
| `GET /api/v1/learning/chapters` | List versioned learning chapters and quizzes. |
| `POST /api/v1/learning/chapters/:chapterId/complete` | Submit a quiz; the reward is once per chapter version. |
| `GET /api/v1/learning/waste-game/catalog` | Get sorting-game items and locality-qualified guidance. |
| `POST /api/v1/learning/waste-game/play` | Submit the daily game; the reward is once per UTC day and does not claim that waste was collected or emissions avoided. |
| `POST /api/v1/devices/log-hours` | Save daily appliance runtime; energy is labeled as an estimate from rated power, while cost and CO₂e remain unavailable without tariff and validated emission data. |
| `GET /api/v1/devices/summary` | Summarize saved runtime logs; monthly bill projections remain unavailable without tariff data. |
| `GET /api/v1/activity` | Return the signed-in citizen's persisted activity feed, including per-citizen read state for shared community events. |
| `POST /api/v1/activity/:id/read` | Mark a citizen-owned or shared activity item as read for this citizen. |
| `POST /api/v1/activity/read-all` | Mark all visible activity items read for this citizen. |
| `GET /api/v1/providers` | Browse the provider directory. |
| `GET /api/v1/providers/my` | List the citizen's linked providers. |
| `PUT /api/v1/providers/link` | Save the citizen's provider links. |

Analytics fields without an actual data source (live meter telemetry, solar generation, tariff, and emissions) are returned as `null` or empty collections. User-entered readings are not represented as real-time meter data or verified environmental impact.

## Platform administration

- `POST /api/v1/admin/auth/login` issues a short-lived platform, provider, or city-admin token. Platform login requires `ADMIN_EMAIL` and an scrypt `ADMIN_PASSWORD_HASH`; tenant accounts are provisioned by a platform admin.
- `GET /api/v1/admin/kpis` and `GET /api/v1/admin/providers` require a platform-admin token. Unsupported metrics are explicitly unavailable.
- `POST /api/v1/admin/tenant-admins`, `GET /api/v1/admin/tenant-admins`, and `POST /api/v1/admin/tenant-admins/:adminId/deactivate` manage tenant accounts and require a platform-admin token. Provision a provider account only for an existing provider-directory ID; city accounts receive explicit district assignments.
- `GET /api/v1/admin/tenant/me` validates the current tenant role and assignment. `GET /api/v1/admin/audit` returns platform-wide records to platform admins and tenant-scoped records to provider/city admins.
- `GET /api/v1/admin/tenant/overview` returns aggregate in-scope residents and opt-in counts for the authenticated provider or city tenant, restricted to the admin's assigned districts.
- `GET/POST /api/v1/admin/campaigns` create and list persisted campaigns. Tenant audiences are restricted to linked provider customers or residents in assigned city districts, and only citizens who opted in to campaign updates are selected. Campaigns create an in-app notification outbox; incentives are rejected until reward-ledger integration exists.
- `GET/PUT /api/v1/notifications/preferences` lets citizens manage campaign and waste-reminder consent. Both preferences default to off.
- The Flutter Settings screen syncs those preferences to the signed-in citizen account; a failed save is surfaced and does not silently change the displayed choice.
- `POST /api/v1/notifications/internal/dispatch-due` is intended for Vercel Cron and requires `Authorization: Bearer <CRON_SECRET>`. The Hobby-compatible schedule runs daily at 18:00 India time, generates next-day waste reminders for active schedules, and delivers due outbox messages at that run while rechecking consent. Due campaign messages can wait until the next daily run. This is not push notification delivery.
- `GET /api/v1/waste/schedules?district=...&ward=...&date=YYYY-MM-DD` lists currently effective public collection schedules.
- `GET/POST /api/v1/waste/admin/schedules` and `PUT /api/v1/waste/admin/schedules/:scheduleId` provide city-admin schedule management. Admins can only access their assigned districts; overlapping active schedules for the same ward and waste type are rejected.
- `POST /api/v1/admin/broadcast-alert`, `POST /api/v1/admin/send-reminder`, and `POST /api/v1/providers/:providerId/broadcast` create consent-filtered, durable in-app campaigns; they do not send push notifications.

The Next.js operator console is available at `/operator` when the frontend project is deployed. It proxies API calls server-side and stores the short-lived admin token in an HttpOnly cookie. Configure the frontend deployment's `URJA_API_URL` as the backend origin (for example `https://api.example.com`, without `/api/v1`). Deploy the backend and frontend as separate Vercel projects when using the backend's catch-all API rewrite.

## Production limitations

Mascot state, garden layouts, inventory, and coin-funded purchases are stored in PostgreSQL; purchase/refund updates are transactional, and concurrent garden edits are rejected rather than silently overwriting one another. Leaderboard snapshots and cheers are PostgreSQL-backed. Weekly league scores reflect completed learning and sorting-game rewards, not measured environmental impact; municipal rankings remain empty until district-level verified impact data exists. The global impact board uses only persisted mascot CO₂e progress. Activity and device-runtime records are stored in PostgreSQL. Device consumption derived from catalog-rated power is only an estimate, not smart-meter data. The carbon calculator uses configured/static assumptions rather than verified utility data. Push notifications, city/provider tenant administration, provider schedules, and the Next.js admin portal are not complete.

Do not treat any historical product mockup or route description as proof of production readiness. Use `/docs/json` for the exact current API contract and this section for the current data guarantees.
