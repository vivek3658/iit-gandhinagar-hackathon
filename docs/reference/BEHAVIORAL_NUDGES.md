# UrjaVatika: Passive Behavioral Nudges & Invisible Carbon Prevention
**GEDA Mission LiFE Citizen Platform (Problem Statement: HC26-GEDA01)**  
*Blueprint for Zero-Hardware, Context-Aware Micro-Triggers that Save Money and Cut Emissions Without Annoying Citizens.*

---

## 1. The Core Philosophy: "Invisible, Non-Intrusive, High-Impact"

Most sustainability apps fail because they act like nagging alarm clocks—spamming notifications until the user uninstalls them.

**UrjaVatika uses "Ambient Intelligence":**
1. **Zero Hardware Cost:** Uses smartphone sensors already in the citizen's pocket (Geofencing, Battery API, Accelerometer, Weather API, Bluetooth connection state).
2. **Contextual Relevance:** Triggers only at the exact moment and location where the habit can be executed in under 5 seconds.
3. **Anti-Annoyance Cooldowns:** Enforces strict frequency capping (maximum 2 high-priority ambient notifications per day; never notifies during night or meetings).
4. **Actionable Rewards:** Every micro-action awards **Urja Mudra** and feeds the 3D Sparrow companion.

---

## 2. Mobility & Road Nudges (Traffic, Fuel & Engine Idling)

### A. The "Long Traffic Signal / Red Light Off" Smart Trigger
* **The Problem:** In urban Gujarat junctions (e.g., SG Highway in Ahmedabad, Majura Gate in Surat), drivers idle at 60–90 second red lights. Idling for just 10 seconds burns more fuel than restarting the engine. An average commuter wastes **₹1,200–₹1,800/year** burning petrol while standing still.
* **The Non-Intrusive Solution (Post-Trip Commute Summary):**
  * **Why NOT a live alert while driving?** Showing phone pop-ups while driving is unsafe, illegal, and annoying.
  * **Post-Trip Digest (When vehicle stops at destination):**  
    `"🚗 Commute Completed (7.4 km). Based on your route's 4 major signals, switching off your engine at long red lights (>30s) can save you ~₹120/month in petrol and keep Gujarat's air clean. +15 Urja Mudra logged!"`
* **Optional Hands-Free Audio Whisper (Bluetooth Car Audio / Helmet Earbuds):**
  * If the phone is connected to vehicle Bluetooth and vehicle speed stays at 0 km/h for > 35 seconds:  
    A soft 1-second audio chime plays:  
    *🎵 "Sparrow whisper: Long signal ahead? Switch off the engine to save fuel."*

---

### B. The "Hot Car Greenhouse Purge" Summer Nudge
* **The Problem:** A car parked in Gujarat's summer sun (40°C–44°C) reaches **55°C–60°C inside**. Drivers immediately crank the AC to maximum, forcing the engine compressor into extreme overload and burning 25% more fuel for the first 10 minutes.
* **The Smart Trigger:**
  * Phone detects vehicle commute starting between 1:00 PM and 5:00 PM when outdoor temp is > 38°C.
* **The Non-Annoying Pre-Drive Card:**  
  `"☀️ Hot car parked in the sun? Roll down windows for the first 2 minutes of driving to flush out trapped heat. Your AC will cool the cabin twice as fast with 20% less fuel!"`

---

### C. Monthly Tire Pressure Optimization Alert (1st & 15th of Month)
* **The Problem:** Under-inflated tires by just 5 PSI increase vehicle rolling resistance by 10%, burning 3% to 5% more petrol/diesel and wearing out expensive tires prematurely.
* **The Trigger:** Bi-weekly scheduled Sunday morning notification (10:00 AM):  
  `"🚗 Weekend tire check: Properly inflated tires save ~₹400/month in petrol and give a smoother ride. Tap when checked! (+20 Urja Mudra ⚡)"`

---

## 3. Home Electricity & Cooling Nudges

### D. The "Leaving Home" Geofence Delta Alert
* **The Trigger:** Phone location exits 150m radius of Home geofence.
* **The Notification:**  
  `"Leaving home? 🚪 Quick check: Did you leave any bedroom ACs, electric geysers, or ceiling fans running?"`  
  `[ All Off! +15 Mudra ⚡ ]    [ Dismiss ]`
* **Real Savings:** Prevents 8 hours of forgotten 1.5-ton AC consumption (saves **₹70–₹80 per incident**).

---

### E. The "AC 24°C Comfort Standard" Heatwave Sync
* **The Trigger:** Weather API reports district temperature > 38°C (Ahmedabad, Rajkot, Surat, Vadodara).
* **The Nudge (9:00 AM):**  
  `"🌡️ Heatwave alert today (41°C). Setting your AC to 24°C instead of 18°C saves up to 36% electricity and keeps your room comfortable without compressor tripping."`
* **Real Savings:** Every 1°C higher thermostat setting saves **6% power** (verified by Bureau of Energy Efficiency - BEE).

---

### F. Nighttime AC Sleep Timer Prompt (10:30 PM)
* **The Trigger:** 15 minutes prior to saved citizen bedtime.
* **The Nudge:**  
  `"🌙 Bedtime tip: Set your bedroom AC sleep timer to 3 hours. The room stays cool through the night, saving 5 kWh of power while you sleep!"`
* **Real Savings:** Saves ~5 units (kWh) per night = **₹900/month** off the monthly bill.

---

### G. Phone Battery 100% Full & Unplug Reminder
* **The Trigger:** Native `battery_plus` detects charging state reaches 98%–100%.
* **The Nudge:**  
  `"🔋 Fully charged! Unplug your charger and switch off the wall socket to stop phantom power drain and protect battery lifespan."`

---

## 4. Water & Kitchen Resource Conservation

### H. Gujarat Municipal Water Window Pump Alert
* **The Problem:** Municipal water supply in Gujarat (AMC, SMC, RMC) runs for a strict 1.5-hour window. Submersible overhead pumps left running unattended cause massive rooftop tank overflow.
* **The Trigger:** 15 minutes before the local municipal water supply window ends (e.g. 7:45 AM):  
  `"💧 Municipal water window closes in 15 mins! Check your overhead tank and switch off the motor pump to prevent overflow."`
* **Real Savings:** Saves 500–1,000 liters of treated drinking water and 1 kWh of pump electricity per day.

---

### I. The "LPG Gas Cooker" Micro-Tip (Sunday Evening)
* **The Problem:** Cooking with uncovered pots or boiling unsoaked pulses uses 30%–40% more LPG gas cylinders.
* **The Smart Kitchen Tip:**  
  `"🥘 Kitchen LiFE Tip: Soaking dal/chana for 30 minutes before cooking cuts stove boiling time in half and keeps your LPG cylinder lasting 2 weeks longer!"`

---

### J. Refrigerator Door Gasket & Coil Check (Quarterly Nudge)
* **The Problem:** A dusty refrigerator condenser coil or loose magnetic door gasket causes the fridge compressor to work 25% harder, silently adding ₹200/month to power bills.
* **The Trigger:** Fired once every 90 days:  
  `"🧊 Quick 10-second test: Place a paper bill in your fridge door. If it slips out easily, your door seal needs cleaning to stop cool air leakage! (+30 Mudra ⚡)"`

---

## 5. Anti-Annoyance & Privacy Guarantees

To ensure citizens never feel annoyed or tracked:

1. **Strict Frequency Capping:**
   * Maximum **2 ambient notifications per 24 hours**.
   * Low-urgency tips are batched into a single daily summary card on the Home Screen.
2. **Quiet Hours Auto-Mute:**
   * Zero push notifications between **10:30 PM and 6:30 AM** (except silent battery full chimes if enabled).
3. **Local-Only Location Processing (Zero Geolocation Upload):**
   * The citizen's exact Home GPS coordinates are stored **exclusively in encrypted local SQLite/Preferences on the phone**.
   * The Fastify backend never receives or stores citizen home coordinates, guaranteeing **100% compliance with India's Digital Personal Data Protection (DPDP) Act 2023**.
4. **Adaptive Snooze:**
   * If a citizen dismisses a nudge 3 times without tapping, the app automatically pauses that specific trigger for 14 days.

---

## 6. Summary: Annual Impact per Citizen Household

| Ambient Nudge | Annual Money Saved (₹) | Annual CO2 Cut (kg) | Citizen Effort |
| :--- | :--- | :--- | :--- |
| **Leaving Home AC/Geyser Off** | ₹2,400 - ₹4,800 | 250 - 500 kg | 2 seconds |
| **AC Set at 24°C in Summer** | ₹1,500 - ₹2,200 | 180 - 260 kg | 1-time change |
| **Red Light Engine Off (Commute)** | ₹1,200 - ₹1,800 | 100 - 150 kg | Flip switch at signals |
| **Municipal Water Pump Overflow** | ₹600 (pump power) + water | 45 kg + 18,000L water | Turn off motor switch |
| **Tire Pressure Maintenance** | ₹1,000 - ₹1,400 | 80 - 120 kg | Check at petrol bunk |
| **Charger Unplug (Phantom Load)** | ₹300 - ₹500 | 30 - 50 kg | Unplug wire |
| **TOTAL ANNUAL IMPACT** | **₹7,000 – ₹11,300 Saved!** | **~700 – 1,125 kg CO2 Saved!** | Minimal Everyday Micro-Habits |
