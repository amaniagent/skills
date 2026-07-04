---
name: react-native-to-swift
description: Migrate a React Native app to native Swift/SwiftUI with a concrete concept-to-concept mapping (View→VStack, FlatList→List, useState→@State, useEffect→task/onAppear, React Navigation→NavigationStack, Redux→@Observable, fetch→URLSession, Reanimated→withAnimation, native modules→direct Swift APIs) and a strangler-fig migration plan. Honest about the cross-platform trade: RN ships Android too, so going native-Apple means pairing with swift-on-android/Skip or maintaining two UIs. Uses app-planning-per-platform for the target. Use when moving an RN app to SwiftUI, scoping such a migration, or mapping specific RN patterns to their SwiftUI equivalents. Triggers include "migrate React Native to Swift", "rewrite this RN app in SwiftUI", "SwiftUI equivalent of this RN component", "port React Native to native iOS".
---

# React Native → Swift/SwiftUI

Moving off React Native to native Swift buys native performance and feel, direct access to new Apple
APIs (incl. on-device FoundationModels), and no JS bridge — at the cost of RN's cross-platform reach.
Decide the target with `app-planning-per-platform` first, then use the mapping and plan below.

> ⚠️ **The trade, stated up front.** RN gives you iOS **and** Android from one codebase. A native
> SwiftUI rewrite is Apple-only unless you *also* adopt `swift-on-android` (share a Swift core, Kotlin/
> Compose UI) or **Skip** (SwiftUI→Compose transpilation). Put this decision in the plan before writing
> code — it changes the whole scope.

## Migration strategy: strangler-fig, not big-bang

Two viable paths:

1. **Screen-by-screen (strangler-fig)** — embed SwiftUI into the running RN app via a native module
   / `RCTRootView` host, replace one screen at a time, delete RN as coverage grows. Lower risk for
   large apps; you ship continuously.
2. **Clean native rebuild** — for small/medium apps a from-scratch SwiftUI build is often *cleaner*
   than bridging, using the RN app purely as the behavior spec (see `repo-to-swift-native` for the
   oracle discipline).

Pick per app size and how much native-module glue already exists.

## Concept mapping

| React Native | SwiftUI / Swift |
|---|---|
| `<View>` | `VStack` / `HStack` / `ZStack` (+ a plain container) |
| `<Text>` | `Text` |
| `<Image>` | `Image` / `AsyncImage` |
| `<ScrollView>` | `ScrollView` |
| `<FlatList>` / `<SectionList>` | `List` or `LazyVStack`/`LazyVGrid` in a `ScrollView` |
| `<TouchableOpacity>` / `Pressable` | `Button` (+ `.buttonStyle`) |
| `<TextInput>` | `TextField` / `SecureField` |
| `<Modal>` | `.sheet` / `.fullScreenCover` |
| `StyleSheet` / inline styles | view modifiers (`.padding`, `.background`, `.font`, …) |
| Flexbox layout | stacks + `Spacer` + `.frame` + `Layout`/`Grid` |
| `useState` | `@State` |
| `useReducer` | `@State` + an update function, or an `@Observable` model |
| `useEffect(fn, [])` (mount) | `.task { }` / `.onAppear` |
| `useEffect(fn, [dep])` | `.onChange(of: dep)` / `.task(id: dep)` |
| `useContext` / Context | `@Environment` / `@Observable` in the environment |
| Redux / Zustand / MobX | `@Observable` model(s) (Observation), injected via `@Environment` |
| React Navigation (stack) | `NavigationStack` + `navigationDestination` |
| React Navigation (tabs) | `TabView` |
| `AsyncStorage` | `UserDefaults` (small) / **SwiftData** (structured) |
| `fetch` / axios | `URLSession` `async` APIs, `Codable` |
| Reanimated / Animated | `withAnimation` / `.animation` / `Transaction`; shaders for effects (`metal-shaders`) |
| Native module (Obj-C/Java bridge) | call the Swift/Apple API **directly** — the reason to migrate |
| Hermes/JS runtime | gone — native compiled Swift |

## Watch-outs

- **State model shift.** RN re-renders from top on state change; SwiftUI diffs a declarative tree
  driven by `@State`/`@Observable`. Don't recreate a Redux mega-store — prefer small `@Observable`
  models scoped to features (Apple ships `swiftui-specialist`; use it for idiomatic SwiftUI).
- **Layout shift.** Flexbox → stacks. Resist porting a flex tree 1:1; re-express with stacks, frames,
  and `Grid`.
- **Lists.** `FlatList` perf tricks (getItemLayout, windowing) map to `List`/`Lazy*` — SwiftUI does
  the windowing; drop the manual optimization.
- **Navigation.** RN's imperative `navigation.navigate` becomes value-driven `NavigationStack` paths;
  model routes as data.
- **Native modules are the payoff.** Anything you wrote a bridge for (camera, BLE, HealthKit,
  payments) becomes a direct Swift call — see `app-integration`, `healthkit`, etc.

## Verify

Per migrated screen, `RenderPreview` (xcode-mcp) the SwiftUI and compare against a screenshot of the
RN screen — a vision model can grade parity (the design-contract check). For behavior, drive the RN
app and the SwiftUI build with the same inputs and compare (oracle method).

## Honest limits

- **You may lose Android.** The single biggest consequence; decide the cross-platform strategy in the
  plan (`swift-on-android` / Skip / two UIs) — this skill doesn't make that problem disappear.
- This maps **concepts**, not code — there's no reliable automatic RN→SwiftUI transpiler; expect to
  rebuild UI, not translate it.
- Large apps with heavy native-module surface need a real strangler-fig plan and continuous shipping;
  a naive full rewrite stalls.
- Third-party RN libraries (maps, charts, gesture systems) need native Swift equivalents chosen
  case-by-case — inventory them early; some have no drop-in match.
