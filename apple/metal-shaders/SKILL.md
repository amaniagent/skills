---
name: metal-shaders
description: Add GPU shader effects to SwiftUI with Metal — the colorEffect / distortionEffect / layerEffect modifiers and stitchable MSL functions — without dropping to a full Metal render pipeline. Covers the three modifier contracts and their required MSL signatures, passing arguments (floats, colors, boundingRect, images, time) from Swift, animating shaders with TimelineView, bundling .metal files in SwiftPM, and using twostraws/Inferno (MIT, audited 0/8) as a reference library instead of writing every shader from scratch. Use when adding a visual effect (wave, ripple, blur, recolor, shimmer, dissolve transition) to a SwiftUI view. Triggers include "add a shader effect", "metal shader in SwiftUI", "ripple/wave/blur effect", "custom transition", "recolor this view on the GPU".
---

# Metal shaders in SwiftUI — effects without a render pipeline

Since iOS 17 / macOS 14 you can run a **Metal fragment shader over a SwiftUI view** with a single
modifier — no `MTKView`, no command queue, no render pass. You write a small **stitchable** MSL
function, bundle the `.metal` file, and apply it. This is the right tool for *visual polish on
existing views*; for compute or a custom 3D pipeline you still drop to MetalKit (see limits).

**Rule 8 — look before you build:** `twostraws/Inferno` is a MIT-licensed library of ~40 ready
SwiftUI Metal shaders (waves, water, loupe, blur, recolor, shimmer, dissolve/circle/swirl
transitions). **Audited 0/8 (safe):** pure Swift + `.metal`, no scripts, no network, no shell —
`resources: [.process("Shaders")]` in `Package.swift`, loaded via a `@dynamicMemberLookup` enum over
`ShaderLibrary.bundle(.inferno)`. Read it, copy the shader you need (keep the MIT header), or depend
on it. Don't reinvent a Gaussian blur.

## The three modifiers and their MSL contracts

Each modifier calls a stitchable function with a **fixed leading signature**; your extra `Shader`
arguments append after it. Get the signature wrong and it silently no-ops or crashes.

| Modifier | What it does | MSL signature (leading args fixed) |
|---|---|---|
| `.colorEffect(_:)` | recolor each pixel; can't move pixels | `[[stitchable]] half4 fn(float2 position, half4 color, /*args*/)` → new color |
| `.distortionEffect(_:maxSampleOffset:)` | move pixels (warp/ripple) | `[[stitchable]] float2 fn(float2 position, /*args*/)` → new **position** to sample |
| `.layerEffect(_:maxSampleOffset:)` | sample the whole layer per pixel (blur, emboss, pixellate, transitions) | `[[stitchable]] half4 fn(float2 position, SwiftUI::Layer layer, /*args*/)` → color |

`position` is in **user space** (points). `.distortionEffect` and `.layerEffect` need
`maxSampleOffset:` — the largest distance (in points) a pixel may sample from, so SwiftUI sizes the
render bounds; too small clips the effect.

Minimal example (recolor, from Inferno — colorEffect):

```c
#include <metal_stdlib>
using namespace metal;
[[ stitchable ]] half4 recolor(float2 position, half4 color, half4 replacement) {
    return replacement * color.a;      // replace RGB, keep original alpha
}
```

```swift
view.colorEffect(
    ShaderLibrary.recolor(.color(.blue))   // arg order matches the MSL params after `color`
)
```

## Passing arguments from Swift

`ShaderLibrary.<functionName>(args...)` builds a `Shader`. Argument kinds:

| Swift `Shader.Argument` | MSL type it maps to |
|---|---|
| `.float(x)` / `.float2(w,h)` / `.float3` / `.float4` | `float`, `float2`, … |
| `.color(Color)` | `half4` (premultiplied) |
| `.boundingRect` | `float4` (view bounds — for normalizing position) |
| `.image(Image)` | `texture2d` |
| `.data(Data)` | `device const void*` (arbitrary buffer) |

A common pattern is passing `.float2(size)` or `.boundingRect` so the shader can normalize
`position` to 0…1 UV coordinates.

## Animating a shader

Shaders don't animate themselves — feed them **time** as a `.float` and drive a redraw with
`TimelineView`:

```swift
TimelineView(.animation) { context in
    let t = context.date.timeIntervalSince1970
    MyView().colorEffect(ShaderLibrary.wave(.float(t)))
}
```

Do **not** animate by rebuilding SwiftUI state per frame — let the GPU + `TimelineView` do it. This
is exactly what Inferno's `TimeTransformation` previews demonstrate.

## Bundling `.metal` files

- **App target**: drop the `.metal` into the target; Xcode compiles it into the default library and
  `ShaderLibrary.<name>` finds it. Reference an explicit library with `ShaderLibrary.bundle(.main)`.
- **Swift package**: add `resources: [.process("Shaders")]` to the target (as Inferno does) and load
  with `ShaderLibrary.bundle(.module)`. Inferno wraps this in a `@dynamicMemberLookup` enum so calls
  read `InfernoShaderLibrary.wave` — a clean pattern to copy for your own shader package.

## Transitions

Dissolve / circle-reveal / swirl transitions are `.layerEffect` shaders driven by a `progress`
uniform, wired into a custom `Transition`. Inferno's `Shaders/Transition/` (Genie, Diamond, Swirl,
Crosswarp, Wind, Pixellate…) are ready-made references — a progress `float` from 0→1 is animated by
SwiftUI and passed into the shader each frame.

## Verify with RenderPreview

Shaders are visual — verify them, don't guess. Use the `xcode-mcp` skill's `RenderPreview` to
snapshot the effect, and for time-based shaders wrap the preview in `TimelineView` and use the
canvas timeline override to capture frames. A vision model can then grade the frames against the
intended look (the design-contract check).

## Gotchas

| Symptom | Cause / fix |
|---|---|
| Effect does nothing | Wrong stitchable signature for the modifier (see the contract table); or `[[ stitchable ]]` missing |
| Distortion/blur clipped at edges | `maxSampleOffset:` too small — set it to the max pixels the shader samples away |
| Colors look wrong / washed | SwiftUI colors are **premultiplied** `half4`; multiply by `color.a`, don't assume straight alpha |
| `ShaderLibrary.fn` not found | `.metal` not in the target/bundle, or wrong bundle — use `.bundle(.module)` for packages |
| Shader won't compile | Needs iOS 17 / macOS 14 SDK; older deployment targets don't have the SwiftUI shader modifiers |
| Animation janky | Rebuilding views per frame instead of passing a time uniform under `TimelineView` |

## Honest limits

- This is the **SwiftUI shader-modifier** path only — per-pixel fragment effects over existing
  views. It is *not* general Metal: no compute shaders, no custom `MTKView` render loop, no 3D
  geometry. For those, use MetalKit / RealityKit directly (out of scope here).
- MSL is a full language; this skill teaches the SwiftUI *integration contract*, not shader math.
  For the math, read Inferno's annotated shaders and the Metal Shading Language spec.
- Availability and exact modifier signatures are iOS 17/macOS 14+; confirm current API against
  `DocumentationSearch` (the `xcode` bridge) if a signature is rejected.
- Inferno is **referenced, not vendored** here (audit 0/8, MIT). If you copy a shader, keep its MIT
  header; if you depend on the package, that's a normal SwiftPM dependency, not a skill artifact.
