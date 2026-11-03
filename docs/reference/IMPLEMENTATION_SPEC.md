# UrjaVatika: Implementation Spec (Android-only, no extra hardware)
**GEDA Mission LiFE Citizen Platform (HC26-GEDA01)**
Flutter app + Kotlin platform channels + Fastify backend.

---

## 0. How to use this file with Gemini CLI

1. Give Gemini CLI **one phase at a time** (Section 17). Do not paste the whole file and ask for everything.
2. After each phase: run the tests, run the app on a real Android phone, check the acceptance criteria, then commit.
3. **Never let the agent invent data.** Emission factors, device specs, BEE values and tariff slabs must come from a cited source. If a value is unknown, store `null` and a `TODO(source)` marker.
4. Android only. Ignore iOS for now. Do not add iOS code paths.
5. No extra hardware (no smart plugs, no meters, no NFC stickers). Everything uses the phone, its sensors, its IR blaster (if present), Wi-Fi, Bluetooth, and public data.

---

## 1. Principles

1. **Be honest about evidence.** Every credited action carries an evidence tier and a confidence label. Never show "verified" for something the phone only guessed.
2. **Compute, don't hardcode.** CO2e = kWh x emission factor, where kWh comes from the user's actual device model, runtime, and conditions.
3. **Counterfactual only.** Credit savings against what *this household* would otherwise have done, not a national average.
4. **Show ranges.** Present CO2e as low-high, with a label (`verified`, `estimated`, `self-reported`).
5. **Privacy by design (DPDP Act 2023).** Home SSID, GPS, device inventory and the household-to-model mapping stay on the phone (encrypted). The backend gets only summaries.
6. **Keystone first.** The AC is the biggest lever (roughly 100x a phone charger per hour). Build the AC path properly; the small nudges plug in later.
7. **Small habits are habit anchors, not carbon claims.** A phone charger left plugged in is roughly 10 Wh (about 7 g CO2e). Reward with Mudra/Sparrow progress, not kg.

---

## 2. Scope and non-goals

**In scope (v1):** AC tracking and nudges, device model catalog, IR control (where the phone has an IR blaster), presence detection (Wi-Fi/geofence), bill OCR and calibration, notification rules engine, local ledger, summary sync.

**Out of scope (v1):** iOS, external hardware, scanning other people's devices, reading other apps' notifications, any audio recording stored on device or server, per-appliance NILM.

**Optional later:** acoustic AC check (pilot only), smart-meter CSV import, smart-AC cloud APIs, OBD, ward leaderboards.

---

## 3. Evidence model

| Tier | Meaning | Examples | Default weight |
|---|---|---|---|
| A: `verified` | The phone itself saw it | Charger unplugged after full charge; left home Wi-Fi | 1.0 |
| B: `command_sent` | The app sent an IR command (no acknowledgment) | App sent AC "off" or "24 C" | 0.7 (tune in pilot) |
| C: `estimated` | Tap plus supporting context | "AC off" tap, phone at home, night, after a nudge | 0.6 |
| D: `self_reported` | Bare tap | "I switched the engine off" | 0.3, capped per day |
| Ground truth | Monthly bill reconciliation | OCR kWh vs weather-normalized baseline | Adjusts household weights |

Weights above are starting values. Store them in `assets/evidence_weights.json`, versioned, and tune them from pilot data.

**Anti-gaming rules**
- One claim per action per day per household.
- Do not credit an action for a device the household has not registered.
- Household mode: several phones, one AC, credited once.
- Daily cap on `self_reported` credit.
- If bill calibration shows claimed savings do not appear after 2 months, shrink that household's weights.

---

## 4. Architecture

```
Android sensors/receivers (Kotlin) --> Event Bus (Dart)
       |                                   |
   Presence                          Rules Engine (JSON)
   (Wi-Fi/geofence)                        |
                                    Nudge Scheduler --> Notification actions
                                           |
 DeviceRegistry <-- Catalog (offline)      v
       |                            AcBeliefEngine --> Evidence + CreditCalculator
   IrService (command_sent)                |
                                           v
                          Local Ledger (Drift/SQLite, encrypted)
                                           |
                                    Outbox (changes + hourly heartbeat)
                                           |
                                        Fastify
```

Android notes: Android's periodic WorkManager minimum is 15 minutes, so do not depend on 10-minute polling. Prefer event-driven sources (power connected, network callbacks, geofence transitions). Use WorkManager only for housekeeping and heartbeat.

---

## 5. Local data model (Drift / SQLite, encrypted)

**device_registry**
`id, category, room, catalog_id, catalog_version, discovered_via (json), sense (none|inferred|local_state|cloud_state), control (none|ir_send|local_api), kw_rated, evidence_ceiling, user_confirmed, created_at`

**command_log**
`id, ts, device_id, state_json {power, mode, tempC, fan}, evidence ('command_sent'), synced`

**events** (event bus journal)
`id, ts, type, payload_json, synced`

**ledger**
`id, action_id, ts, device_id, evidence_tier, confidence_label, quantity, unit, ef_id, ef_version, catalog_id, catalog_version, co2e_kg_low, co2e_kg_high, household_id, synced`

**baseline**
`device_id, date, outdoor_temp_c, cooling_degree_hours, estimated_runtime_h, estimated_kwh`

**bills**
`id, period_start, period_end, kwh, source ('ocr'|'manual'), image_ref (local only), created_at`

**Outbox event (what the backend receives)**
```json
{"household":"anon-id","type":"action_credited","ts":"...",
 "action":"ac_off_on_leave","tier":"B","label":"estimated",
 "co2e_kg":[0.4,0.6],"ef_version":"2026-01","catalog_version":3}
```
Never send: SSID, GPS, address, raw device inventory, photos.

---

## 6. Emission factors (`assets/emission_factors.json`, versioned)

Format per entry: `{id, value, unit, source, year, version, note}`.

Starting values to **verify against the latest official source before demo**:
- Grid electricity: about 0.71 kg CO2e/kWh (CEA national figure; confirm the latest edition)
- Petrol: about 2.3 kg CO2e/litre
- Diesel: about 2.7 kg CO2e/litre
- LPG: `null` until an official source is cited

Rules: never hardcode a factor in code; every ledger row stores `ef_id` and `ef_version` so history can be recomputed.

---

## 7. Device catalog (the "all models" API)

### 7.1 Purpose
Know the exact model each household uses, so energy and CO2e are based on real specs instead of generic averages.

### 7.2 Entry schema
```json
{
  "id": "ac_<brand>_<model>",
  "category": "ac | fan | fridge | geyser | tv | pump | other",
  "brand": "", "model": "", "year": null,
  "tonnage": null, "inverter": null, "star": null, "iseer": null,
  "rated_power_w": null,
  "annual_kwh_label": null,
  "power_model": {"type": "inverter_curve | fixed_cycle | speed_table | flat", "params": {}},
  "ir_code_set": null,
  "data_quality": "label_verified | spec_sheet | class_estimate | measured",
  "source": {"name": "", "year": null, "url": null},
  "version": 1
}
```
Null means unknown. Fill only from a real source.

### 7.3 Data quality tiers
| Tier | Meaning | Uncertainty range (placeholder, replace after pilot) |
|---|---|---|
| `label_verified` | BEE star label or manufacturer datasheet | +/-10% |
| `spec_sheet` | Brochure only | +/-15% |
| `class_estimate` | No model match; use type, tonnage, star | +/-30% |
| `measured` | Aggregated from pilot homes with real readings | derived from data |

### 7.4 Data sources
- BEE star-labelling product databases (check format and terms; ask GEDA to request a direct data feed).
- Manufacturer datasheets and brochures.
- Do not scrape retailer sites.
- Seed the top models for brands sold in Gujarat, plus a **class fallback table** (e.g. conventional vs BLDC fans, fixed-speed vs inverter ACs). Mark class defaults as `class_estimate` and cite where they come from.

### 7.5 Identifying the user's model
1. Camera -> ML Kit text recognition on the unit's rating sticker.
2. `GET /v1/catalog/match?text=...` (or the local index offline) -> ranked candidates -> user confirms.
3. No match: user picks brand, type, tonnage, star -> `class_estimate`; entry goes to the suggestions queue.
4. Brand choice also selects the IR code set.

### 7.6 Real-world correction
Pilot homes with real readings contribute `measured / label` factors per model. Publish an aggregate only when a minimum number of households contribute, with no identifiers. Over time `measured` becomes the strongest tier.

### 7.7 Fastify API
- `GET /v1/catalog/devices?category=&brand=&q=`
- `GET /v1/catalog/devices/:id`
- `GET /v1/catalog/match?text=` (normalise OCR text; trigram similarity on brand+model; return top 5 with scores)
- `GET /v1/catalog/snapshot?since=<version>` (ETag; diff for offline cache)
- `POST /v1/catalog/suggestions` (moderation queue)
- `GET /v1/factors` (versioned emission factors)

Tables: `catalog_devices`, `catalog_versions`, `factors`, `suggestions`.

Importer: `tools/import_catalog.ts` reads CSV, validates required fields per category, and **rejects** any row with `data_quality=label_verified` that lacks a source.

---

## 8. Device registry and discovery

Each device gets a capability record. The engine picks the best evidence path per device.

- **Manual add** (always available): category, room, catalog match.
- **User-started Wi-Fi scan** (`NsdManager` mDNS + SSDP): finds TVs, Chromecasts, plugs, bulbs, Wi-Fi AC modules by service type and hostname. Android 10+ blocks the ARP table and randomizes MACs, so do not rely on hardware addresses. Results stay on the phone; the user confirms each device; only category counts may sync.
- **BLE fingerprint** (`BLUETOOTH_SCAN` with `neverForLocation`): manufacturer ID, service UUIDs, RSSI (rough same-room proximity). An appliance that advertises only while powered gives a real on/off signal, but confirm per model in the pilot. Most dumb appliances advertise nothing; record that fact.
- **IR capability check**: `ConsumerIrManager.hasIrEmitter()` at onboarding.

Do not build any passive, always-on scan of the home network.

---

## 9. IR control: the phone as the AC remote

- Android API: `ConsumerIrManager` (transmit only, permission `TRANSMIT_IR`). A phone cannot receive IR.
- Many AC IR frames carry the **full state** (power, mode, temperature, fan), so "Off" and "24 C" are idempotent and safe to resend.
- Encoders: implement per brand from a pattern table in `assets/ir_codes.json`. IRremoteESP8266 and open IR code databases are good references; **check licenses before copying**. Port to Kotlin behind a platform channel.
- Every send is written to `command_log` with evidence `command_sent`.
- Limits to design around: no acknowledgment, line of sight needed, and the household's original remote can change state without the app knowing. Mitigate with a **resync** action (resend full state) at bedtime and on leave-home, and a one-tap "sync" prompt when the log looks stale.
- Phones without an IR blaster: `control = none`; use the tap tier.

Runtime estimate: from the command log (on at t1, off at t2), corrected by resync confirmations.

---

## 10. AC belief engine (no hardware)

Output `P(AC on)` and a confidence label. On-device log-odds model:

```
logit = prior(weather, hour, user_profile)
      + w_home  * anyone_home
      + w_sleep * charging_at_night
      + w_cmd   * last_ir_command_state      # strong when recent
      + w_tap   * user_said_on_or_off        # strongest
      + w_sound * acoustic_delta             # only if the pilot feature is enabled
P = sigmoid(logit)
```

- Weights live in `assets/ac_weights.json`; start hand-set, tune from pilot data and bill calibration.
- Labels: `P > 0.85` likely, `0.5-0.85` uncertain, below that stay quiet.
- Unit tests for at least 6 scenarios (home/away x hot/cool x recent command/none).

**Acoustic check (optional pilot, off by default):** opt-in only. At setup, take two 5-second samples (AC on, AC off). Store only loudness and a few frequency features, never audio. Needs a visible off switch, a clear purpose statement, and an on-device-only guarantee. Fans sound like ACs, inverter ACs are quiet, and the mic indicator will appear. Measure accuracy in 5-10 real bedrooms; drop the feature if it is weak.

---

## 11. Credit and CO2e calculation

```
kwh = power_model(catalog_entry, conditions) * runtime_hours
kwh_saved = expected_kwh(weather_today, baseline) - actual_kwh
credit_kwh = kwh_saved * evidence_weight
co2e_kg = credit_kwh * emission_factor     (as a low-high range from data_quality)
```

- **Baseline period:** first 14 days. Log runtime and weather; make no claims.
- **Weather normalization:** cooling degree-hours = sum over hours of max(0, outdoor_temp - 24 C). A hotter week is not "worse behavior".
- **No meter:** `hours_off * kw_from_catalog * duty_factor` (duty factor from the power model), labeled `estimated`, capped per day.
- **Bill calibration (monthly):** photograph the bill, ML Kit OCR on-device, compare actual kWh against the weather-normalized baseline. Use it to scale the household's weights within sane bounds and as a sanity cap. Do not claim the bill proves any single action.
- Store `catalog_version` in each ledger row so past entries can be recomputed if a model's data is corrected.
- Tariff-slab-aware rupee savings are a later feature (needs a cited slab table per DISCOM).

---

## 12. Rules engine and nudge policy

Rules are JSON, loaded at runtime; no nudge logic in code.

```json
{
  "id": "leave_home_ac_check",
  "trigger": {"event": "household_away"},
  "conditions": ["has_ac", "p_ac_on_gt_0.7", "not_quiet_hours", "daily_cap_not_hit", "temp_gt_30"],
  "nudge": {"title": "Leaving? Quick AC check",
            "actions": ["send_ir_off", "done_tap", "dismiss"]},
  "evidence": "command_sent_or_tap",
  "co2e": {"formula": "kw_from_catalog * hours_expected_on * grid_ef", "baseline": "household"}
}
```

Global policy:
- Max **2** ambient notifications per 24 hours; low-urgency tips batch into a daily card.
- No notifications from 22:30 to 06:30.
- **Adaptive snooze:** 3 dismissals without a tap pause that trigger for 14 days.
- Notification action buttons work without opening the app.
- "Household away" = all registered phones off home Wi-Fi/geofence for 10 minutes.

---

## 13. Mapping the 10 nudges in BEHAVIORAL_NUDGES.md

| Nudge | v1 handling | Evidence ceiling |
|---|---|---|
| A. Engine off at red light | Post-trip summary only; can measure stopped time, not engine state; defer | self-reported |
| B. Hot car purge | Advisory card, no credit | none |
| C. Tire pressure | Biweekly reminder, one tap | self-reported |
| D. Leaving home | Core: presence + AC belief + IR "off" | command_sent |
| E. AC at 24 C | Core: IR sets 24 C; setpoint known because the app sent it | command_sent |
| F. Night AC timer | Core: app schedules an IR "off" (or timer frame if the brand supports it) | command_sent |
| G. Charger unplug | Verified by battery events; reward Mudra only | verified |
| H. Water pump window | Reminder before window ends, one tap | self-reported |
| I. LPG tip | Informational, no credit | none |
| J. Fridge gasket | Quarterly tip, one tap | self-reported |

### Numbers in BEHAVIORAL_NUDGES.md to fix before judges see them
- Night AC timer "5 kWh, Rs 900/month" is an upper bound; for an inverter AC use roughly 3-4 kWh, and compute from the catalog instead of typing it in.
- Fridge coil "Rs 200/month" looks high (a whole fridge often costs near Rs 300/month); recompute from the catalog's annual kWh.
- Water pump row: 1 kWh/day is about 260 kg CO2e/year at 0.71 kg/kWh, which does not match "45 kg". Use the formula.
- The annual impact table should be **computed** from the catalog and factors, not typed.

---

## 14. Sync, outbox, privacy

- Event-driven sends only. Send on change immediately, plus **one heartbeat per hour** so the backend can tell "still off" from "offline". Queue locally while offline; retry with backoff.
- Backend receives: anonymous household id, action id, tier, label, CO2e range, timestamp, ef/catalog versions.
- Backend never receives: SSID, GPS, address, device inventory, bill images, audio.
- Local storage: encrypted (Drift with encryption or SQLCipher), secrets in `flutter_secure_storage`.
- Aggregated leaderboards use anonymized totals only.

---

## 15. Android permissions (verify for your target SDK)

- `POST_NOTIFICATIONS` (Android 13+)
- Location (needed to read the Wi-Fi SSID) and geofencing; ask at the moment of need with a plain-language reason
- `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` (Android 12+), with `neverForLocation` where applicable
- `TRANSMIT_IR`
- Foreground service types only if a feature truly needs one (the acoustic pilot would need a microphone type)
- `RECORD_AUDIO` only for the opt-in acoustic pilot

OEM battery optimizers can delay background work; document the exemption steps for popular Indian OEMs in the app's help screen.

---

## 16. Pilot plan and ADB tooling

**ADB is a lab tool, not a user feature.** It needs developer options and cannot ship to citizens.

Use it to:
1. Log sensors, battery temperature and mic levels while you toggle a real AC, then check which signals correlate (this sets the belief engine weights).
2. Replay recorded event traces (CSV) into the event bus without waiting days.
3. Test on Android TVs or boxes you own (`adb connect <ip>:5555`).

Pilot (5-10 homes, with consent):
- Measure per-model real kWh where a meter or bill is available; feed the catalog `measured` tier.
- Measure IR reliability (success rate by brand, distance, angle).
- Measure belief engine accuracy against user confirmations.
- Measure the acoustic feature, if enabled.
- Report real numbers; these carry more weight than design claims.

Put scripts in `tools/adb/` and a Dart replay script in `tools/replay/`.

---

## 17. Build phases (give to Gemini CLI one at a time)

### Phase 0: Conventions
```
Set up the Flutter project structure: feature folders (core, events, presence,
catalog, devices, ir, belief, ledger, rules, notifications, sync, bills),
Riverpod (or the existing state tool), Drift, lints, and a CI test command.
No features yet. Add docs/DECISIONS.md.
```
**Accept:** `flutter test` and `flutter analyze` pass.

### Phase 1: Ledger, factors, calculator
```
1. Drift DB (encrypted): ledger, events, baseline, bills, command_log, device_registry.
2. assets/emission_factors.json (versioned, source and year per entry). Use the
   values in Section 6 and mark "verify latest CEA".
3. EvidenceWeights loader from assets/evidence_weights.json.
4. Co2eCalculator: returns {low, high, label}. Unit tests: ranges widen with
   worse data_quality; self_reported is capped and excluded from the verified total;
   recomputation with a new ef_version changes old rows only when requested.
```
**Accept:** tests cover each tier; no factor appears in code.

### Phase 2: Event bus, Android receivers, presence
```
1. EventBus (Dart streams) with a persistent journal.
2. Kotlin receivers via platform channel: power connected/disconnected,
   ConnectivityManager.NetworkCallback (Wi-Fi), Play Services Geofencing.
3. HouseholdPresence: home = any registered phone on home SSID or inside the
   geofence; away = all phones away for 10 minutes. Home SSID encrypted locally.
4. Debug screen: live events and presence state.
```
**Accept:** unplug the charger and leave the Wi-Fi on a real phone; both events appear.

### Phase 3: Catalog (backend, then app)
```
Backend (Fastify): tables, importer with validation, endpoints in Section 7.7,
ETag and snapshot diffs, /match with OCR normalisation, tests.
App: CatalogRepository (snapshot into Drift, fully offline), ModelPicker flow
(camera -> ML Kit text recognition -> match -> confirm -> DeviceRegistry.catalog_id),
class-estimate fallback.
```
**Accept:** photograph a real AC sticker and get a ranked match; offline lookup works.

### Phase 4: IR control
```
1. Kotlin ConsumerIrManager channel: hasEmitter(), transmit(freq, pattern).
2. IrService + AcIrEncoder interface; one brand implemented from
   assets/ir_codes.json; full-state frames {power, mode, tempC, fan}.
3. CommandLog writes every send as 'command_sent'. Add a "resync" action.
4. Unit-test the encoder against known frames.
```
**Accept:** on an IR-blaster phone, the app turns a real AC off and sets 24 C; no emitter -> control = none.

### Phase 5: AC belief engine and credit
```
1. AcBeliefEngine with weights in assets/ac_weights.json; inputs: weather (stub
   first), hour, profile, presence, charging, last command, taps.
2. CreditCalculator: credit_kwh = expected_kwh * evidence_weight; daily cap;
   one claim per action per day per household.
3. Baseline logger: 14-day baseline with cooling degree-hours.
4. Unit tests for 6+ scenarios.
```
**Accept:** deterministic outputs for fixtures; no claim during the baseline period.

### Phase 6: Rules engine, notifications, outbox
```
1. Rules engine from JSON (Section 12) with caps, quiet hours, adaptive snooze.
2. Notification actions (send_ir_off, done_tap, dismiss) that work without opening the app.
3. Outbox: send only on change plus an hourly heartbeat, queue offline, backoff.
4. Fastify ingest endpoint accepting only the summary schema in Section 5.
```
**Accept:** leaving home on a hot day triggers one nudge; the third dismissal pauses it for 14 days.

### Phase 7: Bill OCR and calibration
```
ML Kit OCR on-device, extract kWh and period, manual correction UI,
weather-normalized comparison, bounded weight scaling, monthly report.
Images stay on the phone.
```
**Accept:** a sample bill produces the right kWh; weights never move outside bounds.

### Phase 8: Discovery, BLE, ADB tools, pilot kit
```
User-started NsdManager+SSDP scan, BLE fingerprint list, user confirmation per device,
only category counts leave the phone. Add tools/adb and tools/replay scripts and a
pilot data-collection checklist.
```
**Accept:** scan results never leave the phone except counts; replay script reproduces a recorded night.

### Phase 9 (optional): Acoustic pilot
```
Opt-in only, two-sample calibration, store features only, visible off switch,
feature flag default off, on-device only.
```
**Accept:** accuracy measured in at least 5 bedrooms before enabling anywhere.

### Phase 10: Sparrow integration
```
Sparrow state driven by verified/estimated impact, not by raw taps; forgiving
streaks with a freeze day.
```

---

## 18. Things to verify before the demo (do not assume)

- Latest CEA grid emission factor and the petrol/diesel/LPG factors, with citations.
- BEE database format, license and bulk access (ask GEDA for a feed).
- IR code license terms for any library you port.
- DISCOM smart-meter data access (Torrent, UGVCL and others), if you want the fallback.
- Current Android permission rules for your target SDK (SSID, Bluetooth, foreground services).
- Play Store policy for the microphone pilot, if you ship it.
- DPDP: consent text, purpose limitation, and retention for each data item.

---

## 19. Definition of done for the demo

- A real household: onboard, pick the AC model from its sticker, run a 14-day baseline.
- A real nudge on leaving home, one tap (or an IR command) to switch the AC off, a ledger entry with a tier and range.
- A bill upload producing a calibration report.
- Every number on screen traceable to a source and a version.
- Clear, honest labels: verified, command sent, estimated, self-reported.
