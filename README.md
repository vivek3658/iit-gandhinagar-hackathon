# Urja ONE

Urja ONE is a prototype for **HC26-GEDA01**, GEDA's Mission LiFE citizen-engagement challenge. The Flutter app brings household-impact estimates, practical actions, learning games, and a playful virtual sanctuary together.

This is a hackathon prototype, not a production-certified utility or carbon-accounting service. User-entered activity is not independently verified; footprint and impact values are estimates. Automatic appliance discovery/control, live utility-provider data, and production-scale capacity have not been established.

## Explore

[Interactive project guide](docs/index.html) · [Garden studio](docs/garden-studio.html) · [Sparrow animator](docs/sparrow-animator.html) · [Architecture](ARCHITECTURE.md)

<details>
<summary>What can I explore in the app?</summary>

- **Sparrow companion:** an interactive 3D mascot with mood, vitality, and petting interactions.
- **Wardrobe and accessories:** preview and equip items across headwear, face, neck, held-item, and outfit categories.
- **Garden island:** arrange a 3D garden around the Sparrow home and manage garden items.
- **Impact and activities:** review estimated energy and carbon impact, complete sustainability quests, and explore learning and waste-sorting games.

</details>

<details>
<summary>Project docs and demos</summary>

- [Problem fit and capability status](CAPABILITIES.md)
- [Architecture and data model](ARCHITECTURE.md)
- [Release and scale evidence](RELEASE.md)
- [Submission overview and presentation guidance](SUBMISSION.md)
- [Original challenge summary](PROBLEM_STATEMENT.md)
- [Visual documentation index](docs/index.html)
- [Detailed project references](docs/reference/README.md)

</details>

## Project

| Directory | Purpose |
|---|---|
| `mobile/` | Flutter Android citizen application |
| `backend/` | Fastify v5 and TypeScript API |
| `frontend/` | Next.js operator and citizen-facing web routes |
| `docs/reference/` | Detailed implementation and project notes |
| `docs/archive/` | Preserved visual prototypes and legacy notes |

For developer setup, see [SETUP.md](SETUP.md). For deployment-specific backend and web setup, see [backend/DEPLOYMENT.md](backend/DEPLOYMENT.md) and [frontend/README.md](frontend/README.md). Never commit credentials or local signing material.

Android release builds require a local upload keystore; unsigned release builds are blocked. A profile APK is for profiling/internal testing, not a normal Play Store release. See [RELEASE.md](RELEASE.md).
