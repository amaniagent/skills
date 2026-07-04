---
name: xcode-mcp
description: Drive Xcode from an AI agent through the two MCP surfaces that actually ship and work — Apple's official Xcode bridge (xcrun mcpbridge → a running Xcode.app) and the standalone XcodeBuildMCP (simulator-first, session defaults/profiles). Covers when to pick which, the mandatory session_show_defaults handshake, the build/run/test/preview loop, RenderPreview as a design-contract check, and the fact that Xcode 27 ships its own agent skills. Use when an agent must build, run, test, preview, or debug an Apple app (iOS/macOS/watchOS/visionOS) without a human clicking Xcode's buttons. Triggers include "build the app", "run it on the simulator", "render the SwiftUI preview", "run the tests", "why won't this project build".
---

# Xcode from an agent — two MCP surfaces, one workflow

There are **two working ways** to let an agent operate Xcode, and they are not redundant — they
cover different jobs. Know both, pick per task, and never assume defaults are configured.

| Surface | What it is | Reach for it when |
|---|---|---|
| **`mcp__xcode__*`** (Apple's official bridge) | `xcrun mcpbridge` — a STDIO bridge to a **running Xcode.app**. Drives the real IDE: its indexer, canvas previews, documentation search, device/organizer/crash data, string catalogs. | You want *Xcode's own* machinery: SwiftUI `#Preview` snapshots, semantic doc search, physical-device runs, crash logs from the Organizer, String Catalog edits. Xcode must be open with the project. |
| **`mcp__XcodeBuildMCP__*`** (standalone, community) | A self-contained MCP wrapping `xcodebuild` + `simctl` + SwiftPM. Simulator-first. No Xcode window needed. | Headless/CI-shaped automation: build/run/test on a simulator, scriptable **session defaults + named profiles**, SwiftPM packages, UI automation on the sim. |

In our setup **both are live**. The rule of thumb: **XcodeBuildMCP for the headless build/run/test
loop, the xcode bridge for anything that needs the real Xcode** (previews, doc search, devices,
crash triage, catalogs).

## Prerequisite: the right toolchain

macOS-27 / SDK-27 targets need **Xcode 27**, not the Command Line Tools (CLT breaks SwiftData
macros and `@State`-as-macro). For CLI/XcodeBuildMCP work:

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app   # or wherever Xcode 27 lives
xcodebuild -version                                  # confirm: Xcode 27.x
```

For the `xcode` bridge, just run the desired Xcode — the bridge talks to whatever Xcode.app is open.

---

## XcodeBuildMCP: session defaults first, then one-shot run

**Mandatory handshake.** Before your first build/run/test call in a session you MUST call
`session_show_defaults`. Do not assume a project/scheme/simulator is set — a fresh session shows
everything `null` under the `(default)` profile.

```
session_show_defaults          → {profiles:{"(default)":{projectPath:null, scheme:null, ...}}}
```

If defaults are missing, discover and set them once, then everything else can be argument-free:

```
discover_projs   { workspaceRoot: "/path/to/repo" }   → finds .xcodeproj / .xcworkspace
list_schemes     { ... }                               → pick a scheme
list_sims        {}                                    → pick a simulator (name or UDID)
session_set_defaults {
  projectPath: "…/macAgentOS.xcodeproj",   # xor workspacePath — never both
  scheme: "macAgentOS",
  simulatorName: "iPhone 16 Pro",
  configuration: "Debug",
  persist: true            # writes .xcodebuildmcp/config.yaml so it survives restarts
}
```

Named **profiles** let you keep several targets side by side (`profile: "watch"`,
`createIfNotExists: true`) and switch with `session_use_defaults_profile`.

Once defaults are set, the run loop is trivial — usually **empty arguments**:

```
build_run_sim   {}          # build → install → boot sim → launch; captures a runtime log file
test_sim        {}          # run the scheme's tests on the sim (progress:true by default)
screenshot      {}          # capture the sim screen
snapshot_ui     {}          # runtime UI hierarchy (element refs for taps/swipes)
stop_app_sim    {}          # stop the running app
```

Only **simulator** workflows are enabled by default. Device runs, macOS builds, LLDB debugging,
and UI automation must be turned on in the XcodeBuildMCP config — if those tools are absent, that's
why (see xcodebuildmcp.com/docs/configuration), not a bug.

---

## The xcode bridge: everything is keyed by `tabIdentifier`

Apple's `mcp__xcode__*` tools act on an **open workspace window/tab**, so almost every call takes a
`tabIdentifier`. List windows first (`XcodeListWindows`) to get it, then:

```
BuildProject   { tabIdentifier, buildForTesting?: true }     # build, wait for completion
RunProject     { tabIdentifier, attachDebugger?: true }      # Cmd+R equivalent; returns once launched
GetConsoleOutput { tabIdentifier }                           # read the app's console
StopProject    { tabIdentifier }                             # stop it
RunAllTests    { tabIdentifier }        RunSomeTests / GetTestList
```

Scheme & destination management: `XcodeListSchemes` / `XcodeSwitchScheme`,
`XcodeListRunDestinations` / `XcodeSwitchRunDestination`. File I/O through the IDE's view of the
project: `XcodeRead / XcodeWrite / XcodeGlob / XcodeGrep / XcodeLS / XcodeMV / XcodeRM`.

Things **only** the bridge gives you:

- **`DocumentationSearch { query, frameworks? }`** — semantic search over Apple Developer docs from
  inside Xcode. First stop for API questions before WebFetch.
- **Crash triage**: `GetTopCrashIssues`, `GetCrashIssueLogs`, `GetTopFieldPerformanceIssues` — the
  Organizer's data, agent-readable.
- **String Catalogs**: `StringCatalogRead / Edit / Context`, `LocalizationPlanner` — localization work.
- **Physical device**: `DeviceInteractionStartSession → InstallAndRun → Synthesize → EndSession`.
- **`InvokeDebuggerCommand`** — raw LLDB against the running process.

### RenderPreview — the design-contract check

`RenderPreview` builds a SwiftUI `#Preview` (or `PreviewProvider`) and **returns a snapshot image**,
without launching the whole app. This is the single most useful bridge tool for agent-driven UI work
and for a vision model verifying that the built UI matches the design:

```
RenderPreview {
  tabIdentifier,
  sourceFilePath: "macAgentOS/ContentView.swift",   # path as Xcode organizes it
  previewDefinitionIndexInFile: 0,                   # 0 = first #Preview in the file
  # optional canvas controls, discovered from a prior call's supportedCanvasControlOverrides:
  previewLocalizationOverride: "de",                 # preview in a locale
  previewCanvasControlOverrides: { timelineIndex: 2, toggleState: true }  # Widget/Live Activity timeline
}
```

`timelineIndex` + `toggleState` matter for **Widgets and Live Activities** — you can render each
timeline entry and both states of the toggle, exactly the frames a widget skill needs to verify.

---

## `xcrun mcpbridge` — the bits people miss

The bridge binary does more than pipe JSON-RPC:

```bash
xcrun mcpbridge                          # STDIO bridge (what the MCP client connects to)
xcrun mcpbridge run-agent claude         # launch an agent WITH Xcode-provided config:
                                         #   binary path, auth tokens, env, and the Xcode MCP tools
xcrun mcpbridge run-agent claude --dry-run          # print the resolved command, run nothing
xcrun mcpbridge run-agent claude --no-xcode-tools   # launch without injecting Xcode's MCP tools
```

`run-agent` is how Xcode 27 wires a coding agent to itself — you don't hand-configure the MCP
endpoint, Xcode hands the agent its own tool service.

### Xcode 27 ships its own agent skills

```bash
xcrun mcpbridge run-agent skills export --output-dir ./xcode-skills --replace-existing
```

exports the SKILL.md bundles Xcode makes globally available. As of Xcode 27 that's **7 skills**:
`swiftui-specialist`, `swiftui-whats-new-27`, `device-interaction`, `test-modernizer`,
`uikit-app-modernization`, `c-bounds-safety`, `audit-xcode-security-settings`.

**Consequence (Rule 8 — look before you build):** do **not** write your own generic
"SwiftUI best practices" or "migrate XCTest to Swift Testing" skill — Apple already ships those and
they're versioned to the SDK. Export them, reference them, and let your own skills cover what Apple's
don't (project planning, WidgetKit end-to-end, domain frameworks like HealthKit, the MCP plumbing
in *this* file).

---

## Picking a surface — decision table

| Task | Surface |
|---|---|
| Build + run on a simulator, no Xcode window | XcodeBuildMCP `build_run_sim` |
| Run the test suite headless / in a loop | XcodeBuildMCP `test_sim` |
| Snapshot a SwiftUI preview for a design check | xcode bridge `RenderPreview` |
| Render each Widget/Live Activity timeline frame | xcode bridge `RenderPreview` + `timelineIndex` |
| Look up an Apple API | xcode bridge `DocumentationSearch` |
| Run on a physical iPhone | xcode bridge `DeviceInteraction*` |
| Triage a shipped crash | xcode bridge `GetTopCrashIssues` |
| Edit a String Catalog | xcode bridge `StringCatalog*` |
| SwiftPM package build/test | XcodeBuildMCP (SwiftPM tools) |
| Keep 3 targets' defaults side by side | XcodeBuildMCP named profiles |

## Gotchas

| Symptom | Cause / fix |
|---|---|
| XcodeBuildMCP build/run "no project" | You skipped `session_show_defaults`; set defaults or pass paths. |
| `session_set_defaults` rejected | You gave both `projectPath` and `workspacePath` — they're mutually exclusive. |
| Device / macOS / debug tools missing | Not enabled in XcodeBuildMCP config; only sim workflows ship on by default. |
| SwiftData macro / `@State` errors on build | Wrong toolchain — point `DEVELOPER_DIR` at Xcode 27, not CLT. |
| xcode bridge tool "no such tab" | Wrong/stale `tabIdentifier`; re-list with `XcodeListWindows`. |
| `RenderPreview` empty / wrong preview | `previewDefinitionIndexInFile` counts `#Preview` blocks from the top of the file, 0-based. |
| Canvas override ignored | That preview doesn't support it — check `supportedCanvasControlOverrides` from a prior call. |

## Honest limits

- **Not covered here:** the XcodeBuildMCP configuration file format for enabling device/macOS/debug
  workflows (see their docs) and the exact set of bridge tools, which grows per Xcode release —
  treat the tables above as "as of Xcode 27," and list the live tool set in your session.
- The `xcode` bridge needs a **running Xcode.app with the project open**; it is not headless. If you
  need fully headless CI, stay on XcodeBuildMCP.
- This skill documents *our working practice*, not a spec. When a tool's parameters differ from what's
  written here, the live tool schema wins.
