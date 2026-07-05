---
name: led-grow-controller
description: Design and dial in an indoor LED grow setup with ESP32 sensing/actuation — the "fridge-sized greenhouse for the living room" build. Covers the light side (PPFD/DLI targets per crop type, spectrum and photoperiod, LED distance and heat), the climate side (temperature, humidity, and VPD as the real control variable), and the automation side (capacitive soil-moisture, light and temp/humidity sensors on ESP32, hysteresis pump control, and the safety interlocks that keep water off your floor). Honest that exact PPFD/DLI/VPD values are crop- and phase-specific and must be dialed in per plant. Pairs with the embedded-swift skill for the firmware layer. Use when building or tuning an indoor grow box, an auto-watering rig, or an ESP32 plant-monitoring controller. Triggers include "LED grow light", "indoor greenhouse", "PPFD DLI", "ESP32 plant watering", "grow box automation", "soil moisture sensor", "VPD control".
---

# LED grow controller — light, climate, and ESP32 automation

The build is a small enclosed grow space ("a fridge for the living room") with LED lighting, an
ESP32 reading the environment and driving pumps/lights. This skill is the **horticulture + control
logic**; the **firmware** that runs on the board is the companion `embedded-swift` skill (ESP32-C6:
read ADC sensors, drive GPIO/PWM, run the threshold/schedule loop).

> ⚠️ **Read this first — numbers are starting points, not gospel.** PPFD, DLI, VPD, and photoperiod
> targets vary by **crop and growth phase** and by your exact hardware. Every value below is a
> reasonable *starting range* to dial in with observation and, ideally, a PAR meter — not a spec.
> Under-light and you get leggy, pale plants; over-light or too-close LEDs and you get bleaching.

## Light: PPFD, DLI, and photoperiod

Two numbers drive everything:

- **PPFD** (µmol/m²/s) — instantaneous photon density of photosynthetically active light (400–700nm)
  hitting the canopy. This is what you set with LED power and distance.
- **DLI** (mol/m²/day) — the daily total. `DLI ≈ PPFD × photoperiod(h) × 3600 / 1,000,000`. This is
  the number that actually predicts growth.

| Crop class | PPFD (canopy) | DLI target | Photoperiod |
|---|---|---|---|
| Seedlings / microgreens | ~100–250 | ~6–12 | 16–18h |
| Leafy greens & herbs (lettuce, basil) | ~200–400 | ~12–17 | 14–16h |
| Fruiting (chili, tomato, strawberry) | ~400–600+ | ~20–30 | 12–16h |

Ranges are approximate and crop-specific — verify per plant. Most plants need a **dark period** for
respiration; running 24h light is usually a mistake outside a few leafy crops.

**Spectrum, in plain terms** (broad tendencies, exact ratios uncertain and product-dependent):

- **Full-spectrum white LEDs** (≈3000–4000K) are the sensible base — good coverage, easy to eyeball
  plant health under.
- **Blue (~450nm)** biases toward compact, leafy, shorter growth.
- **Red (~660nm)** drives photosynthesis efficiently and supports flowering/fruiting.
- **Far-red (~730nm)** triggers shade-avoidance (stretch) and can nudge flowering — use sparingly.
- Practical rig: white full-spectrum panel + optional supplemental deep-red; skip exotic ratios
  until the basics work.

**Distance & heat:** LED height sets PPFD (inverse-square-ish) and manages heat. Start mid-power
panels ~30–45cm above canopy and adjust by watching the plants and (ideally) a PAR reading. Even
"cool" LEDs dump heat into a small sealed box — plan airflow or you cook the canopy and invite
condensation/mold.

## Climate: VPD is the variable that matters

Temperature and humidity in isolation mislead. The real control target is **VPD (vapor pressure
deficit, kPa)** — how "thirsty" the air is, computed from temp + relative humidity. It governs
transpiration, nutrient uptake, and mold risk.

| Phase | VPD target (approx) |
|---|---|
| Seedling / clone | ~0.4–0.8 kPa |
| Vegetative | ~0.8–1.2 kPa |
| Flowering / fruiting | ~1.2–1.5 kPa |

Compute VPD from a temp/humidity sensor in firmware and drive ventilation/humidity toward the phase
target, rather than chasing raw %RH. Too low VPD (humid, still air) in a sealed box → condensation →
mold; too high → stress and wilt.

## ESP32 sensing & actuation

| What | Sensor / part | Notes |
|---|---|---|
| Soil moisture | **Capacitive** probe (not resistive) | Resistive probes corrode fast; capacitive last. **Calibrate in your actual substrate** — raw ADC differs per soil/coco/perlite. |
| Air temp + humidity | SHT31 / SHT41 (or DHT22 budget) | Feeds the VPD calc. Place at canopy height, shaded from direct LED. |
| Light | BH1750 (lux) or a PAR sensor | BH1750 reads **lux, not PPFD** — useful for on/off and relative trend, not absolute PPFD. A real PAR sensor is the only accurate PPFD source. |
| Water pump | Relay or logic-level MOSFET | Drive from ESP32 GPIO via the switch, never directly. |
| Overflow guard | Float switch / water-detect sensor | Hardware interlock — see safety. |

## Watering control loop

- **Threshold + hysteresis**, not a bare setpoint. e.g. pump ON below 30% moisture, OFF above 45% —
  the dead band stops the pump chattering around one value.
- **Dose by run-time**, calibrated per pot/substrate (measure how many seconds fills to target), and
  cap max pump-on time per cycle so a stuck reading can't flood.
- **Rate-limit**: enforce a minimum interval between waterings; soil takes time to equalize after a
  dose, so reacting instantly re-triggers.
- Prefer this simple scheme first; PID/fuzzy control is rarely worth it for soil moisture.

## Safety interlocks (living room = water damage risk)

Non-negotiable in a home:

1. **Float/overflow sensor** in the tray that cuts the pump in hardware or firmware regardless of the
   moisture reading.
2. **Max pump-on watchdog** — absolute time limit per activation; if exceeded, shut off and alarm.
3. **Fail-safe default** — on sensor fault or boot, pump defaults OFF, never ON.
4. **Food-safe tubing + backflow prevention** if you'll eat the crop; keep the reservoir covered
   (light + debris → algae).
5. **Electrical**: keep mains/relay wiring away from water; fuse the pump line.

## Verify

- **Light**: measure PPFD at canopy with a PAR meter (or at minimum confirm DLI math against
  photoperiod); adjust LED height/power to the crop's range.
- **Climate**: log temp/RH, compute VPD, confirm it tracks the phase target across a full light/dark
  cycle.
- **Water**: dry-run the pump loop with the reservoir but tubing into a measuring cup — confirm dose
  volume, hysteresis, watchdog cutoff, and overflow interlock all fire before pointing it at a plant.
- **Over cycles**: log settings + observations per grow; leggy/pale ⇒ more light, bleached tips ⇒
  less/raise LEDs, mold ⇒ lower humidity / raise VPD / more airflow.

## Honest limits

- Optimal PPFD/DLI/VPD/spectrum are **plant- and phase-specific** and interact with temperature and
  CO₂ — this skill gives ranges and method, not a per-crop lookup table. Dial in by observation.
- Without a **PAR meter** you're estimating PPFD; lux sensors (BH1750) don't measure it directly.
- Substrate-specific **calibration** of capacitive moisture sensors is mandatory — the same raw ADC
  means different water content in coco vs. peat vs. potting mix.
- Nutrient/pH/EC management (esp. hydroponic) is its own domain and only touched here.
- The firmware to run all this on the board is the **`embedded-swift`** skill (or Arduino/ESP-IDF C
  if you prefer) — this skill stops at "what the controller should do," not "in which language."
