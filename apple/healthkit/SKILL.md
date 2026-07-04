---
name: healthkit
description: Read and write health data on iOS/iPadOS/watchOS with HealthKit — authorization and the Info.plist/entitlement setup, the HKQuantityType/HKQuantitySample/HKCorrelation data model, sample and statistics queries, background delivery, and the privacy model (you never learn if a read was denied). Includes a concrete dietary-nutrition mapping: the ~39 HealthKit dietary quantity types with their units, ready to map a nutrition dataset (e.g. BLS/KidsKitchen) into a food HKCorrelation. Use when logging food/nutrition, reading steps/heart rate/energy, syncing samples, or requesting HealthKit permissions. Triggers include "log food to Health", "read HealthKit data", "request health authorization", "save a nutrition sample", "map nutrients to HealthKit", "why is my HealthKit read empty".
---

# HealthKit — the on-device health store

HealthKit is a **permissioned, on-device** store for health/fitness/nutrition samples, shared across
apps with the user's per-type consent. It runs on **iOS, iPadOS, watchOS** — **not macOS** (plan
accordingly; a Mac app reaches health data only via a paired device/CloudKit of your own). Workouts
belong to a sibling skill (`apple-fitness` / WorkoutKit); this skill covers the store + nutrition.

## Setup (do this first or nothing works)

1. Add the **HealthKit capability** (entitlement) to the target.
2. Add **Info.plist usage strings** — missing = crash on request:
   - `NSHealthShareUsageDescription` (read)
   - `NSHealthUpdateUsageDescription` (write)
3. Check availability, then request per-type authorization:

```swift
guard HKHealthStore.isHealthDataAvailable() else { return }   // false on Mac / unsupported
let store = HKHealthStore()

let toRead: Set<HKObjectType> = [HKQuantityType(.stepCount), HKQuantityType(.dietaryEnergyConsumed)]
let toWrite: Set<HKSampleType> = [HKQuantityType(.dietaryEnergyConsumed), HKQuantityType(.dietaryProtein)]
try await store.requestAuthorization(toShare: toWrite, read: toRead)
```

### The privacy model — the biggest surprise

- `authorizationStatus(for:)` tells you about **write** permission only. **You can never tell
  whether a *read* was granted or denied** — a denied read type simply returns **no samples**, look-
  ing identical to "user has no data." Design for empty results; never treat empty as an error or as
  "denied."
- Authorization is **per type**. Request the minimum set. Re-requesting already-decided types is a
  no-op (the sheet won't reappear; send the user to Settings > Privacy > Health).
- Data is on-device (syncs via the user's encrypted iCloud Health, not yours). Don't exfiltrate it.

## Data model

| Type | Use |
|---|---|
| `HKQuantityType` + `HKQuantitySample` | numeric measurements (energy, mass, steps, heart rate) with an `HKUnit` |
| `HKCategoryType` + `HKCategorySample` | enumerated states (sleep analysis, mindful minutes) |
| `HKCorrelationType` + `HKCorrelation` | a **group** of samples — **food** and **blood pressure** are correlations |
| `HKUnit` | `.kilocalorie()`, `.gram()`, `.gramUnit(with: .milli)`, `.liter()`, `.count()` |

### Logging food = one HKCorrelation of nutrient samples

A logged food item is an `HKCorrelation` of type `.food`, wrapping one `HKQuantitySample` per
nutrient, tagged with `HKMetadataKeyFoodType`:

```swift
let energy = HKQuantitySample(type: HKQuantityType(.dietaryEnergyConsumed),
    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: 240),
    start: date, end: date)
let protein = HKQuantitySample(type: HKQuantityType(.dietaryProtein),
    quantity: HKQuantity(unit: .gram(), doubleValue: 9), start: date, end: date)

let food = HKCorrelation(type: HKCorrelationType(.food), start: date, end: date,
    objects: [energy, protein], metadata: [HKMetadataKeyFoodType: "Oatmeal"])
try await store.save(food)
```

## Reading

```swift
// Raw samples
let p = HKSamplePredicate.quantitySample(type: HKQuantityType(.stepCount),
          predicate: HKQuery.predicateForSamples(withStart: dayStart, end: dayEnd))
let steps = try await HKSampleQueryDescriptor(predicates: [p], sortDescriptors: []).result(for: store)

// Aggregated (daily totals, averages)
let stats = HKStatisticsCollectionQueryDescriptor(
    predicate: p, options: .cumulativeSum,
    anchorDate: dayStart, intervalComponents: DateComponents(day: 1))
```

- **`HKStatisticsCollectionQuery`** → daily/hourly buckets (steps/day, energy/day).
- **`HKAnchoredObjectQuery`** → incremental sync (only what changed since your anchor).
- **`enableBackgroundDelivery(for:frequency:)`** + an `HKObserverQuery` → wake on new data (needs the
  Background Modes / HealthKit background capability).

## The nutrition mapping (KidsKitchen vorarbeit)

A nutrition dataset (BLS has ~140 nutrient columns per ingredient) maps onto HealthKit's **~39
`dietary*` quantity types**. Map only what HealthKit models; the rest stays app-side. Units below are
what each identifier expects.

| Group | HKQuantityTypeIdentifier | Unit |
|---|---|---|
| Energy | `dietaryEnergyConsumed` | kcal (`.kilocalorie()`) |
| Macros | `dietaryProtein`, `dietaryCarbohydrates`, `dietaryFiber`, `dietarySugar`, `dietaryFatTotal`, `dietaryFatSaturated`, `dietaryFatMonounsaturated`, `dietaryFatPolyunsaturated`, `dietaryCholesterol` | g (cholesterol mg) |
| Vitamins | `dietaryVitaminA`, `dietaryVitaminC`, `dietaryVitaminD`, `dietaryVitaminE`, `dietaryVitaminK`, `dietaryThiamin` (B1), `dietaryRiboflavin` (B2), `dietaryNiacin` (B3), `dietaryVitaminB6`, `dietaryFolate` (B9), `dietaryVitaminB12`, `dietaryBiotin` (B7), `dietaryPantothenicAcid` (B5) | mass: mg or µg |
| Minerals | `dietaryCalcium`, `dietaryIron`, `dietaryMagnesium`, `dietaryPhosphorus`, `dietaryPotassium`, `dietarySodium`, `dietaryZinc`, `dietaryChloride`, `dietaryChromium`, `dietaryCopper`, `dietaryIodine`, `dietaryManganese`, `dietaryMolybdenum`, `dietarySelenium` | mass: mg or µg |
| Other | `dietaryCaffeine` (mg), `dietaryWater` (`.liter()` / mL) | mg / volume |

That's ~39 nutrients (energy + 9 macro + 13 vitamin + 14 mineral + 2 other). **All dietary nutrients
use MASS units** in HealthKit — HealthKit does *not* take IU: convert Vitamin A/D from IU to
micrograms **before** saving (a fixed factor per vitamin), or you'll log wrong values. Pick the
`HKUnit` mass prefix (`.gram()`, `.gramUnit(with: .milli)`, `.gramUnit(with: .micro)`) to match the
nutrient's natural scale. Persist the BLS-column → identifier table in the app so the FoundationModels
match result can be turned into a `.food` correlation in one pass.

## Verify

HealthKit needs a **real device or a simulator with the Health app** — you cannot check it through a
SwiftUI `RenderPreview`. Verify by: request authorization → save a known correlation → read it back
with a sample query → confirm it also appears in the **Health app > Browse**. Empty reads are the
default failure mode; confirm the write path before blaming the read.

## Gotchas

| Symptom | Cause / fix |
|---|---|
| Crash on `requestAuthorization` | Missing `NSHealth*UsageDescription` Info.plist strings or the HealthKit entitlement |
| Reads always empty | Read denial is invisible — or there's genuinely no data; never assume it's granted |
| Nutrient values off by ~30× | IU vs µg — convert Vitamin A/D to micrograms before saving; HealthKit wants mass |
| Auth sheet won't reappear | Decisions are sticky; re-requesting is a no-op — direct the user to Settings |
| No `macOS` build | HealthKit isn't on macOS; `isHealthDataAvailable()` is false there |
| Background updates never fire | Missing background delivery capability / observer query not registered |

## Honest limits

- Exact identifier availability and any newly added nutrient types shift per OS release — confirm the
  live set with the `xcode` bridge `DocumentationSearch` (framework: HealthKit) before relying on an
  identifier this table doesn't list.
- Clinical/FHIR records (`HKClinicalType`), ECG, and characteristic types (blood type, DOB) exist but
  are out of scope here — this skill focuses on the store model + nutrition.
- Workouts, `HKWorkout`, and WorkoutKit live in the `apple-fitness` skill, not here.
- The nutrition mapping is a *starting* table from lived KidsKitchen work; validate units against a
  few known foods (energy ±20% EU tolerance) before mass-writing, exactly as the KidsKitchen pipeline
  validates against recipes that already have nutrition values.
