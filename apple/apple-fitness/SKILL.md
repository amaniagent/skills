---
name: apple-fitness
description: Build fitness/workout features on Apple platforms — WorkoutKit to author, preview, and schedule structured workouts (custom workouts, interval blocks, goals, and heart-rate/pace/power/cadence alerts) to Apple Watch, and HealthKit's live workout session on watchOS (HKWorkoutSession + HKLiveWorkoutBuilder) to track and save an HKWorkout with route data. Covers the split between authoring plans (WorkoutKit, iOS+watch) and live tracking (HealthKit, watch), workout activity types, and saving/reading workouts. Pairs with the healthkit skill for the underlying store. Use when composing a training plan, scheduling a workout to the Watch, tracking a live workout, or reading past workouts. Triggers include "create a workout", "schedule a workout to Apple Watch", "interval training plan", "track a running workout", "HKWorkoutSession", "workout route", "read past workouts".
---

# Apple fitness — author with WorkoutKit, track with HealthKit

Two distinct frameworks, two jobs. Get the split right or you'll reach for the wrong one:

| Framework | Job | Where |
|---|---|---|
| **WorkoutKit** | **Author / preview / schedule** structured workouts (plans, intervals, goals, alerts) | iOS + watchOS (iOS 17+) |
| **HealthKit workout session** | **Live tracking** during a workout — collect samples, save the `HKWorkout` | watchOS (the Watch is the tracker) |

The store underneath is HealthKit — see the `healthkit` skill for authorization, the entitlement,
and the `HKQuantityType`/query model this builds on.

## WorkoutKit — compose a structured workout

A custom workout is warmup + blocks of steps + cooldown; each step has a **goal** and optional
**alerts**:

```swift
import WorkoutKit
import HealthKit

let work = IntervalStep(.work,
    goal: .distance(400, .meters),
    alert: PaceThresholdAlert(pace: HKQuantity(unit: .init(from: "min/km"), doubleValue: 5)))
let recover = IntervalStep(.recovery, goal: .time(90, .seconds))

let block = IntervalBlock(steps: [work, recover], iterations: 6)

let custom = CustomWorkout(
    activity: .running,
    location: .outdoor,
    displayName: "6×400m",
    warmup: WorkoutStep(goal: .time(5, .minutes)),
    blocks: [block],
    cooldown: WorkoutStep(goal: .open))
```

- **Goals**: `.time`, `.distance`, `.energy`, `.open` (go until the user ends it).
- **Alerts**: `HeartRateRangeAlert`, `HeartRateZoneAlert`, `PaceThresholdAlert`,
  `CadenceRangeAlert`/`CadenceThresholdAlert`, `PowerRangeAlert`/`PowerThresholdAlert`,
  `PowerZoneAlert` — attach to a step to cue the athlete.
- **Activity + location**: `HKWorkoutActivityType` (`.running`, `.cycling`, `.functionalStrengthTraining`,
  …) and `.indoor`/`.outdoor`.

### Preview and schedule to the Watch

```swift
let plan = WorkoutPlan(.custom(custom))

// Ask permission, then schedule so the workout appears on the paired Apple Watch
let scheduler = WorkoutScheduler.shared
guard await scheduler.authorizationState == .authorized ||
      (await scheduler.requestAuthorization()) == .authorized else { return }
try await scheduler.schedule(plan, at: dateComponents)
```

A `WorkoutPlan` is **previewable** (a `WorkoutPreview` in the Workout app) — the user gets a native
preview before starting, and scheduled plans show up on the Watch.

## HealthKit — track a live workout (watchOS)

On the Watch you run an `HKWorkoutSession` and feed a **live builder** that collects samples and
produces the saved `HKWorkout`:

```swift
let config = HKWorkoutConfiguration()
config.activityType = .running
config.locationType = .outdoor

let session = try HKWorkoutSession(healthStore: store, configuration: config)
let builder = session.associatedWorkoutBuilder()
builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)

session.startActivity(with: .now)
try await builder.beginCollection(at: .now)
// … live heart rate / energy / distance flow into the builder …
try await builder.endCollection(at: .now)
let workout = try await builder.finishWorkout()   // saved HKWorkout
```

- **Route**: for outdoor workouts add an `HKWorkoutRouteBuilder`, feed it `CLLocation`s during the
  session, and finish it associated with the workout (needs location permission + the workout
  processing background mode).
- **Live metrics**: observe the builder's statistics for the UI (current HR, active energy, distance).

## Reading past workouts

Query workouts like any HealthKit sample, filtered by activity type:

```swift
let predicate = HKQuery.predicateForWorkouts(with: .running)
let p = HKSamplePredicate.workout(predicate)
let workouts = try await HKSampleQueryDescriptor(predicates: [p], sortDescriptors: [
    SortDescriptor(\.startDate, order: .reverse)]).result(for: store)
```

Read `HKWorkout.duration`, per-type statistics (`workout.statistics(for:)` for energy/distance/HR),
and the associated route via `HKWorkoutRouteQuery`.

## Verify

- **WorkoutKit**: preview the `WorkoutPlan` and confirm the scheduled workout appears on the paired
  Watch; `RenderPreview` (xcode-mcp) any SwiftUI that shows the plan.
- **Live session**: requires a **real Apple Watch** (the simulator can't produce sensor data) — run
  it, finish, then confirm the `HKWorkout` (and route) shows in the Health/Fitness app.
- Authorization for workout types and route data must be granted (see `healthkit` — read denial is
  invisible, empty results are the default failure).

## Gotchas

| Symptom | Cause / fix |
|---|---|
| Workout won't schedule | `WorkoutScheduler` not authorized — request and check `authorizationState` |
| Live session no data | Running on the simulator — sensor data needs a real Watch |
| Route empty | Missing location permission or the workout-processing background mode, or route builder not finished |
| `finishWorkout()` saves nothing | HealthKit write not authorized for workouts, or collection not ended |
| Alerts don't fire | Wrong unit on the alert quantity (e.g. pace `min/km` vs `min/mi`) |

## Honest limits

- WorkoutKit's exact type/alert surface is iOS 17+ and grows per release — confirm against
  `DocumentationSearch` (framework: WorkoutKit) before relying on a specific alert or goal type.
- **Live tracking is watchOS-centric**; an iPhone-only app authors and reads workouts but doesn't run
  the sensor session — plan the Watch target (see `app-planning-per-platform`).
- Nutrition/dietary data is the `healthkit` skill; this skill is workouts/activity. Deep custom
  metrics, multisport transitions, and advanced route processing are summarized, not exhaustive.
