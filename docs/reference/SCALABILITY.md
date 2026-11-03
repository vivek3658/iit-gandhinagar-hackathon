# Scale readiness: evidence, limits, and next steps

## Current evidence

The backend is a Fastify v5 application that registers feature routes and optional infrastructure plugins. PostgreSQL can be configured through `DATABASE_URL`; in non-production configurations, selected services can use in-memory state when the database is absent. Redis, MongoDB, and RabbitMQ clients are optional and have fallback behavior.

This repository has **no verified production-capacity result**. Do not treat any throughput, concurrent-user, latency, or availability target in an old diagram, comment, or test title as measured capacity.

The existing [`scalability.test.ts`](../../backend/test/scalability.test.ts) test uses Fastify's in-process `inject()` API against several app objects. It does not measure a deployed network, independently provisioned application instances, real shared PostgreSQL/Redis, an edge cache, or end-to-end production traffic. Its hard-coded architecture assumptions and capacity calculations are not benchmark evidence.

## What is and is not established

- **Established in code:** Fastify route registration; a bounded PostgreSQL connection pool when configured; development/test fallbacks for some services.
- **Not established by configuration alone:** a multi-instance deployment, configured and healthy shared infrastructure, a production load balancer/cache, failover, backup/restore, or operational monitoring.
- **Not load-tested:** throughput, latency under realistic traffic, concurrency limits, database saturation, or recovery during dependency failure.
- **Not an architectural guarantee:** the maximum connection count of a database pool does not imply a request-rate or user-capacity result.

See the fuller [scale and release evidence](../../RELEASE.md) and [architecture diagram](../../ARCHITECTURE.md).

## Responsible next steps

Before making a capacity claim, provision the intended shared services and deployable topology; run repeatable network-level load tests with representative authenticated reads and writes; capture requests/second, p50/p95/p99 latency, error rate, resource use, and dependency health; test instance and database failure; and publish the environment, workload, test duration, and raw results. Until that is done, describe scale-out as a **future validation and deployment plan**, not a current capability.
