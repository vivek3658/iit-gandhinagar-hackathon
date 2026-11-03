# Problem fit and capability status

## Challenge alignment

HC26-GEDA01 asks for a citizen-facing sustainability companion that makes household impact easier to understand, offers actionable habits, encourages community participation, and connects people to useful resources. URJA Vatika's prototype focuses on that engagement loop: estimate → choose an action → learn or play → see in-app progress.

## Capability matrix

| Challenge need | Prototype evidence | Status and honest boundary |
|---|---|---|
| Personalised footprint awareness | The backend calculator accepts household activity inputs and returns a category breakdown, comparisons, and rule-based suggestions. See [calculator service](../../backend/src/modules/calculator/calculator.service.ts). | **Estimate, not measurement.** Inputs and factors are assumptions; no independent meter reading or audited carbon methodology is established. Do not present a displayed value as verified CO₂e saved. |
| Behaviour nudges and micro-tasks | Daily quests and claim flows are present in the Flutter home experience and backend routes. See [citizen home](../../mobile/lib/features/home/citizen_home_screen.dart), [quests routes](../../backend/src/modules/quests/quests.routes.ts), and [notification service](../../backend/src/modules/notifications/notifications.service.ts). | **Prototype / user-confirmed.** A completed quest is a user claim, not sensor evidence. Local reminders and an in-app feed are distinct from a provisioned push-delivery service. |
| Gamification and learning | The app has chapter progress, a waste-sorting round that uses up to 15 catalog items, game rewards, a mascot/garden experience, and leaderboard routes. See [learning service](../../mobile/lib/services/learning_service.dart), [learning screen](../../mobile/lib/features/dashboard/citizen_learning_screen.dart), and [backend app route registration](../../backend/src/app.ts). | **Implemented in the prototype.** A leaderboard's population and persistence depend on the configured backend/data; an empty or sample view must not be narrated as live statewide participation. |
| Actionable resource hub | The calculator contains rule-based action suggestions; the web and mobile projects include solar/resource content. See [calculator service](../../backend/src/modules/calculator/calculator.service.ts) and [citizen solar page](../../frontend/app/(citizen)/solar/page.tsx). | **Guidance, not a feasibility study or quote.** The current code does not establish a roof survey, provider connection, tariff lookup, or guaranteed savings. |
| Appliance/device tracking | The Flutter device screen explicitly says the user identifies and registers a device and that URJA does not scan the network or control appliances. Runtime logs use user-entered hours; rated power may be used for an energy estimate. See [registered devices screen](../../mobile/lib/features/appliances/registered_devices_screen.dart), [registry client](../../mobile/lib/services/device_registry_service.dart), and [device routes](../../backend/src/modules/devices/devices.routes.ts). | **Manual registry and self-reported logging.** Do not claim automatic BLE, Wi-Fi, mDNS, or smart-meter discovery/control based on schema values or labels. |
| Community/administrator workflows | The Next.js operator page calls server-side login/proxy routes, which forward allowlisted requests to the Fastify API when `URJA_API_URL` is configured. See [operator page](../../frontend/app/operator/page.tsx), [login handler](../../frontend/app/api/operator/login/route.ts), and [proxy handler](<../../frontend/app/api/operator/proxy/[...path]/route.ts>). | **Code path exists; deployment and end-to-end campaign delivery are not certified here.** An in-app feed entry is not proof of an Android push notification reaching every targeted user. |

## Data provenance to state in the demo

- Profile and household data come from the user's account/setup.
- Device runtime and ordinary habit claims are user-reported.
- The calculator's output is derived from entered values and code-defined factors.
- Game points represent in-app engagement; they are not a carbon-credit balance.
- Community views show only the data available to the configured backend.
- No live DISCOM, smart-meter, or general-purpose appliance-control integration was verified for this submission.

When presenting impact, say **“estimated from the information entered”**. Do not say “the app measured/verified this saving” unless a future version adds an auditable baseline, activity evidence, methodology, and validation.
