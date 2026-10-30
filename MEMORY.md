# UrjaVatika Project Memory & Session State
> **Platform:** GEDA Mission LiFE Citizen Engagement Platform  
> **Problem Statement:** `HC26-GEDA01` (Track 1: Green Energy & Sustainability)  
> **Host Agency:** Gujarat Energy Development Agency (GEDA)  
> **Architecture:** Fastify v5 Modular Monolith + Redis 7 + PostgreSQL 16 (Primary + Read Replica) + MongoDB 7 (rs0) + RabbitMQ 3 + NGINX Gateway  
> **Target Capacity:** 100,000 concurrent writes / sec, 500,000 reads / sec on 4–6 app containers  
> **Last Updated:** October 30, 2026

---

## 1. Executive Summary & Core Rules

1. **Dual Economy (XP vs Coins):**
   * **Mascot Level & EXP:** Earned **strictly via calculated $CO_2e$ saved**. 
     $$\text{EXP} = \text{kg } CO_2e \times 100 \quad (10\text{g } CO_2e = 1\text{ EXP})$$
     Mascot level-ups can NEVER be purchased with coins.
   * **Urja Mudra Coins:** Earned via verified daily green habits (watering plants, turning off idle switches, garbage sorting mini-game). Coins are spent **only on wardrobe accessories ($\ge 100$ coins) and garden decor**.
2. **Official Gujarat Emission Baseline:**
   * **Electricity Grid Factor:** $0.82 \text{ kg } CO_2e \text{ per kWh}$ (CEA India Baseline Database for Gujarat DISCOMs: DGVCL, MGVCL, PGVCL, UGVCL).
   * **Urban Commute:** $0.058 \text{ kg } CO_2e \text{ per km}$ saved by substituting 125cc petrol bike with walking/metro/EV.
   * **Red Light Idle:** $0.024 \text{ kg } CO_2e \text{ per minute}$ avoided by cutting engine at traffic lights.
   * **Municipal Water:** $0.00035 \text{ kg } CO_2e \text{ per Liter}$ of treated municipal water conserved.
3. **Mascot Identity:**
   * Primary mascot: **Chibi House Sparrow (ચકલી / Gauraiya)** with a signature 2-leaf green head sprout.
   * Secondary switchable mascot: **Squirrel (ખિસકોલી / Chiku)**.

---

## 2. Mascot & 3D Studio Implementation

### A. Backend Mascot Module (`src/modules/mascot/`)
* **State Machine:** Tracks `mascotName`, `mascotType`, `level`, `currentExp`, `nextLevelExp`, `mood`, `co2SavedKg`, `growthPoints`, `equippedAccessories` (`head`, `neck`, `body`).
* **Endpoints:**
  * `GET /api/v1/mascot/state`: Real-time mascot status + dynamic contextual speech dialogue.
  * `PATCH /api/v1/mascot`: Rename or switch mascot.
  * `POST /api/v1/mascot/interact`: Pet, feed, or nudge mascot (+mood, +cooldown).
  * `GET /api/v1/mascot/wardrobe`: Catalog of accessories with purchase status.
  * `POST /api/v1/mascot/wardrobe/buy`: Purchase accessories with Urja Mudra coins ($\ge 100$).
  * `POST /api/v1/mascot/wardrobe/equip`: Equip or unequip wardrobe slots.
* **Dialogue Engine:** Dynamic speech generation reacting to time of day, battery state, AC temperature, and geofence departures.

### B. Interactive 3D Mascot Studio (`docs/sparrow-animator.html`)
* **Problem Solved:** The user's AI-generated mesh (`0224df49-730f-4a5f-96a0-0344e73e9dfb.glb`) had fused the sparrow and rock perch into one static lump of geometry (`geometry_0`), making dynamic animation impossible.
* **Solution Built:**
  1. **Articulated Chibi Rig:** Built a clean, fully textured, procedural 3D sparrow matching the exact colors from `EcoNest Sparrow Mascot Design Sheet.png`:
     * Chestnut brown back/cap (`#945228`), soft cream beige belly (`#faebd7`), rosy cheeks (`#fca5a5`), anime eyes with white highlights, orange beak, and green head sprout (`#22c55e`).
     * **Zero Rock:** Completely standalone character with feet grounded on the floor plane.
  2. **Independent Pivot Anatomy:**
     * **Flapping Wings:** Left and right wings have independent shoulder pivots and flap dynamically during hops and victory leaps.
     * **Head Tilt:** Head tilts $25^\circ$ sideways independently while feet stay firmly planted.
  3. **GSAP Cartoon Easing:**
     * `Idle Breathe`: Subtle squash & stretch ($y: 0.96 \leftrightarrow 1.04$) and sprout sway.
     * `Happy Hop`: Double bounce (`bounce.out`) + wing flutter + shadow squashing.
     * `Curious Tilt`: $25^\circ$ head cock + look up.
     * `Victory Leap`: High leap ($+0.85\text{m}$) + $360^\circ$ spin + continuous wing flaps.
     * `Resting Nest`: Tucks head into chest with slow 2.2s breathing.
  4. **Zero-CORS Loading:** Model data encoded into `docs/assets/sparrow-data.js` so double-clicking `docs/sparrow-animator.html` in Chrome/Edge opens instantly with zero browser CORS errors.
  5. **1-Click GLB Export:** Built-in `GLTFExporter` allows downloading `EcoNest_Sparrow_Colored.glb` directly.

---

## 3. Garden Module Design & Specifications

### A. Level-Gated Grid Growth
The garden land expands dynamically based on the mascot's verified $CO_2e$ level:
* **Level 1:** $3 \times 3$ grid (9 tiles) — Beginner nest
* **Level 10:** $4 \times 4$ grid (16 tiles) — Small garden
* **Level 25:** $5 \times 5$ grid (25 tiles) — Homestead
* **Level 40:** $6 \times 6$ grid (36 tiles) — Micro-farm
* **Level 50:** $7 \times 7$ grid (49 tiles) — Community sanctuary
* **Level 75:** $8 \times 8$ grid (64 tiles) — Botanical estate
* **Level 90:** $9 \times 9$ grid (81 tiles) — Energy reserve
* **Level 100:** $10 \times 10$ grid (100 tiles) — Lifetime Green Legend

### B. Grid Constraints
* **Footprint:** Strictly **$1 \times 1$ square tiles** (no complex multi-tile collision bugs).
* **Rotation:** 4-way $90^\circ$ limit (`0°`, `90°`, `180°`, `270°`) requiring only 2 bits of storage.
* **Core Tiles:**
  1. *Renewables:* Mini Solar Petal, Mini Kinetic Windmill, Solar Lantern, Compost Tumbler.
  2. *Water:* Lily Pond Tile, Stone Recharge Well, Drip Crop Plot, Rainwater Recharge Pit, Wooden Footbridge.
  3. *Flora:* Sacred Tulsi Altar, Young Neem Tree, Pollinator Flower Patch, Rose Bush.
  4. *Paths & Decor:* Cobblestone Way, Timber Deck, Rammed Earth, Picket Fence, Solar Bird Bath, Wooden Birdhouse, Garden Bench.

### C. Scalability Design for 100k Writes / 500k Reads
* **Bottleneck Mitigation:**
  * Direct SQL writes would exhaust connection pools during burst traffic.
  * **Redis Atomic Lua Script:** Validates coin balance, mascot level, grid boundary, and tile occupancy in $< 0.4\text{ms}$. Deducts coins and updates `garden:{userId}` in Redis memory.
  * **Write-Behind Worker:** Pushes `garden.tile_placed` event to RabbitMQ. Background consumers batch upsert 500 tiles/query into PostgreSQL.
  * **500k Reads/sec:** Satisfied 100% from Redis in-memory cache or NGINX edge caching (< 2 KB gzipped).

---

## 4. Behavioral Micro-Nudges (`BEHAVIORAL_NUDGES.md`)

Zero-hardware ambient nudges utilizing smartphone sensors:
1. **Geofence Departure:** Detects Wi-Fi disconnect + GPS leaving home $\rightarrow$ In-app nudge: *"Leaving home? Checked: Fans & geyser are turned OFF!"*
2. **AC 24°C Optimization:** Nudges user to set AC thermostat to 24°C before sleep $\rightarrow$ Saves 2.4 kWh ($1.97\text{ kg } CO_2e$ / night).
3. **Traffic Red-Light Idle Digest:** Aggregates stop duration from accelerometer $\rightarrow$ Post-trip nudge showing liters of petrol saved by cutting the engine at red lights.
4. **Municipal Water Timing:** Notifies citizens 15 minutes before scheduled municipal water supply window to prevent overflow and tank wastage.
5. **Pre-Sleep Shutdown:** 10:30 PM reminder to switch off Wi-Fi router, TV set-top box, and chargers.

---

## 5. File Inventory & Current Status

### Key Project Files:
* `src/app.ts`: Fastify v5 application builder, registered plugins, central error handler.
* `src/modules/health/`: Liveness and readiness health checks.
* `src/modules/auth/`: Google OAuth, profile completion, JWT refresh rotation, account deletion.
* `src/modules/media/`: ImageKit HMAC-SHA1 signature generator.
* `src/modules/mascot/`: Mascot state machine, wardrobe store, and speech dialogue engine.
* `BEHAVIORAL_NUDGES.md`: Catalog of phone sensor zero-hardware triggers.
* `docs/index.html`: Visual documentation portal dashboard.
* `docs/sparrow-animator.html`: Interactive 3D Mascot Studio (Three.js + GSAP).
* `docs/assets/sparrow.glb`: Raw generated AI model.
* `docs/assets/sparrow-data.js`: Zero-CORS Base64 model loader.
* `docs/garden-studio.html`: Interactive 3D Garden & Mascot Studio (Three.js + GSAP).
* `mobile/`: Clean Flutter cross-platform mobile client (`urja`).
* `FRONTEND_RULES.md`: Complete Frontend Engineering standards & Feature-First architecture guide.
* `src/modules/garden/`: Garden module (31-tile catalog, ghost preview, buy/place, inventory, 80% resale).
* `test/health.test.ts`, `test/auth.test.ts`, `test/mascot.test.ts`, `test/garden.test.ts`, `test/scalability.test.ts`: Automated test suites.

### Test & Build Verification:
* `npm test`: **24/24 tests passing** across all 5 suites.
* `npm run lint`: **0 errors, 0 warnings**.
* `npm run build`: **0 TypeScript compilation errors**.
* Scalability throughput: **~1,850 - 2,800 req/sec** sustained on single-core harness.

---

## 6. Where We Stand & Next Steps

* **Current State:**
  * Core architecture, Auth, Mascot state machine (12 canonical expressions & active props), Behavioral Nudges, and 3D Character Studio are fully operational.
  * Mobile Flutter project initialized in `./mobile` with package name `urja`.
  * Complete Frontend Architectural Blueprint established in `FRONTEND_RULES.md`.
  * Garden module is fully implemented in backend with atomic validation, inventory preservation, and 80% coin recovery liquidation.
  * Interactive 3D Web Studio (`docs/garden-studio.html`) is live with ghost tile placement, 4-way 90° rotation, inventory drawer, and mascot animations.
* **Pending Next Steps:**
  * Implement Flutter UI widgets & Riverpod state providers for Garden & Mascot WebView bridge in `./mobile`.
  * Implement Background RabbitMQ consumer worker for batch upserting garden events to PostgreSQL.
  * Git commit after user review.
* **Git Status:** All new and updated files remain uncommitted per working agreement until explicit user approval.
