---
name: use-ntfy
description: Send push notifications from an agent to a phone or desktop via ntfy — a single HTTP POST to a topic, self-hosted or via ntfy.sh. Use to notify a human when a long task finishes, when a run needs input or approval, or when something fails and someone should look. Covers publishing with title/priority/tags, self-hosted vs public, and when a push is the right call. Triggers include "notify me when done", "send a push notification", "ping my phone", "alert on completion", "set up ntfy".
---

# Use ntfy — a push to a human in one HTTP POST

Publish = `POST` a body to `<server>/<topic>`; subscribe = open that topic in the ntfy app.
The mechanism is one curl line — the value is in **when** to fire it.

```bash
curl \
  -H "Title: CI pipeline" \
  -H "Priority: high" \
  -H "Tags: white_check_mark,rocket" \
  -H "Click: https://ci.example.com/build/1234" \
  -d "Build #1234 passed — ready to deploy" \
  http://<host>:<port>/<your-topic>      # or ntfy.sh/<your-topic>
```

## Push policy

Push when a **human's attention changes what happens next**:
- A long/unattended job finished — success or failure — and nobody is watching the terminal.
- The run is **blocked on a decision or approval** it won't make itself.
- Something failed in a way that needs a person to look.

Don't push routine progress or per-step chatter — that's log noise on someone's lock screen. One
notification at a meaningful boundary beats ten during the run. Put the outcome *in the message*
(the number, the status, the path), not just "done": it should be readable without opening
anything. Priority runs `min`→`low`→`default`→`high`→`urgent`; reserve `high`/`urgent` for things
a human should act on now, or you train them to ignore it.

## Access

The **topic name is the only auth** on an open server — anyone who knows it can publish and
subscribe. Pick an unguessable name, don't commit it. For anything sensitive, enable ntfy's
users/tokens and publish with `-H "Authorization: Bearer <token>"`. Self-hosted: bind to
`127.0.0.1` and reach it over a private mesh or reverse proxy (see `use-tailscale`), not the
open internet.
