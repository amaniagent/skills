---
name: app-planning-per-platform
description: Plan an Apple app before writing code by making the platform choice explicit — iOS, iPadOS, macOS, watchOS, visionOS — and pinning down the deltas that actually change the architecture: navigation paradigm, window/scene model, lifecycle, input, and the Human Interface Guidelines that differ per platform. Produces a filled-in planning doc, not vibes. Use when starting a new Apple app or adding a platform to an existing one, when deciding "should this be multiplatform or per-platform", or when a design that felt right on iPhone falls apart on Mac or Watch. Triggers include "plan an iOS app", "make this work on Mac too", "watchOS companion", "visionOS version", "which platform should this target".
---

# Planning an Apple app, per platform

Apple ships `swiftui-specialist` and `swiftui-whats-new-27` as agent skills (export with
`xcrun mcpbridge run-agent skills export` — see `xcode-mcp`). Those cover *how to write* the
SwiftUI. This skill covers *what to build and where*.

## Step 1 — one target or several?

- **Multiplatform, shared UI** — only when the interaction model is genuinely the same. You still
  branch layout with size classes and `#if os(...)`.
- **Shared core, per-platform UI** — the common case: one domain layer (Swift package), a distinct
  SwiftUI layer per platform.
- **Separate app entirely** — watchOS and visionOS often earn this. A Watch app is not a small
  phone app; a visionOS app is not a floating iPad app.

## Step 2 — the deltas that change architecture

| Concern | iOS (iPhone) | iPadOS | macOS | watchOS | visionOS |
|---|---|---|---|---|---|
| **Navigation** | `NavigationStack`, tab bar, sheets | `NavigationSplitView` (2–3 col), sidebar, multiple windows | `NavigationSplitView`, menu bar, toolbar, multiple windows | Hierarchical push / `TabView`, tiny | `NavigationSplitView`, ornaments, windows in space |
| **Window/scene** | one full-screen scene | `WindowGroup` + multi-window, Stage Manager | `WindowGroup`, `Settings`, `MenuBarExtra`, resizable | single app, no windowing | `WindowGroup`, `Volume` (`.volumetric`), `ImmersiveSpace` |
| **Input** | touch, no hover, no keyboard assumed | touch + pencil + pointer + keyboard | pointer + keyboard, right-click menus | Digital Crown, taps, gestures | eyes + pinch, indirect; no direct touch |
| **Canonical extras** | widgets, App Clips, Live Activities | same + Scribble, external display | menu bar item, Services, drag-drop, AppleScript | **complications**, notifications, Smart Stack | ornaments, hand tracking, RealityKit |
| **Screen size / density** | small, one-handed reach | large, split views | huge, dense, keyboard-first | ~1.5–2", glanceable | infinite, depth, comfort zone |
| **Session length** | minutes | minutes–hours | hours | **seconds** | minutes, comfort-limited |

### Lifecycle — scene-based everywhere, but budgeted differently

All platforms use the SwiftUI `App`/`Scene` lifecycle and `@Environment(\.scenePhase)`.

- **iOS/iPadOS**: background execution is tightly budgeted — plan `BGTaskScheduler`, not "keep
  running". Multi-window (iPad) means state must be per-scene, not global.
- **macOS**: the app keeps running with no windows; handle `MenuBarExtra`-only states, termination
  via the App menu, and windows opening/closing independently.
- **watchOS**: do the work in background/complication refresh, not while the user watches a
  spinner. "Glance and gone."
- **visionOS**: `ImmersiveSpace` has its own open/dismiss lifecycle on top of scene phase; only one
  immersive space open at a time; respect `.mixed` / `.progressive` / `.full`.

### HIG deltas worth pinning early

- **Touch targets & reach**: 44pt minimum on touch platforms; Mac can go denser with a pointer;
  watchOS uses full-width rows and the Crown.
- **Navigation depth**: deep push stacks are fine on iPhone, wrong on Mac (split view + sidebar),
  painful on Watch (1–2 levels).
- **Chrome**: iPhone hides it; Mac expects menu bar + toolbar + keyboard shortcuts for
  *everything*; visionOS puts controls in **ornaments**, not floating buttons.
- **Color/material**: system materials and semantic colors, so Dark Mode, Increase Contrast, and
  visionOS glass/vibrancy come for free. Never hardcode opaque backgrounds on visionOS.
- **Dynamic Type** from day one, not as a late accessibility bolt-on.

## Step 3 — pin the decisions

Per app, one line each: one-sentence purpose and primary job-to-be-done · target strategy (single
multiplatform UI / shared core + per-platform UI / separate apps) · minimum OS per platform · what
lives in the shared core · persistence + cross-device sync · system integration (App Intents,
widgets/complications/Live Activities, notifications — see `app-integration`, `widgets`).

Per **checked platform**, one block: why this platform *and why not the others* · navigation
model · scene/window model · primary input · platform-specific features · expected session length
and the "glance" test · **what is DIFFERENT here vs. the others** (the delta that justifies
per-platform work at all) · test plan.

An unanswered field is an undecided risk, not a blank.

### HIG risk check

- [ ] Touch targets ≥44pt on touch platforms
- [ ] Dynamic Type + semantic colors + materials
- [ ] Dark Mode / Increase Contrast handled
- [ ] Keyboard shortcuts on Mac (menus complete)
- [ ] No hardcoded opaque backgrounds on visionOS

## Verification loop

Planning is done when each targeted platform **renders and runs**: `RenderPreview` per platform
(`xcode-mcp`) graded against the design contract, then build/run. A plan that only "compiles for
iPhone" hasn't verified the deltas it claimed.

## Honest limits

- The HIG evolves per OS release; this skill states **principles, not current pixel values** —
  confirm metrics against the live HIG, new APIs via `DocumentationSearch` / `swiftui-whats-new-27`.
- Planning only — it does not teach SwiftUI, RealityKit, or WidgetKit implementation.
- tvOS is out of scope; the same delta method applies if you add it.
