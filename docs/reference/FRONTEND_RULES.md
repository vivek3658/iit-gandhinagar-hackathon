# UrjaVatika: Frontend Engineering Guidelines & Architecture Rules

> **Target App:** `urja` (Flutter Mobile & Cross-Platform Web)  
> **Agency:** Gujarat Energy Development Agency (GEDA) — Mission LiFE Citizen Platform  
> **Version:** 1.0.0  
> **Updated:** October 30, 2026

---

## 1. Architectural Philosophy: Feature-First & Reactive Clean Architecture

To ensure code modularity, rapid testability, and painless onboarding for both human developers and autonomous AI coding agents, all code inside `mobile/lib/` must adhere strictly to **Feature-First Clean Architecture**.

### Directory Structure
```
mobile/lib/
├── app.dart                     # MaterialApp entrypoint, global theme, routing config
├── main.dart                    # main() function, environment bootstrap, runZonedGuarded
├── core/                        # Shared, feature-agnostic infrastructure
│   ├── constants/               # Emission factors (0.82 kg/kWh), asset paths, district list
│   ├── network/                 # Dio client, JWT auth interceptor, 401 silent token refresher
│   ├── storage/                 # Encrypted FlutterSecureStorage wrapper (key-value tokens)
│   ├── theme/                   # UrjaVatika design system (colors, typography, spacing, shadows)
│   ├── utils/                   # CO2-to-EXP calculators, currency formatters, date helpers
│   └── widgets/                 # Reusable atomic UI (UrjaButton, MudraBadge, DialogueBubble)
└── features/                    # Self-contained business modules
    ├── auth/                    # 1-Click Google OAuth, Onboarding, District selection
    │   ├── data/                # AuthRemoteSource, AuthRepositoryImpl
    │   ├── domain/              # UserEntity, AuthRepository contract
    │   └── presentation/        # LoginScreen, OnboardingScreen, AuthNotifier
    ├── mascot/                  # 3D Chibi Sparrow companion, expressions, speech engine
    │   ├── data/                # MascotRemoteSource, WardrobeService
    │   ├── domain/              # MascotState, ExpressionEnum, AccessoryEntity
    │   └── presentation/        # Sparrow3DStage (WebView bridge), SpeechBubble, WardrobeShopModal
    ├── garden/                  # Sanctuary land grid (3x3 to 10x10), tile placement & inventory
    │   ├── data/                # GardenRemoteSource, TileCatalog
    │   ├── domain/              # GardenGrid, TilePlacement, InventoryItem
    │   └── presentation/        # GardenCanvas, GhostTilePreview, InventoryDrawer, ResaleDialog
    ├── nudges/                  # Zero-hardware phone sensor listeners & scheduled alerts
    │   ├── listeners/           # BatteryChargeListener, HomeDepartureListener, RedLightIdleListener
    │   └── presentation/        # NudgeSnackBar, EcoActionCard
    └── leaderboard/             # Gujarat district & ward rankings
        ├── data/                # LeaderboardRemoteSource
        └── presentation/        # DistrictPodium, WardRankingList
```

---

## 2. Mascot & 3D Stage Rules: Expression State Machine

The Sparrow mascot is a living, emotional guide. It must never feel like a static sprite.

### A. The 12 Canonical Expression Poses
The 3D stage (`EcoNest Sparrow 3D`) runs a procedural rig capable of 12 distinct poses:

| Pose Key | Category | Trigger / Context | Key Rig Attributes |
| :--- | :--- | :--- | :--- |
| `tpose` | Debug | Initial mesh calibration | Default neutral wings, open eyes |
| `happy` | General Mood | Vitality $50\text{--}79$, steady progress | Gentle breathing loop, warm eye curves, open smile |
| `excited` | General Mood | Vitality $\ge 80$, logging high $CO_2$ drop | Rapid wing flaps, hops, sparkle particle halo |
| `curious` | Interaction | User taps mascot on screen | $25^\circ$ sideways head cock, scanning eyes |
| `thinking` | Interaction | Opening calculators or viewing tariff tips | Head tilted up, slower blink, contemplation |
| `cheering` | Interaction | Completing daily habits or sorting waste | Double hop, victory spin, wing high-flutters |
| `resting` | General Mood | Vitality $25\text{--}49$, evening idle | Tucks head into chest, low breathing |
| `planting` | In-App Action | Citizen buys/places tree, crop, or flower | Leaning forward, holding `sapling` prop |
| `watering` | In-App Action | Water conservation habit logged | Tilting `can` prop with falling water `drops` |
| `celebrating`| Milestone | Leveling up or unlocking new grid expansion | Continuous backflips, `confetti` & `sparks` |
| `exploring` | In-App Action | Expanding garden boundary | Wide horizontal head scan, alert posture |
| `nest` | Bedtime/Idle | Vitality $< 25$ or 10:30 PM bedtime nudge | Resting in twig nest with floating `zzz` cloud |

### B. Flutter-to-Three.js Two-Way Communication Bridge
When embedding the 3D model in Flutter using `webview_flutter`:
1. **Flutter to JavaScript:**
   ```dart
   void triggerSparrowPose(String pose) {
     webViewController.runJavaScript("Sparrow.set('$pose');");
   }
   ```
2. **JavaScript to Flutter:**
   The webview communicates user taps on the 3D canvas back to Dart using a named `JavascriptChannel`:
   ```javascript
   // Inside HTML canvas tap handler:
   if (window.SparrowChannel) {
     SparrowChannel.postMessage(JSON.stringify({ event: 'TAP_MASCOT' }));
   }
   ```

---

## 3. Garden Grid Architecture & Citizen Workflow Rules

### A. Level-Gated Grid Growth
Land availability is strictly controlled by the mascot's verified $CO_2e$ level:
$$\text{Grid Size} = \begin{cases} 
3 \times 3 & \text{Level } 1\text{--}9 \\
4 \times 4 & \text{Level } 10\text{--}24 \\
5 \times 5 & \text{Level } 25\text{--}39 \\
6 \times 6 & \text{Level } 40\text{--}49 \\
7 \times 7 & \text{Level } 50\text{--}74 \\
8 \times 8 & \text{Level } 75\text{--}89 \\
10 \times 10 & \text{Level } 90\text{--}100
\end{cases}$$

### B. Interactive Preview-Before-Buy Workflow
To prevent buyer's remorse and accidental point expenditure:
```mermaid
flowchart TD
    SHOP[Citizen opens Garden Catalog] --> PICK[Picks tile: e.g. Glass Greenhouse 650 🍃]
    PICK --> GHOST[Enters Ghost Preview Mode on Grid]
    GHOST --> ROTATE[Citizen taps ⟳ Rotate 90° to test angles]
    ROTATE --> POSITION[Citizen taps valid coordinate x, y]
    POSITION --> REVIEW{Is cell empty and within level bounds?}
    REVIEW -- No --> RED_GLOW[Cell glows RED: Coordinate locked or out of bounds]
    REVIEW -- Yes --> GREEN_GLOW[Cell glows GREEN: Valid position]
    GREEN_GLOW --> ACTION_BAR[Bottom Sheet: 'Buy & Place (650 🍃)' or 'Cancel']
    ACTION_BAR --> CONFIRM[Citizen taps 'Confirm Buy & Place']
    CONFIRM --> API_CALL[Calls POST /api/v1/garden/buy-and-place]
    API_CALL --> ATOMIC_SUCCESS[Redis Lua deducts coins & places tile permanently]
```

### C. Inventory & 80% Resale Mechanism
1. **Removal to Inventory:** Citizens can long-press or tap any placed tile and choose **"Store in Inventory"**. The tile is removed from the grid and added to `citizen.inventory[tileId]`. Placed assets are **never lost**.
2. **Repositioning:** Tiles in inventory can be placed back onto the grid at any time for **0 additional coins**.
3. **80% Resale Liquidation:**
   * If a citizen wishes to permanently liquidate an unwanted tile from their inventory, they can tap **"Sell for 80% Refund"**.
   * Formula:
     $$\text{Refund Coins} = \lfloor \text{Catalog Price} \times 0.80 \rfloor$$
   * Example: A 500-coin Solar Flower returns **400 Urja Mudra coins** upon resale. Small 100-coin picket fences return **80 coins**.

---

## 4. Pricing & Economic Tiering Rules

The catalog is divided into clear pricing tiers to give meaningful progression:

| Tier | Category | Price Range | Sample Tiles | Gameplay Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Micro / Utility** | Paths & Fences | $50\text{--}120\text{ coins}$ | Picket Fence (100), Cobblestone Path (100), Rammed Earth (100), Meadow Grass (50) | Affordable cosmetic pathways for beginners |
| **Flora & Water** | Agriculture & Greenery | $200\text{--}400\text{ coins}$ | Sacred Tulsi Altar (250), Vegetable Plot (300), Apple Tree (350), Lily Pond (400) | Creates natural habitats for birds and bees |
| **Major Structures** | Buildings & Green Tech | $500\text{--}800\text{ coins}$ | Sparrow Home (500), Solar Flower (500), Glass Greenhouse (650), Kinetic Windmill (750) | High-value sustainability showpieces |
| **Civic Monuments** | High-Level Estates | $1,000\text{--}1,500\text{ coins}$ | Village Bio-Digester (1,000), Sacred Banyan Tree (1,200), Freedom Tree (1,500) | Late-game prestige achievements for top citizens |

---

## 5. Network & Authentication Resilience

1. **Tokens:**
   * Access Token: 15 minutes lifetime, stored in-memory (Riverpod `StateNotifier`).
   * Refresh Token: 30 days lifetime, stored strictly in `flutter_secure_storage`.
2. **Silent 401 Recovery:**
   * Dio Interceptor automatically pauses queued requests on `401 Unauthorized`, calls `POST /api/v1/auth/refresh`, updates the token header, and replays failed requests without kicking the citizen to the login screen.
3. **Offline Caching:**
   * The citizen's mascot state, speech dialogue, and garden grid layout must be cached locally in `Hive` or `Isar` database so the 3D sanctuary renders instantly with 0ms delay even when the device is offline or in rural Gujarat areas with intermittent connectivity.

---

## 6. Working Agreement for Frontend Developers
* Always run `flutter analyze` and `flutter test` before committing.
* Never commit hardcoded API keys or localhost IPs; use `.env` via `flutter_dotenv`.
* Keep widget trees shallow using smaller sub-widgets with `const` constructors for 60/120 FPS performance on budget Android devices.
