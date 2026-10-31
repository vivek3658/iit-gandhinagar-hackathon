# Urja — Next.js App Router frontend

A proper **multi-route Next.js + TypeScript** prototype of the Mission LiFE citizen app. All 14 original Urja WebP assets are in `public/assets`.

## Run

```bash
npm install
npm run dev
npm run typecheck
npm run build
```

Open http://localhost:3000. `/` redirects to `/story`.

## Routes

- `/story` guided lessons and onboarding
- `/garden` your evolving illustration
- `/missions` daily tasks and seven-day habit experiment
- `/impact` consumption diary and estimates
- `/explore` route directory
- `/tips` simple suggestions
- `/reminders` time-of-day suggestions
- `/community` sample leaderboard and local activity
- `/solar` rough rooftop solar estimate
- `/resources` information portals
- `/admin-demo` explicitly labeled illustrative administrator preview; `/admin` is disabled (404) until a real authenticated backend exists
- `/settings` export and reset local data

## Architecture

- `app/`: URL routing, route-group layout, metadata, minimal entry pages
- `features/`: independent screen components
- `components/`: reusable presentation and navigation
- `contexts/`: typed state and local persistence (replace with API later)
- `lib/`: pure calculations, date utilities, browser storage
- `data/`: chapters, challenges, example data and resources
- `types/`: domain models
- `public/assets/`: original Urja character and garden assets

**Demo limitations:** No backend, true multi-user features, verified actions, real-time notifications, or authenticated GEDA account. Community and admin values are marked as sample data; estimates are illustrative. Do not claim these are live values.

## Verification

Project source has been reorganized into true App Router pages; a complete Next.js build should be run locally with dependencies installed. Unlike earlier versions, this does not bundle one large imperative HTML engine.

## Production checklist and verification

- Strict TypeScript enabled. Run `npm install && npm run typecheck && npm run build` before deployment.
- `/admin` intentionally returns 404: do NOT treat client-side passwords or middleware-only checks as authorization. Add server-side sessions, role checks, and protected APIs before enabling real admin features.
- Current storage is device-local; browser clearing or switching devices loses progress. This is **not** synchronized user data.
- Dashboard and community data are examples only; there is no verified data pipeline or push notification service.
- Next Image optimization requires the selected deployment platform to support image transformations.
- Install and commit a lockfile in a network-enabled environment if none is present.
- Build and end-to-end browser testing still need to be executed in an environment with installed Next.js dependencies.
