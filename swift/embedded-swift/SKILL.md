---
name: embedded-swift
description: Write firmware for microcontrollers in Embedded Swift — the experimental compilation mode that produces tiny, runtime-free binaries for bare-metal ARM Cortex-M and RISC-V targets (Raspberry Pi Pico/RP2040, ESP32-C6 via ESP-IDF, nRF52840, STM32). Covers what the language subset removes (no reflection, no metadata, constrained existentials, no ObjC), enabling it in SwiftPM, C interop with vendor SDKs, and a method to port existing C/Arduino/MicroPython firmware into Embedded Swift. Honest about maturity: it is experimental, snapshot-toolchain only, not production-ready. Use when building firmware for an ESP32/Pico/nRF board, a sensor/actuator controller (e.g. an LED grow-light or auto-watering rig), or porting embedded logic to Swift. Triggers include "Embedded Swift", "Swift on ESP32", "Swift firmware", "blink an LED in Swift", "port this Arduino sketch to Swift".
---

# Embedded Swift — Swift on bare metal

Embedded Swift is a **compilation mode** (not a fork) that emits small, self-contained binaries with
**no Swift runtime**, suitable for microcontrollers. It's the firmware layer of a "Swift-native
first" stack — the same language from the cloud (Vapor) to the app (SwiftUI) to the sensor board.

> ⚠️ **Maturity — read this first.** As of mid-2026 Embedded Swift is still **experimental**: it
> ships only in **development-snapshot toolchains** (not stable Swift releases) and is **not
> production-ready**. Expect API churn and snapshot-specific breakage. Supported boards include
> **RP2040 (Raspberry Pi Pico), ESP32-C6 (RISC-V, via ESP-IDF 6.x), nRF52840, STM32F746**. Treat
> everything below as "current pattern," and verify against `swiftlang/swift-embedded-examples` and
> the Swift.org Embedded pages for your toolchain.

## What the subset removes (and why)

No runtime means no features that need runtime metadata:

| Removed / constrained | Consequence |
|---|---|
| Reflection (`Mirror`), full metadata | no runtime type introspection |
| Non-final dynamic casts, arbitrary `any` existentials | use `final class`, generics, and constrained protocols; class-bound existentials are OK |
| Objective-C interop | no Foundation-via-ObjC; a slim stdlib subset only |
| Implicit heap allocation | allocation is explicit/limited — prefer value types and static storage |
| `print` to a console by default | you provide output (UART/semihosting) |

**ARC works**, generics work, structs/enums/protocols work. Write in value types, avoid heap where
you can, keep data static. This is closer to "Swift as a better C" than "Swift as on the phone."

## Enabling it (SwiftPM sketch)

```swift
// Package.swift target
.executableTarget(name: "Firmware",
    swiftSettings: [
        .enableExperimentalFeature("Embedded"),
        .unsafeFlags(["-wmo"])                 // whole-module is required
    ])
```

Build with a **development-snapshot** toolchain for the board's triple (e.g. `armv6m-none-none-eabi`
for RP2040, a RISC-V triple for ESP32-C6), no stdlib auto-link. In practice you build **through the
vendor toolchain**: for ESP32-C6 as an **ESP-IDF component**; for Pico via the **Pico SDK** +
CMake, with Swift compiled in. The examples repo has working build scripts per board — start from
those, don't assemble flags from scratch.

## C interop is the whole game

Firmware talks to hardware through the vendor C SDK — GPIO, I2C, SPI, ADC, PWM, timers. Embedded
Swift's C interop is how you reach them:

```swift
// Call the vendor SDK from Swift (Pico SDK example shape)
gpio_init(LED_PIN)
gpio_set_dir(LED_PIN, true)          // output
while true {
    gpio_put(LED_PIN, true);  sleep_ms(500)
    gpio_put(LED_PIN, false); sleep_ms(500)
}
```

You import the SDK's C headers as a module and call them directly. Register-level access is either
through the SDK's C functions or thin Swift wrappers over memory-mapped registers. The "hello world"
is a **blinking LED** — get that building and flashing before anything else.

## Porting existing firmware to Embedded Swift (the "rewrite" method)

To move a C/Arduino sketch or MicroPython program to Embedded Swift, don't translate line-by-line —
**re-express the layers**:

1. **Map the hardware surface.** List every peripheral the code touches (GPIO/I2C/SPI/ADC/PWM/UART)
   and the exact vendor SDK calls. That's your C-interop boundary.
2. **Keep the vendor SDK.** You're replacing the *logic*, not the HAL — call the same ESP-IDF/Pico
   SDK C functions from Swift.
3. **Translate logic to value types.** State machines → enums; buffers → fixed-size arrays/tuples or
   `UnsafeBufferPointer`; classes only where you need identity, `final`.
4. **Strip disallowed features.** No reflection, no dynamic casts, no Foundation — swap them for
   static equivalents. If a library needs the runtime, it doesn't come along.
5. **Static-allocate.** Replace dynamic allocation with statically sized storage; audit anything that
   grows unbounded.
6. **Verify incrementally.** Port one peripheral at a time, flash, confirm on hardware, then the next.
   A blink first, then one sensor, then the control loop.

Concretely for the **LED grow-light / auto-watering** kind of build (Track D `led-pflanzenwuchs`):
the firmware layer is Embedded Swift on an ESP32-C6 — read soil-moisture/light (ADC), drive
pumps/LEDs (GPIO/PWM), and the control logic (thresholds, schedules) is exactly the value-type Swift
this method produces.

## Reference

`swiftlang/swift-embedded-examples` (official Apple/swiftlang, MIT) — per-board projects and build
scripts. Read-only reference: clone into a throwaway dir, copy the board setup you need. It's the
canonical source of the *working* flag/toolchain combination, which is the part most likely to break
between snapshots.

## Verify

- **Build** for the target triple with the snapshot toolchain (through the vendor build system).
- **Flash** to the board (`picotool`, `esptool`/`idf.py flash`, `probe-rs`, or the SDK's flasher).
- **Observe** on hardware — LED blink, UART/serial log, or a logic analyzer. There is **no
  simulator/RenderPreview path** for firmware; the board is the test.

## Gotchas

| Symptom | Cause / fix |
|---|---|
| "experimental feature not enabled" | Missing `-enable-experimental-feature Embedded`; also needs `-wmo` |
| Won't compile with a release Swift | Embedded mode needs a **development snapshot** toolchain, not stable Swift |
| Link errors about the runtime/stdlib | You pulled in a feature that needs the runtime (reflection, Foundation, dynamic cast) — remove it |
| `Mirror`/`as?`/`any P` rejected | Not available/constrained in Embedded — use generics, `final class`, static dispatch |
| Binary too big / won't fit | Unbounded allocation or heavy generics bloat — check static sizes, prune |
| ESP32 build fails | Toolchain/ESP-IDF version mismatch — match the examples repo's ESP-IDF (6.x) + snapshot pairing |

## Honest limits

- **Experimental, snapshot-only, not production.** Anything here can change between toolchain
  snapshots; this skill gives the shape and method, not a stable API contract.
- Board/peripheral coverage is **narrow and specific** — RP2040, ESP32-C6, nRF52840, STM32F746 are
  the well-trodden targets; others may need extra bring-up.
- This skill does not cover RTOS integration depth, DMA, or low-level linker-script authoring — those
  are per-board rabbit holes. Start from the examples repo's known-good setup.
- The "rewrite" method is a *porting discipline*, not an automatic transpiler — expect to make
  design decisions (allocation, concurrency) that the source language hid.
