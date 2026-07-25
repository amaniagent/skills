---
name: react-native-to-swift
description: Migrate a React Native app to native Swift/SwiftUI with a concrete concept-to-concept mapping (View→VStack, FlatList→List, useState→@State, useEffect→task/onAppear, React Navigation→NavigationStack, Redux→@Observable, fetch→URLSession, Reanimated→withAnimation, native modules→direct Swift APIs) and a strangler-fig migration plan. Honest about the cross-platform trade: RN ships Android too, so going native-Apple means pairing with swift-on-android/Skip or maintaining two UIs. Uses app-planning-per-platform for the target. Use when moving an RN app to SwiftUI, scoping such a migration, or mapping specific RN patterns to their SwiftUI equivalents. Triggers include "migrate React Native to Swift", "rewrite this RN app in SwiftUI", "SwiftUI equivalent of this RN component", "port React Native to native iOS".
---

# React Native → Swift/SwiftUI

Decide the target with `app-planning-per-platform` first, then use the mapping below.

> ⚠️ **The trade, stated up front.** RN gives you iOS **and** Android from one codebase. A native
> SwiftUI rewrite is Apple-only unless you *also* adopt `swift-on-android` (shared Swift core,
> Kotlin/Compose UI) or **Skip** (SwiftUI→Compose transpilation). Decide this before writing code —
> it changes the whole scope.

**Path:** embed SwiftUI into the running RN app (`RCTRootView` host) and replace screen by screen
for large apps; for small/medium apps a clean SwiftUI rebuild with the RN app as the behavior
oracle is usually cleaner than bridging (see `repo-to-swift-native`).

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

- **State model shift.** RN re-renders from top; SwiftUI diffs a declarative tree driven by
  `@State`/`@Observable`. Don't recreate a Redux mega-store — small models scoped to features.
- **Layout shift.** Don't port a flex tree 1:1; re-express with stacks, frames, and `Grid`.
- **Lists.** `FlatList` perf tricks (getItemLayout, windowing) are unnecessary — `List`/`Lazy*`
  window for you; drop the manual optimization.
- **Navigation.** RN's imperative `navigation.navigate` becomes value-driven `NavigationStack`
  paths; model routes as data.
- **Native modules are the payoff.** Camera, BLE, HealthKit, payments become direct Swift calls.
- **Third-party RN libraries** (maps, charts, gesture systems) need native equivalents chosen
  case-by-case — inventory them early; some have no drop-in match.

## Verify

Per migrated screen: `RenderPreview` (xcode-mcp) the SwiftUI and compare against a screenshot of
the RN screen. For behavior, drive both builds with the same inputs and compare (oracle method).
This maps **concepts**, not code — there is no reliable RN→SwiftUI transpiler; expect to rebuild
UI, not translate it.
