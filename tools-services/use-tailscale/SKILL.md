---
name: use-tailscale
description: Reach and expose self-hosted, localhost-bound services over a Tailscale tailnet from an agent — without SSH tunnels, public ports, or a reverse proxy. Covers the operator flag that lets a non-root user drive tailscale, serve vs funnel, picking a free port, and the reverse-proxy collision that fails silently. Use when a service is bound to 127.0.0.1 and needs to be reachable from another machine, or when replacing SSH port-forwards with the tailnet. Triggers include "expose a local service", "access localhost from another machine", "set up tailscale serve", "replace SSH tunnel", "reach my server's UI remotely".
---

# Use Tailscale — private mesh access to localhost services

Tailscale gives every machine a stable MagicDNS name on a private WireGuard mesh (the *tailnet*).
An agent can use it to reach a service bound to `127.0.0.1` on another host, and to publish such a
service to the tailnet over HTTPS — no inbound firewall port, no public exposure, no SSH tunnel.

## One-time setup (needs root — hand root commands to a human if you can't sudo)

```bash
sudo tailscale up --operator=<user> --ssh
```

Two flags carry most of the value:
- **`--operator=<user>`** — lets that non-root user run `tailscale status/serve/ip/...` **without
  sudo** afterwards. Set it once; it persists. This is what makes an unprivileged agent able to
  drive Tailscale day-to-day.
- **`--ssh`** — enables Tailscale SSH: `ssh <user>@<host>` from any tailnet device with auth over
  the tailnet, no key management.

`tailscale up` prints a **login URL** — open it in a browser to authenticate (GitHub login works).
Everything is outbound, so a restrictive inbound firewall doesn't matter.

## Daily use (no sudo, thanks to the operator flag)

```bash
tailscale status                 # who's on the tailnet, which IPs
tailscale ip -4                  # this host's tailnet IP (100.x.y.z)
tailscale serve status           # what's currently published
tailscale serve reset            # take everything back down
```

## Publish a localhost service to the tailnet

`tailscale serve` puts a TLS front on a local port, reachable only inside the tailnet:

```bash
tailscale serve --bg --https=<PORT> localhost:<local-port>
# → https://<host>.<your-tailnet>.ts.net:<PORT>/
```

Result: an HTTPS URL for a service that was only listening on `127.0.0.1`, with a real cert, no
extra reverse proxy, and no public exposure.

## The silent-failure trap: don't reuse a bound port

**If another process already binds the port you hand to `tailscale serve` (classically `:443`,
held by a reverse proxy like Caddy/nginx), `serve` fails *silently*.** The config looks correct,
`serve status` looks plausible, but the TLS handshake just fails. This wastes an hour if you don't
know it.

- **Always publish on a free port.** Check first: `ss -tln | grep :<PORT>` (or `sudo lsof -i:<PORT>`).
  Pick something unused (e.g. 8443, 9443) for each service.
- Reserve `:443` for whatever reverse proxy already owns it; never point `serve --https=443` at a
  host where another service holds 443.

## serve vs funnel — know which one exposes the internet

- **`tailscale serve`** — tailnet-only. Private. This is the default choice for internal tools.
- **`tailscale funnel`** — publishes to the **public internet**, not just the tailnet. Treat it as
  an outward-facing action: only use it deliberately and with explicit human sign-off, never as a
  reflex for "make it reachable".

## Troubleshooting

```bash
systemctl status tailscaled              # daemon health
journalctl -u tailscaled -n 50 --no-pager
sudo tailscale up <ALL desired flags>    # to change options, re-run `up` with the FULL flag set
```

`tailscale up` is declarative: to change one option you must re-specify **all** the flags you want,
not just the new one — omitted flags revert to defaults.
