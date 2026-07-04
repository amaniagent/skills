---
name: swift-on-android
description: Run Swift on Android using the official Swift SDK for Android (shipped with Swift 6.3, March 2026, owned by the Swift Android Workgroup) — cross-compile Swift into Android .so shared libraries via the Android NDK and call them from Kotlin/Java over JNI. Covers the realistic architecture (share a Swift core, native UI per platform), where SwiftUI-on-Android stands (not native — Skip transpiles to Compose), the SDK setup, and an honest read of maturity (officially supported but tooling/debugging still early preview, ~60MB runtime). Use when sharing Swift business logic with an Android app, evaluating cross-platform Swift, or scoping the Android side of a Swift-native product. Triggers include "Swift on Android", "share Swift code with Android", "Swift Android SDK", "call Swift from Kotlin", "cross-platform Swift core".
---

# Swift on Android — official, but read the maturity note

As of **Swift 6.3 (March 2026)** there is an **official Swift SDK for Android**, owned and versioned
by the **Swift Android Workgroup** — not a community hack. You cross-compile Swift to Android
**shared libraries (`.so`)** with the **Android NDK (27d)** and bridge to Kotlin/Java via **JNI**.
Over a quarter of Swift Package Index packages have Android-adapted. This is the piece that makes
"Swift-native first" genuinely cross-platform.

> ⚠️ **Maturity (mid-2026).** Officially *supported*, but still **early preview** on tooling: IDE
> integration, debugging, and docs are rougher than mature Android toolchains, and the Swift runtime
> + Foundation add **~60 MB** (shrinking as it matures). The remaining problems are engineering, not
> existential — but plan for rough edges. Verify specifics against Swift.org's "Swift SDK for
> Android" docs for your toolchain version.

## The realistic architecture

Don't try to write the whole Android app in Swift. The high-value pattern:

```
        ┌─────────────── shared Swift core (SwiftPM) ───────────────┐
        │  models · business logic · networking · persistence rules  │
        └───────────────────────────────────────────────────────────┘
             ▲                                          ▲
   SwiftUI (Apple)                        JNI ──► Kotlin/Compose (Android)
   native UI                              compiled to .so, loaded by the app
```

- **Business/domain/networking logic** → one Swift package, compiled to a native `.so` for Android
  and linked normally on Apple. Write and test it once.
- **UI stays native per platform**: SwiftUI on Apple, **Kotlin/Jetpack Compose** on Android, each
  calling the shared core. This is the same "shared core, per-platform UI" split from
  `app-planning-per-platform`.

## SwiftUI on Android — not native

There is **no native SwiftUI renderer on Android**. Options:

- **Skip** (skip.dev) — transpiles SwiftUI/Swift to Kotlin/Jetpack Compose at build time; the
  closest thing to "SwiftUI on Android," but it's a third-party framework with its own model and
  subset — evaluate it (and audit per Gate-Everything) before betting on it.
- **Hand-written Compose UI** over the shared Swift core via JNI — more work, full control, no
  transpiler surprises.

Be explicit in the plan which one you're using; "just reuse my SwiftUI" is not free on Android.

## Setup (shape)

```bash
# Install the official Swift SDK for Android into your host toolchain
swift sdk install <android-swift-sdk-bundle-url>     # from Swift.org for your Swift version
swift sdk list

# Cross-compile a package to an Android .so (per ABI, e.g. aarch64)
swift build --swift-sdk aarch64-unknown-linux-android <flags>
```

You need a matching **host toolchain**, the **Swift SDK for Android**, and the **Android NDK 27d**.
The output `.so` goes into the Android app's `jniLibs`, and you expose Swift functions through a
**JNI** boundary (a small C-ABI shim Swift can export, called from Kotlin via `external fun`).

## JNI boundary — keep it thin

- Cross the bridge with **C-ABI-friendly** signatures (primitives, pointers, byte buffers); marshal
  structured data as serialized bytes (JSON/`Codable` or a compact format), not as rich Swift types.
- Keep the surface **small and stable** — a handful of coarse entry points, not hundreds of fine
  calls (JNI calls have overhead and each is a maintenance point).
- Manage lifetimes carefully across the boundary; the Swift side owns its memory, hand Android copies.

## Verify

- Build the `.so` for each target ABI (`swift build --swift-sdk …`).
- Load it in a minimal Android app (`System.loadLibrary`), call one JNI entry point, run on an
  emulator/device, confirm the round-trip.
- Test the shared core the normal way (`swift test`) on the host — most logic verification happens
  there, not on-device.

## Honest limits

- **Early-preview tooling.** Debugging Swift on Android, IDE support, and docs are not yet at Android
  Studio/Kotlin polish. Budget time for setup friction and thin error messages.
- **Binary size** (~60 MB runtime + Foundation) matters for app download size today; weigh it against
  the code-sharing benefit.
- **Not every package works** — ~25%+ of SPI is adapted, not all; check each dependency's Android
  support before relying on it.
- **No native SwiftUI** — cross-platform UI is Skip (transpiled) or hand-written Compose, both with
  their own trade-offs; this skill shares *logic*, not UI, by default.
- This is a fast-moving area that **just went official**; treat setup commands and SDK bundle URLs as
  version-specific and confirm against current Swift.org Android docs.
