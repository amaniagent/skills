---
name: use-ntfy
description: Send push notifications from an agent to a phone or desktop via ntfy — a single HTTP POST to a topic, self-hosted or via ntfy.sh. Use to notify a human when a long task finishes, when a run needs input or approval, or when something fails and someone should look. Covers publishing with title/priority/tags, self-hosted vs public, and when a push is the right call. Triggers include "notify me when done", "send a push notification", "ping my phone", "alert on completion", "set up ntfy".
---

# Use ntfy — a push to a human in one HTTP POST

ntfy turns "tell a human something happened" into a plain HTTP POST to a **topic**. A phone or
desktop subscribed to that topic gets a push. No app to build, no account required, no callback
infra. For an agent doing long or unattended work, it closes the loop back to a person.

## The whole model

- **Topic = channel.** Anyone who knows the topic name can publish to it and subscribe. The topic
  name is the only "auth" on a public server, so **treat it like a secret** — pick an unguessable
  name, don't commit it.
- **Publish** = `POST` a message body to `<server>/<topic>`.
- **Subscribe** = open the topic in the ntfy app (phone/desktop) or the web UI. Self-hosted: add
  your server URL in the app, then the topic.

## Publish

Public server:

```bash
curl -d "Backup finished: 4.2 GB in 3m12s" ntfy.sh/<your-topic>
```

Self-hosted server (bound to localhost, reached over a mesh or reverse proxy — see `use-tailscale`):

```bash
curl -d "Deploy succeeded on prod" http://<host>:<port>/<your-topic>
```

Enrich with headers — title, priority, tags (emoji shortcodes), and a click-through URL:

```bash
curl \
  -H "Title: CI pipeline" \
  -H "Priority: high" \
  -H "Tags: white_check_mark,rocket" \
  -H "Click: https://ci.example.com/build/1234" \
  -d "Build #1234 passed — ready to deploy" \
  http://<host>:<port>/<your-topic>
```

Priority runs `min`→`low`→`default`→`high`→`urgent`; reserve `high`/`urgent` for things a human
should act on now, or you train them to ignore it.

## When an agent should push (and when not)

Push when a **human's attention changes what happens next**:
- A long/unattended job finished — success or failure — and nobody is watching the terminal.
- The run is **blocked on a decision or approval** it won't make itself.
- Something failed in a way that needs a person to look.

Don't push for routine progress or per-step chatter — that's log noise on someone's lock screen.
One notification at a meaningful boundary beats ten during the run. Put the outcome in the message
itself (the number, the status, the path), not just "done" — the notification should be readable
without opening anything.

## Self-hosted notes

- Bind the server to `127.0.0.1` and reach it over a private mesh or reverse proxy rather than
  exposing it publicly.
- The topic name is the access boundary on an open instance; for anything sensitive, enable
  ntfy's auth (users/tokens) and publish with `-H "Authorization: Bearer <token>"`.
- Good default use: notify a phone at the end of every unattended agent batch, so a person learns
  the tally without babysitting the console.
