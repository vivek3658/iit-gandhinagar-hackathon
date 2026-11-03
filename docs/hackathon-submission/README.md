# HC26-GEDA01 submission pack

**Project:** URJA Vatika
**Challenge:** Gujarat Energy Development Agency (GEDA), Mission LiFE citizen engagement
**Purpose:** Judge-facing overview of the prototype, its actual evidence, and its limits.

## Documents

1. [Problem fit and capability status](problem-fit-and-capabilities.md)
2. [Architecture and data model](architecture-and-data.md)
3. [Scale, verification, and release notes](scale-and-release.md)
4. [Three-minute team-lead demo script](three-minute-demo-script.md)

The challenge summary is [PROBLEM_STATEMENT.md](../../PROBLEM_STATEMENT.md). These submission documents supersede older project descriptions when their feature or capacity claims conflict.

## Snapshot and release hygiene

- The architecture view is expressed in Mermaid in [architecture and data model](architecture-and-data.md).
- The working tree also contains uncommitted changes across the backend, frontend, Flutter app, and database schema. The documents describe the inspected prototype, but they are **not a statement that all those changes are in the pinned commit**.
- The profile APK was generated at `mobile/build/app/outputs/flutter-apk/app-profile.apk` (94,754,753 bytes). It is a local build output, not checked into this document pack and not tied to a recorded source commit. Rebuild from the final committed tree before publishing it.
- Android release builds require a local upload keystore. A profile APK is suitable for internal profiling/demo distribution, not a properly signed Play Store release.

## How to describe results

Use “estimate” for footprint or avoided-emissions values derived from entered data. Use “self-reported” for logged/claimed actions and appliance runtime. Say “implemented in the prototype” for code paths, not “deployed,” “live,” “verified,” or “at scale” unless the relevant environment and evidence have been independently checked.
