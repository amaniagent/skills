---
name: widgets
description: Build WidgetKit widgets across Apple platforms — Home Screen, Lock Screen, StandBy, macOS desktop/Notification Center, watchOS complications, and visionOS — plus interactive widgets (App Intents) and Live Activities with the Dynamic Island. Covers the Widget→TimelineProvider→Entry→View shape, timeline reload policies, the per-platform widget families, the iOS 17+ requirements (containerBackground, AppIntentConfiguration, interactive Button/Toggle), and how to verify every timeline frame with RenderPreview. Use when adding a widget, a Lock Screen or StandBy widget, a watch complication, a Live Activity, or making a widget interactive. Triggers include "add a widget", "lock screen widget", "watch complication", "live activity", "dynamic island", "make the widget tappable", "why won't my widget update".
---

# WidgetKit — one framework, many surfaces

A widget is a small, **timeline-driven** SwiftUI view that the system renders on your behalf and
refreshes on a budget. Since iOS 16/17 the same WidgetKit powers Home Screen, Lock Screen, StandBy,
the Mac desktop and Notification Center, **watchOS complications**, and visionOS — and, via
ActivityKit, Live Activities and the Dynamic Island. Plan the surface first (see the
`app-planning-per-platform` skill), because the widget *families* and constraints differ per surface.

**Rule 8:** Apple ships `swiftui-specialist` / `swiftui-whats-new-27` (export via
`xcrun mcpbridge run-agent skills export`). Let them cover generic SwiftUI. This skill is the
WidgetKit-specific end-to-end.

## The shape

Four pieces, always:

```swift
struct MyWidget: Widget {
    var body: some WidgetConfiguration {
        // static (no user config) OR AppIntentConfiguration (user-configurable, iOS 17+)
        StaticConfiguration(kind: "MyWidget", provider: Provider()) { entry in
            MyWidgetView(entry: entry)
                .containerBackground(.fieldBackground, for: .widget)   // iOS 17+: REQUIRED
        }
        .configurationDisplayName("My Widget")
        .description("What it shows.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct Provider: TimelineProvider {                    // or AppIntentTimelineProvider (configurable)
    func placeholder(in: Context) -> Entry { ... }     // redacted first paint
    func getSnapshot(in: Context, completion: ...) { } // widget gallery / transient
    func getTimeline(in: Context, completion: ...) {   // the real entries + reload policy
        let entries = [Entry(date: .now, ...)]
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct Entry: TimelineEntry { let date: Date; /* your data */ }
```

The **Entry** is a snapshot at a `date`; a **Timeline** is a list of future entries plus a **reload
policy** telling WidgetKit when to ask for the next timeline.

## Reload policies — the #1 "why won't it update"

| Policy | Meaning | Use when |
|---|---|---|
| `.atEnd` | Reload after the last entry's date | You precomputed a sequence and want the next batch when it runs out |
| `.after(date)` | Reload at a specific time | You know the next meaningful moment (next departure, midnight) |
| `.never` | Never on its own — **you** drive it | App calls `WidgetCenter.shared.reloadTimelines(ofKind:)` (or `reloadAllTimelines()`) on data change |

Reloads are **budgeted**, not immediate — the system may coalesce or delay them (roughly a few dozen
background refreshes/day). If your widget must reflect an app change *now*, push it from the app with
`WidgetCenter` and share data via an **App Group** container, not a background timer inside the widget.

## Families per surface (set `supportedFamilies`)

| Family | Surface |
|---|---|
| `.systemSmall/.systemMedium/.systemLarge` | Home Screen, Today, macOS desktop |
| `.systemExtraLarge` | iPad Home Screen, macOS |
| `.accessoryCircular/.accessoryRectangular/.accessoryInline` | **Lock Screen**, StandBy, and **watchOS complications** (same families) |

`.accessory*` render **monochrome/vibrant** — design for the tint treatment; use
`.widgetAccentable()` to mark the parts that take the accent. StandBy uses the same accessory/system
families, shown larger and often always-on (dim aggressively).

## Configurable widgets — App Intents, not SiriKit

Since iOS 17, user-editable widgets use **`AppIntentConfiguration`** + an `AppIntentTimelineProvider`
with a `WidgetConfigurationIntent` (an App Intent) — this replaced the old
`IntentConfiguration` + SiriKit intent definition file. The intent's parameters become the "Edit
Widget" fields. (This ties into the `app-integration` / App Intents skill.)

## Interactive widgets (iOS 17+ / macOS 14+)

Widgets can now contain a **`Button`** or **`Toggle`** whose action is an **App Intent** — the only
code that may run from a widget tap without launching the app:

```swift
Button(intent: ToggleTaskIntent(id: task.id)) { Label("Done", systemImage: "checkmark") }
Toggle(isOn: task.isDone, intent: ToggleTaskIntent(id: task.id)) { Text(task.title) }
```

Everything else is still a **deep link**: wrap content in `Link(destination:)` (system/medium+) or
set `.widgetURL(_:)` (whole small widget) and handle it in the app via `onOpenURL`.

## Live Activities + Dynamic Island (ActivityKit)

A Live Activity is a separate `ActivityConfiguration` (a `Widget`) backed by an
`ActivityAttributes` type. You provide:

- the **Lock Screen / banner** view, and
- the **Dynamic Island** in three presentations: `.compactLeading`/`.compactTrailing`, `.minimal`,
  and `.expanded` (regions: leading/trailing/center/bottom).

Start with `Activity.request(...)`, update with `activity.update(...)`, end with `activity.end(...)`.
Push updates via ActivityKit push tokens for server-driven changes. Budget and duration limits apply;
design the ended/stale state.

## Cross-platform notes

- **watchOS complications** are just WidgetKit `.accessory*` widgets now — build them the same way,
  add the complication families, keep them glanceable (see the watchOS "seconds" session rule).
- **macOS**: system families on the desktop and in Notification Center; respect that the Mac widget
  may be always visible.
- **visionOS**: widgets render in the shared space; mind depth and the glass material — no hardcoded
  opaque backgrounds.

## Verify with RenderPreview (design-contract check)

Use the `xcode-mcp` skill's `RenderPreview` to snapshot the widget **without installing to a Home
Screen**, and — crucially — pass `previewCanvasControlOverrides.timelineIndex` to render **each
timeline entry** and `toggleState` for Live Activity states. That lets a vision model verify every
frame the user will see, including the transition frames, against the design.

```
RenderPreview { tabIdentifier, sourceFilePath: "…/MyWidget.swift",
                previewCanvasControlOverrides: { timelineIndex: 2 } }
```

## Gotchas

| Symptom | Cause / fix |
|---|---|
| Widget shows blank / clipped on iOS 17+ | Missing `.containerBackground(_:for:.widget)` — now required |
| Widget never updates | Relying on `.never` without calling `WidgetCenter.shared.reloadTimelines`; or expecting real-time refresh (it's budgeted) |
| App and widget see different data | No shared **App Group**; the widget process can't read the app's sandbox otherwise |
| Lock Screen widget looks wrong | It's rendered monochrome/vibrant; use `.widgetAccentable()`, don't rely on color |
| Tap does nothing | Interactive action must be an **App Intent** via `Button(intent:)`/`Toggle(isOn:intent:)`; other closures don't run in-widget |
| Configurable widget won't build | Mixing old `IntentConfiguration`/SiriKit with new `AppIntentConfiguration` — pick the App Intents path on iOS 17+ |

## Honest limits

- Exact **refresh budgets**, timeline entry caps, and Live Activity duration limits are set by the
  system and shift across OS versions — treat "a few dozen/day" as a planning figure, not a contract;
  confirm current numbers in the WidgetKit docs (`DocumentationSearch`).
- Pre-iOS-17 widgets (SiriKit `IntentConfiguration`, no interactivity, no `containerBackground`)
  aren't covered here; this skill targets the modern App Intents + interactive path.
- ActivityKit push and RealityKit/visionOS widget specifics are summarized, not exhaustive — deep
  Dynamic Island layout and push-token plumbing warrant their own pass.
