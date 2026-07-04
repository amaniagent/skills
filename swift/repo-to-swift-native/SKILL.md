---
name: repo-to-swift-native
description: Analyze a foreign codebase (any language/stack) and plan a native-Swift rebuild the disciplined way — audit first, reverse-engineer the domain, choose the target surface (app / server / firmware), map the stack to Swift equivalents, and rebuild in verifiable slices with the original as a behavior oracle. Uses app-planning-per-platform for the target and repo-auditor as the gate. Use when deciding whether and how to reimplement an existing project in Swift, when someone says "let's rebuild this in Swift-native", or when scoping a migration off a non-Swift stack. Triggers include "rewrite this repo in Swift", "port this project to native Swift", "should we rebuild X in Swift", "plan a Swift rewrite of".
---

# Repo → native Swift — rebuild without importing the mistakes

Rewriting a working system in Swift is high-risk: most rewrites fail by porting *incidental* detail
(one language's idioms, a framework's workarounds) instead of the *essential* behavior. This skill is
the discipline that avoids that. It's a planning/method skill — it leans on
`app-planning-per-platform` (target decision) and `repo-auditor` (the gate).

## 0. Gate first (never skip)

The source is untrusted until proven otherwise. **Run `repo-auditor` before you read deeply or run
anything** — clone into a throwaway dir, score it, and never execute install scripts/CI of a repo you
don't control (Gate-Everything). You're studying behavior, not adopting their supply chain.

## 1. Reverse-engineer the domain (not the code)

Separate **essential** complexity (what the system does) from **incidental** (how this stack happened
to do it):

- **Features & user-visible behavior** — the contract you must preserve.
- **Data model & invariants** — entities, relationships, the rules that must always hold.
- **External surface** — APIs called, protocols, file formats, auth.
- **Incidental artifacts to drop** — framework boilerplate, language workarounds, dead paths, bugs
  you don't want to reproduce.

Write this down. The output is a spec of *what*, decoupled from the original *how*.

## 2. Choose the target surface

Use `app-planning-per-platform`. A "Swift rewrite" can land in very different places:

| Original is… | Likely Swift target | Skill |
|---|---|---|
| A mobile/desktop app | SwiftUI app, per platform | `app-planning-per-platform` |
| A web backend / API | Vapor server | `swift-vapor` |
| Device/microcontroller firmware | Embedded Swift | `embedded-swift` |
| A library / CLI | Swift package / SwiftPM executable | — |

Decide platforms and the target/architecture split *before* mapping code.

## 3. Map the stack to Swift equivalents

| Foreign concept | Native Swift |
|---|---|
| Dependencies (npm/pip/gem/cargo…) | SwiftPM packages, or a native framework; drop what the platform already gives you |
| ORM / DB layer | SwiftData (app) or Fluent (server) |
| HTTP client / server | `URLSession` (client) / Vapor (server) |
| JSON models | `Codable` structs |
| Async runtime (promises, goroutines, asyncio) | Swift Concurrency (`async/await`, actors, task groups) |
| DI container | plain init injection / `@Environment` |
| Test framework | Swift Testing (see Apple's shipped `test-modernizer`) |

Where a dependency is battle-tested C, consider **wrapping via C interop** instead of rewriting it
(decide per component — see §5).

## 4. Rebuild in verifiable slices

Never big-bang. Order by dependency, inside-out:

1. **Core/domain first** — a pure Swift package (models + logic), no IO, fully unit-tested. This is
   where the invariants from §1 become tests.
2. **IO layer** — persistence, networking, platform APIs.
3. **UI / entrypoint last** — SwiftUI / Vapor routes / firmware loop.

Drive each slice with **TDD against the original's observable behavior**: the source system is your
**oracle** — feed both the same inputs, assert the same outputs. (See the `test-driven-development`
and `writing-plans` skills for the loop and the plan format.)

## 5. Rewrite vs wrap vs keep

Not everything should be rewritten:

- **Rewrite** logic and anything idiomatic-in-Swift (models, control flow, UI).
- **Wrap** a proven C/C++ core via Swift's C interop when reimplementing it is pure risk (codecs,
  crypto, parsers).
- **Keep** (don't migrate) whatever isn't yours to own — external services stay external.

## Verify

- Core package: `swift test` green, invariants covered.
- Behavior parity: run the oracle comparison on real inputs; differences are either bugs you fixed
  (document them) or regressions (fix them).
- UI slices: `RenderPreview` (xcode-mcp) each screen and compare against the original app's screens.

## Honest limits

- **Rewrites are expensive and frequently unjustified.** The most honest output of this skill is
  sometimes "don't — wrap it, or ship a thin native slice around the existing system." Recommend the
  smallest valuable native slice first; prove value before committing to a full port.
- This is a **method**, not an automatic translator. Expect real design decisions (concurrency model,
  persistence, error handling) the source language hid.
- Cross-platform reach: going native-Swift-on-Apple may *lose* the platforms the original covered
  (e.g. a web or React Native app's Android/web) — pair with `swift-on-android` / `react-native-to-swift`
  and be explicit about that trade in the plan.
- The behavior-oracle approach needs the original to be *runnable* on your inputs; where it isn't,
  fall back to its tests/specs and be honest about the coverage gap.
