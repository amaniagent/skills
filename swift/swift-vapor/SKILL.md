---
name: swift-vapor
description: Build a server-side Swift backend with Vapor 4 — async route handlers, RouteCollection controllers, Fluent models/migrations, Content decoding and Validatable validation, middleware and auth, and the modern async app lifecycle (Application.make → configure → execute → asyncShutdown). Covers both a Linux-deployed API and the "embedded local server launched from a macOS app bundle, bound to 127.0.0.1" pattern. Use when writing an API in Swift, adding an endpoint, wiring a database with Fluent, or standing up a local HTTP/WebSocket server for a native app. Triggers include "build an API in Swift", "add a Vapor route", "Fluent model and migration", "server-side Swift", "local server for my Mac app", "validate this request body".
---

# Vapor — the server in the same language as the app

Vapor is the mature server-side Swift framework (async/await, runs on macOS and Linux). For a
"Swift-native first" stack it's the natural backend: **one language client-to-server**, and a shared
model package (`Content` types) used by both the app and the API. This skill is the orientation +
current-idiom reference; the full "Server-Side Swift with Vapor" book is a separate deep resource.

**Reference (our practice):** `MnemoServer` is a Vapor 4 scaffold that ships **inside a macOS app
bundle** and is launched as its own process, speaking REST + WebSocket on localhost. It binds
**only 127.0.0.1** — the right default for an embedded local server (never expose an app-local
backend on `0.0.0.0`).

## Project shape

```
Sources/
  entrypoint.swift        // @main async lifecycle
  configure.swift         // server config, middleware, DB, migrations, routes()
  Routes/routes.swift      // routes, or controllers conforming to RouteCollection
  Models/ Migrations/       // Fluent
```

### The async lifecycle (Vapor 4, current)

```swift
import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = try await Application.make(env)     // NOT the old `Application(env)`
        do {
            try configure(app)
            try await app.execute()                   // runs until shutdown
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}
```

### configure.swift

```swift
public func configure(_ app: Application) throws {
    app.http.server.configuration.hostname = "127.0.0.1"   // localhost-only for embedded servers
    app.http.server.configuration.port =
        Environment.get("PORT").flatMap(Int.init) ?? 8080

    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    // app.migrations.add(CreateThing())
    try routes(app)
}
```

## Routing

Handlers are `async`/`async throws`; return any `Content` (auto-JSON) or `HTTPStatus`.

```swift
func routes(_ app: Application) throws {
    app.get("health") { _ async in HealthStatus(status: "ok", version: "0.1.0") }

    app.post("users") { req async throws -> UserResponse in
        let input = try req.content.decode(CreateUser.self)
        return UserResponse(id: 1, name: input.name)
    }

    app.get("users", ":userID") { req async throws -> String in
        let id = try req.parameters.require("userID", as: Int.self)
        return "User #\(id)"
    }
}

struct HealthStatus: Content { let status: String; let version: String }
```

### Organize with `RouteCollection` controllers

```swift
struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: index)
        users.post(use: create)
        users.group(":userID") { u in
            u.get(use: show); u.put(use: update); u.delete(use: delete)
        }
    }
    func index(req: Request) async throws -> [User] { try await User.query(on: req.db).all() }
    // ...
}
// configure.swift:  try app.register(collection: UserController())
```

## Validation before decode

Conform to `Validatable`; `validate(content:)` throws **422** with a readable reason before you
touch the payload.

```swift
struct CreateUser: Content, Validatable {
    var name: String; var email: String; var age: Int
    static func validations(_ v: inout Validations) {
        v.add("name", as: String.self, is: .count(2...64))
        v.add("email", as: String.self, is: .email)
        v.add("age", as: Int.self, is: .range(18...120))
    }
}
app.post("users") { req async throws -> HTTPStatus in
    try CreateUser.validate(content: req)
    let input = try req.content.decode(CreateUser.self)
    return .created
}
```

## Fluent (the ORM)

A model is a `final class` with property-wrapper columns; a migration creates its table; you add
migrations in `configure` and run `app.autoMigrate()` (or `vapor run migrate`).

```swift
final class Acronym: Model, Content, @unchecked Sendable {
    static let schema = "acronyms"
    @ID(key: .id) var id: UUID?
    @Field(key: "short") var short: String
    @Parent(key: "user_id") var user: User          // relationships: @Parent/@Children/@Siblings
    init() {} ; init(short: String, userID: User.IDValue) { self.short = short; self.$user.id = userID }
}

struct CreateAcronym: AsyncMigration {
    func prepare(on db: Database) async throws {
        try await db.schema("acronyms")
            .id().field("short", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .create()
    }
    func revert(on db: Database) async throws { try await db.schema("acronyms").delete() }
}
// configure:  app.migrations.add(CreateAcronym())
// query:      try await Acronym.query(on: req.db).filter(\.$short == "OMG").all()
```

Fluent drivers: `fluent-sqlite-driver` (local/dev), `fluent-postgres-driver`, `fluent-mysql-driver`.

## Middleware & auth

- Built-in: `ErrorMiddleware` (JSON errors), `FileMiddleware` (static files), CORS middleware.
- Auth: `Authenticatable` + a `ModelTokenAuthenticator` / `ModelAuthenticatable`; BCrypt for
  password hashing; a `Token` Fluent model with a `@Parent` to the user is the standard bearer-token
  shape.
- Sessions, caching, an HTTP client (`req.client`), and **WebSocket** (`app.webSocket("ws") { req, ws in … }`)
  are first-class — MnemoServer uses REST + WS together on localhost.

## Two deployment shapes

| Shape | How | Notes |
|---|---|---|
| **Linux API** | `swift build -c release`, run in a Docker image (`swift:*-slim`) behind a reverse proxy | standard cloud backend; bind `0.0.0.0`, terminate TLS at the proxy |
| **Embedded local server** | ship the built binary in a macOS `.app`; the app launches it and polls `/health` | bind **127.0.0.1 only**; this is the MnemoServer / "Swift-native first" pattern |

## Verify

```bash
swift build          # or: swift test
swift run             # start it
curl localhost:8080/health      # expect 200 + your HealthStatus JSON
```

For the embedded pattern, the app's launcher should **wait for `/health` 200** before using the
server (MnemoServer's `LaunchManager` does exactly this).

## Gotchas

| Symptom | Cause / fix |
|---|---|
| `Application(env)` won't compile in async main | Use `try await Application.make(env)` + `asyncShutdown()` (current lifecycle) |
| Route returns but body is empty | Return type must be `Content` (or `HTTPStatus`); a plain struct needs `: Content` |
| 422 on POST | Your `Validatable` rules rejected it — the JSON `reason` says which field |
| Migration didn't run | Not added in `configure`, or you didn't `autoMigrate()` / `migrate` |
| Embedded server reachable from LAN | You bound `0.0.0.0` — for an app-local backend set hostname to `127.0.0.1` |
| `Sendable` warnings on models | Fluent models are reference types; the common idiom is `final class … @unchecked Sendable` |

## Honest limits

- This is orientation to **Vapor 4 current idioms**, not the full framework — deep Fluent
  (eager loading, pivots, complex queries), advanced auth flows, queues/jobs, and production
  deployment each warrant their own reference (the Vapor book / docs).
- Fluent's exact schema-builder and relationship APIs shift across minor versions; confirm against
  the current Vapor docs (context7 `/vapor/vapor`) if a call is rejected.
- Server-side Swift on Linux needs the Swift Linux toolchain in your Docker image; this skill
  doesn't cover cross-compilation or static-linking tuning.
