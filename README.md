# URJA Vatika

URJA Vatika is a prototype for **HC26-GEDA01**, GEDA's Mission LiFE citizen-engagement challenge. It explores a sustainability engagement loop: household-impact estimates, practical actions, learning and sorting games, and community progress.

This is a hackathon prototype, not a production-certified utility or carbon-accounting service. User-entered activity is not independently verified; footprint and impact values are estimates. Automatic appliance discovery/control, live utility-provider data, and production-scale capacity have not been established.

## Hackathon submission

- [Problem fit and capability status](CAPABILITIES.md)
- [Architecture and data model](ARCHITECTURE.md)
- [Three-minute demo script](DEMO_SCRIPT.md)
- [Release and scale evidence](RELEASE.md)
- [Submission overview and presentation guidance](SUBMISSION.md)
- [Original challenge summary](PROBLEM_STATEMENT.md)

## Project

| Directory | Purpose |
|---|---|
| `mobile/` | Flutter Android citizen application |
| `backend/` | Fastify v5 and TypeScript API |
| `frontend/` | Next.js operator and citizen-facing web routes |
| `docs/reference/` | Detailed implementation and project notes |
| `docs/archive/` | Preserved visual prototypes and legacy notes |

Browse [detailed project references](docs/reference/README.md). For developer setup, see [backend/DEPLOYMENT.md](backend/DEPLOYMENT.md), [frontend/README.md](frontend/README.md), and [mobile/README.md](mobile/README.md). Never commit credentials or local signing material.

Android release builds require a local upload keystore; unsigned release builds are blocked. A profile APK is for profiling/internal testing, not a normal Play Store release. See [RELEASE.md](RELEASE.md).
