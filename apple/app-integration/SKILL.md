---
name: app-integration
description: Wire an Apple app into the system and into other apps — App Intents (expose your actions to Siri, Shortcuts, Spotlight, widgets, the Action Button, Control Center), and calling foreign apps out (URL schemes, x-callback-url round-trips, universal links, the share sheet, document/Transferable interchange). Covers the AppIntent/@Parameter/perform shape, AppShortcutsProvider phrases, AppEntity/EntityQuery for your data, App Groups for extension data sharing, and canOpenURL/LSApplicationQueriesSchemes. Use when making your app scriptable/automatable, adding a Shortcuts action or Siri phrase, launching or handing data to another app, or sharing data between an app and its extension/widget. Triggers include "add an App Intent", "Siri shortcut", "make this appear in Shortcuts/Spotlight", "open another app from mine", "x-callback-url", "share to other apps".
---

# App integration — expose your app, and use other apps

Two directions, both part of "Swift-native first" (the on-device FoundationModels orchestrator drives
apps through **App Intents**, so making your actions Intents is high leverage):

1. **Expose outward** — App Intents surface your app's actions to Siri, Shortcuts, Spotlight, the
   Action Button, Control Center, interactive widgets, and the assistant.
2. **Reach out** — call and hand data to *other* apps via URL schemes, x-callback-url, universal
   links, the share sheet, and Transferable/document interchange.

## App Intents — the modern, preferred surface

App Intents (iOS 16+) replaced most of SiriKit. One `AppIntent` is a callable, parameterized action:

```swift
import AppIntents

struct AddRecipeIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Recipe"
    static var description = IntentDescription("Adds a recipe to KidsKitchen.")

    @Parameter(title: "Name") var name: String
    @Parameter(title: "Servings") var servings: Int?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // do the work (on your model layer)
        return .result(dialog: "Added \(name).")
    }
}
```

`perform()` returns an `IntentResult`; compose traits: `& ProvidesDialog` (spoken/typed reply),
`& ShowsSnippetView` (a SwiftUI card — verify it with `RenderPreview`), `& ReturnsValue<T>`,
`& OpensIntent`. Use `ForegroundContinuableIntent` when the action needs to bring the app forward
(`throw needsToContinueInForegroundError`).

### Zero-config Siri phrases — AppShortcutsProvider

```swift
struct KidsKitchenShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AddRecipeIntent(),
            phrases: ["Add a recipe in \(.applicationName)"],   // MUST include \(.applicationName)
            shortTitle: "Add Recipe", systemImageName: "plus.circle")
    }
}
```

These App Shortcuts appear automatically in **Shortcuts, Spotlight, and Siri** with no user setup.
Every phrase must contain `\(.applicationName)`.

### Parameters that reference your data — AppEntity + EntityQuery

To let an intent take "which recipe," model the type as an `AppEntity` and provide an `EntityQuery`:

```swift
struct RecipeEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Recipe"
    static var defaultQuery = RecipeQuery()
    var id: UUID
    var displayRepresentation: DisplayRepresentation { .init(title: "\(name)") }
    let name: String
}
struct RecipeQuery: EntityQuery {
    func entities(for ids: [UUID]) async throws -> [RecipeEntity] { /* look up */ }
    func suggestedEntities() async throws -> [RecipeEntity] { /* recents */ }
}
```

`EntityStringQuery` adds free-text matching (great with a FoundationModels/name match). `IndexedEntity`
+ CoreSpotlight puts entities in Spotlight search.

**Shared surfaces:** interactive **widgets** (`Button(intent:)`), **Control Center** controls, and the
**Action Button** all invoke App Intents — build the intent once, reuse it everywhere (see the
`widgets` skill).

## Reaching out to other apps

| Mechanism | Use | Note |
|---|---|---|
| **`openURL` + scheme** | launch another app (`maps://`, `tel:`, `mailto:`, `shortcuts://run-shortcut?...`, custom) | custom schemes you *query* need `LSApplicationQueriesSchemes` in Info.plist for `canOpenURL` to work |
| **x-callback-url** | round-trip with a **result** back to your app | `target://x-callback-url/action?param=…&x-success=myapp://ok&x-error=myapp://err` — only if the target supports it |
| **Universal Links** | open your own web content in-app | associated-domains entitlement; preferred over custom schemes for your domain |
| **Share sheet** | hand data to *any* app | SwiftUI `ShareLink`, or `UIActivityViewController`; make your types `Transferable` |
| **Document / drag-drop** | file interchange | `UIDocumentPicker`, `Transferable`, `.fileImporter`/`.fileExporter` |

x-callback-url is the automation glue between apps (the classic pattern with Shortcuts, Bear,
Drafts, etc.): you pass `x-success`/`x-error`/`x-cancel` URLs and the callee re-opens your app with
the outcome. Handle the return in `onOpenURL` (SwiftUI) / `application(_:open:)`.

```swift
// SwiftUI: receive an incoming URL (your scheme, universal link, or x-callback return)
.onOpenURL { url in router.handle(url) }
```

## Extensions & sharing data

App Extensions (Share, Action, Widget, Shortcuts, Notification) run as **separate processes** and
can't read the host app's sandbox. Share data through an **App Group** container
(`FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` or a shared
`UserDefaults(suiteName:)`) — the same mechanism widgets need. Add the App Groups capability to both
the app and the extension.

## Verify

- **Shortcuts app**: your App Shortcuts should appear automatically; add the intent to a shortcut and
  run it.
- **Spotlight / Siri**: search the app name + action; speak a registered phrase.
- **Snippet views**: render the intent's `ShowsSnippetView` SwiftUI with `RenderPreview` (xcode-mcp).
- **Outbound**: test each `openURL`/x-callback path on a device where the target app is installed;
  `canOpenURL` silently returns false without the `LSApplicationQueriesSchemes` entries.

## Gotchas

| Symptom | Cause / fix |
|---|---|
| App Shortcut never appears | Phrase missing `\(.applicationName)`, or no `AppShortcutsProvider` in the app target |
| `canOpenURL` always false | Custom scheme not declared in `LSApplicationQueriesSchemes` |
| Intent parameter can't pick your data | The type isn't an `AppEntity`, or its `EntityQuery` returns nothing |
| Extension can't see app data | No shared **App Group**; extensions are separate sandboxes |
| x-callback returns nothing | Target app doesn't implement x-callback-url, or your `x-success` scheme is wrong/unregistered |
| Snippet view blank | Intent result missing `& ShowsSnippetView` or the view isn't returned |

## Honest limits

- **App Intents evolves every release** (foreground continuation, `@Dependency`, transferable
  results, assistant schemas). Confirm the current protocol surface with the `xcode` bridge
  `DocumentationSearch` (framework: AppIntents) before relying on a newer trait.
- Legacy **SiriKit** intents still exist for a few system domains (messaging, payments, media) that
  App Intents doesn't fully cover — check the domain before assuming App Intents suffices.
- **x-callback-url depends entirely on the target app**; there's no guarantee an arbitrary app
  supports it. It's a convention, not a system API.
- Deep Spotlight/CoreSpotlight indexing and the assistant schema system are summarized, not
  exhaustive.
