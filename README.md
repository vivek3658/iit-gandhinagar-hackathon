# URJA Vatika

URJA Vatika is a prototype for **HC26-GEDA01**, GEDA's Mission LiFE citizen-engagement challenge. It explores how a sustainability companion can combine household footprint estimates, small actions, learning games, and community progress in a Flutter Android app.

This repository is a hackathon prototype, not a production-certified utility or carbon-accounting service. User-entered activity is not independently verified; calculated footprint and impact values are estimates. Automatic appliance discovery/control, live utility-provider data, and production-scale capacity have not been established by the code or tests reviewed for this submission.

## Submission documents

Start with the evidence-based [hackathon submission pack](docs/hackathon-submission/README.md). It includes:

- [Problem fit and capability status](docs/hackathon-submission/problem-fit-and-capabilities.md)
- [Architecture and data model](docs/hackathon-submission/architecture-and-data.md)
- [Scale, verification, and release notes](docs/hackathon-submission/scale-and-release.md)
- [Three-minute demo script](docs/hackathon-submission/three-minute-demo-script.md)

The original challenge summary is [PROBLEM_STATEMENT.md](PROBLEM_STATEMENT.md).

## Repository layout

| Directory | Purpose |
|---|---|
| `mobile/` | Flutter Android citizen application |
| `backend/` | Fastify v5 and TypeScript API |
| `frontend/` | Next.js operator and citizen-facing web routes |
| `docs/` | Existing project diagrams and the current submission pack |

The backend uses PostgreSQL when configured. Redis, MongoDB, and RabbitMQ clients are optional integrations; their declarations or plugin registration alone do not establish that they are provisioned in a deployed environment.

## Local development

Use the package manager and prerequisites documented by each subproject:

```powershell
cd backend
npm install
npm run dev
```

```powershell
cd frontend
npm install
npm run dev
```

```powershell
cd mobile
flutter pub get
flutter run
```

Focused validation commands:

```powershell
cd backend
npm test
npm run build
npm run lint
```

```powershell
cd mobile
flutter analyze
flutter test
```

Configure local environment values using the relevant example/configuration files; never commit credentials. The mobile app's API URL and Google OAuth client IDs are build-time configurable.

## Release status

The profile APK produced during this work is at `mobile/build/app/outputs/flutter-apk/app-profile.apk`. Profile mode is for profiling and internal testing, not the normal Play Store release mode. Android release builds now require a local upload keystore; unsigned release builds are blocked. See [scale and release notes](docs/hackathon-submission/scale-and-release.md).
