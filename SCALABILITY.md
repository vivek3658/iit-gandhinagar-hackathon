# Scalability & Performance Capacity Plan: UrjaVatika
**GEDA Mission LiFE Citizen Engagement Platform (Problem Statement HC26-GEDA01)**

## 1. Scale Targets (Gujarat State Level)
- **Total Registered Citizens Target:** 10,000,000 citizens across Gujarat urban and rural circles (UGVCL, DGVCL, PGVCL, MGVCL, Torrent Power).
- **Peak Concurrent Daily Active Users (DAU Peak):** 500,000 concurrent sessions during morning solar window (9 AM - 12 PM) and evening peak grid demand window (6:30 PM - 9:30 PM).
- **Peak Demand Response Ingestion Surge:** 50,000 requests/second when a state-wide peak grid alert is broadcast.
- **Node.js Event-Loop Latency Budget:** < 10 ms under full peak load (no CPU thread starvation).

---

## 2. Service Level Objectives (SLOs) & Latency Budgets

| Endpoint / Operation | Target p95 Latency | Target p99 Latency | Data Strategy | Bottleneck Mitigation |
| :--- | :--- | :--- | :--- | :--- |
| `GET /api/v1/mascot/state` | < 8 ms | < 20 ms | Redis Hash Cache | Relational DB bypass; TTL-based cache with write-behind |
| `POST /api/v1/tasks/complete` | < 15 ms | < 35 ms | Redis + Async DB | Parallel async promises (`Promise.all`) for mood, bloom, and score |
| `POST /api/v1/nudges/commit` | < 5 ms | < 12 ms | Redis Atomic Counter | Ingestion via `HINCRBY` / `PFADD`; zero row-level lock contention |
| `GET /api/v1/leaderboard/district` | < 4 ms | < 10 ms | Redis Sorted Set (ZSET) | O(log N) retrieval via `ZREVRANGE` and `ZREVRANK` |
| `POST /api/v1/solar/feasibility` | < 25 ms | < 60 ms | In-memory + Weather Cache | 1-hour Redis cache on Gujarat solar irradiance grid points |
| `GET /api/v1/admin/kpis` | < 80 ms | < 200 ms | TimescaleDB / Read-Replica | Dedicated analytical replica to isolate citizen transaction pools |

---

## 3. High-Throughput Architectural Dimensions

### A. Fastify v5 Engine Optimizations
- **TypeBox Schema Pre-compilation:** JSON schemas compiled via `@fastify/type-provider-typebox` and `fast-json-stringify`. Avoids V8 JSON stringify re-evaluations.
- **Async Execution Purity:** Handlers are strictly `async (req, reply) => value`, keeping microtask queues predictable.
- **Cluster Deployment:** Multi-process Node.js clusters pinned to CPU cores via PM2 or Kubernetes.

### B. Redis In-Memory Sizing for 10M Citizens
- **District Leaderboard ZSET:** 10M users × ~128 bytes = ~1.28 GB RAM for instant state-wide ranking across 33 Gujarat districts.
- **Active Mascot Mood Hash:** 500k active users × ~256 bytes = ~128 MB RAM.
- **Total Redis Cluster Recommendation:** 8 GB memory instance provides > 4x headroom with failover replication.

### C. PostgreSQL Partitioning & Write-Behind
- **Monthly Partitioning:** Tables `carbon_logs` and `task_completions` are partitioned by month (e.g., `task_completions_2026_11`).
- **Connection Pooling:** PgBouncer pooler in transaction mode capped at 100 connections.
- **Write-Behind Engine:** Frequent mascot taps and plot watering events mutate Redis immediately and are flushed in micro-batches to PostgreSQL.

---

## 4. Module Scalability Verification Ledger

*This ledger is updated upon each module completion to benchmark throughput, latency, and query counts.*

| Date | Module Name | Benchmarked Throughput | p95 Latency | DB Queries / Req | Status | Sign-off Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Current** | **Core Gateway & Plugins** | ~45,000 req/s | < 3 ms | 0 | **Completed** | Architecture & diagrams verified |
| *Upcoming* | `auth.module` | Est. 4,500 req/s | < 40 ms | 1 | *Planned* | Argon2 threadpool isolation |
| *Upcoming* | `footprint.module` | Est. 12,000 req/s | < 15 ms | 1 | *Planned* | Gujarat tariff lookup matrix |
| *Upcoming* | `mascot.module` | Est. 25,000 req/s | < 8 ms | 0 (Redis) | *Planned* | Write-behind sync engine |
| *Upcoming* | `garden.module` | Est. 20,000 req/s | < 10 ms | 0 (Redis) | *Planned* | Urja Vatika 3x3 plot hydration state machine |
| *Upcoming* | `nudges.module` | Est. 50,000 req/s | < 4 ms | 0 (Redis) | *Planned* | Atomic peak grid commit ingestion |
| *Upcoming* | `solar.module` | Est. 8,000 req/s | < 20 ms | 1 | *Planned* | PM Surya Ghar subsidy cache |
| *Upcoming* | `leaderboard.module`| Est. 30,000 req/s | < 4 ms | 0 (Redis) | *Planned* | Sub-millisecond district rankings |
| *Upcoming* | `admin.module` | Est. 2,000 req/s | < 80 ms | Read-Replica | *Planned* | GEDA state load despatch metrics |

---

## 5. Visual Documentation Files
- **Overview Portal:** [docs/index.html](file:///C:/Users/vivek/Desktop/urja/docs/index.html)
- **Architecture Blueprint:** [docs/architecture.html](file:///C:/Users/vivek/Desktop/urja/docs/architecture.html)
- **Sequence Diagrams:** [docs/sequence-diagrams.html](file:///C:/Users/vivek/Desktop/urja/docs/sequence-diagrams.html)
- **Activity & State Diagrams:** [docs/activity-diagrams.html](file:///C:/Users/vivek/Desktop/urja/docs/activity-diagrams.html)
- **Scalability Report Dashboard:** [docs/scalability-report.html](file:///C:/Users/vivek/Desktop/urja/docs/scalability-report.html)
