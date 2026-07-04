---
name: app-planning-per-platform
description: Plan an Apple app before writing code by making the platform choice explicit — iOS, iPadOS, macOS, watchOS, visionOS — and pinning down the deltas that actually change the architecture: navigation paradigm, window/scene model, lifecycle, input, and the Human Interface Guidelines that differ per platform. Produces a filled-in planning doc, not vibes. Use when starting a new Apple app or adding a platform to an existing one, when deciding "should this be multiplatform or per-platform", or when a design that felt right on iPhone falls apart on Mac or Watch. Triggers include "plan an iOS app", "make this work on Mac too", "watchOS companion", "visionOS version", "which platform should this target".
---

# Planning an Apple app, per platform

Most Apple-app mistakes are made *before the first line of code*: a navigation model borrowed from
iPhone that breaks on Mac, a watchOS app planned like a phone app, a "multiplatform" target that
ships a lowest-common-denominator UI on every device. This skill forces the platform decision to be
explicit and gives you a **fill-in planning doc** so the deltas are decided on purpose.

**Rule 8 first:** Apple ships `swiftui-specialist` and `swiftui-whats-new-27` as agent skills (export
with `xcrun mcpbridge run-agent skills export` — see the `xcode-mcp` skill). Those cover *how to
write* the SwiftUI. This skill covers *what to build and where* — the planning layer above them.

## Step 1 — one target or several?

A single SwiftUI `App` can declare multiple `Scene`s and run on many platforms, but "compiles
everywhere" ≠ "belongs everywhere." Decide per platform:

- **Multiplatform, shared UI** — only when the interaction model is genuinely the same (a reader, a
  simple form-driven tool). You still branch layout with size classes and `#if os(...)`.
- **Shared core, per-platform UI** — the common case. One model/domain layer (a Swift package), a
  distinct SwiftUI layer per platform. This is what "Swift-native first" wants: logic once, surface
  per device.
- **Separate app entirely** — watchOS and visionOS often earn this. A Watch app is not a small phone
  app; a visionOS app is not a floating iPad app.

## Step 2 — the deltas that change architecture

| Concern | iOS (iPhone) | iPadOS | macOS | watchOS | visionOS |
|---|---|---|---|---|---|
| **Navigation** | `NavigationStack`, tab bar, sheets | `NavigationSplitView` (2–3 col), sidebar, multiple windows | `NavigationSplitView`, menu bar, toolbar, multiple windows | Hierarchical push / `TabView`, tiny | `NavigationSplitView`, ornaments, windows in space |
| **Window/scene** | one full-screen scene | `WindowGroup` + multi-window, Stage Manager | `WindowGroup`, `Settings`, `MenuBarExtra`, resizable | single app, no windowing | `WindowGroup`, `Volume` (`.volumetric`), `ImmersiveSpace` |
| **Input** | touch, no hover, no keyboard assumed | touch + pencil + pointer + keyboard | pointer + keyboard, right-click menus | Digital Crown, taps, gestures | eyes + pinch, indirect; no direct touch |
| **Canonical extras** | widgets, App Clips, Live Activities | same + Scribble, external display | menu bar item, Services, drag-drop, AppleScript | **complications**, notifications, Smart Stack | ornaments, hand tracking, RealityKit |
| **Screen size / density** | small, one-handed reach | large, split views | huge, dense, keyboard-first | ~1.5–2", glanceable | infinite, depth, comfort zone |
| **Session length** | minutes | minutes–hours | hours | **seconds** | minutes, comfort-limited |

### Lifecycle — it's scene-based everywhere (SwiftUI)

All platforms use the SwiftUI `App`/`Scene` lifecycle and `@Environment(\.scenePhase)`
(`.active` / `.inactive` / `.background`). Platform notes:

- **iOS/iPadOS**: background execution is tightly budgeted — plan `BGTaskScheduler`, not "keep
  running." Multi-window (iPad) means state must be per-scene, not global.
- **macOS**: app keeps running with no windows; handle `MenuBarExtra`-only states, termination via
  the App menu, and windows opening/closing independently.
- **watchOS**: extremely short sessions; do work in the background/complication refresh, not while
  the user watches a spinner. Design for "glance and gone."
- **visionOS**: `ImmersiveSpace` has its own open/dismiss lifecycle on top of scene phase; only one
  immersive space open at a time; respect the comfort/immersion styles (`.mixed` / `.progressive` /
  `.full`).

### HIG deltas worth pinning early

- **Touch targets & reach**: 44pt minimum on touch platforms; Mac can go denser with a pointer;
  watchOS uses full-width rows and the Crown for scrolling.
- **Navigation depth**: deep push stacks are fine on iPhone, wrong on Mac (use split view +
  sidebar) and painful on Watch (keep it 1–2 levels).
- **Chrome**: iPhone hides chrome; Mac expects a menu bar + toolbar + keyboard shortcuts for
  *everything*; visionOS puts controls in **ornaments** attached to windows, not floating buttons.
- **Color/material**: use system materials and semantic colors so Dark Mode, Increase Contrast, and
  visionOS's glass/vibrancy come for free. visionOS especially: don't hardcode opaque backgrounds.
- **Text & Dynamic Type**: support it from day one; it's not a late-stage accessibility bolt-on.

## Step 3 — fill in the planning doc

Copy this, answer every line, delete nothing. An unanswered field is an undecided risk.

```markdown
# App Plan — <app name>

## 1. What & who
- One-sentence purpose:
- Primary user & primary job-to-be-done:
- Success = user can:

## 2. Platforms (decide + justify each)
- [ ] iOS (iPhone)   — why / why not:
- [ ] iPadOS         — why / why not:
- [ ] macOS          — why / why not:
- [ ] watchOS        — why / why not:
- [ ] visionOS       — why / why not:
- Target strategy: [ ] single multiplatform UI  [ ] shared core + per-platform UI  [ ] separate apps
- Minimum OS versions (per platform):

## 3. Architecture split
- Shared core (Swift package) contains: (models, persistence, networking, domain logic)
- Per-platform UI layer contains:
- Persistence: [ ] SwiftData  [ ] Core Data  [ ] files  [ ] server — and why:
- Data sync across devices? [ ] no  [ ] CloudKit  [ ] own backend:

## 4. Per-platform surface (one block per checked platform)
### <platform>
- Navigation model:                       (stack / split view / tabs / …)
- Scene/window model:                     (single / WindowGroup+multi / Volume / ImmersiveSpace / MenuBarExtra)
- Primary input:                          (touch / pointer+keyboard / Crown / eyes+pinch)
- Platform-specific features used:        (widgets, complications, ornaments, menu bar, drag-drop…)
- What is DIFFERENT here vs. the others:  (the delta that justifies per-platform work)
- Session length & the "glance" test:

## 5. System integration
- App Intents / Shortcuts?                (see app-integration skill)
- Widgets / Live Activities / complications?  (see widgets skill)
- HealthKit / MapKit / other frameworks?  (see the matching skill)
- Notifications:

## 6. HIG risk check
- Touch targets ≥44pt on touch platforms:        [ ]
- Dynamic Type + semantic colors + materials:    [ ]
- Dark Mode / Increase Contrast handled:         [ ]
- Keyboard shortcuts on Mac (menus complete):    [ ]
- No hardcoded opaque backgrounds on visionOS:   [ ]

## 7. Build & verify (see xcode-mcp skill)
- Verify each platform via RenderPreview (design-contract check) + build/run:
- Test plan per platform:
```

## Verification loop

Planning isn't done when the doc is filled — it's done when each targeted platform **renders and
runs**. Use the `xcode-mcp` skill: `RenderPreview` per platform to sanity-check the layout against
the plan (a vision model can grade the screenshot against the design contract), then build/run on a
simulator or device. A plan that only "compiles for iPhone" hasn't verified the deltas it claimed.

## Honest limits

- The HIG evolves with each OS release and this skill states **principles, not the current pixel
  values** — confirm specific metrics against the live Human Interface Guidelines and, for new APIs,
  the `xcode` bridge `DocumentationSearch` or `swiftui-whats-new-27`.
- This is a *planning* skill. It does not teach SwiftUI, RealityKit, or WidgetKit implementation —
  those are separate skills. It makes sure you build the right thing on the right surface first.
- tvOS is out of scope here (focus platforms per Track A); the same delta method applies if you add it.
