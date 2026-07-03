---
name: use-n8n
description: Operate a self-hosted n8n workflow-automation instance from an agent — running the Docker stack, reaching a localhost-bound UI, and avoiding the two failure modes that actually bite (a lost encryption key that bricks all stored credentials, and root-owned bind-mounts that crash the container). Use when running, debugging, backing up, or updating n8n, or when a workflow/webhook automation needs a home. Triggers include "run n8n", "n8n won't start", "set up a workflow automation", "n8n permission denied", "back up n8n".
---

# Use n8n — self-hosted workflow automation, operated safely

n8n is a self-hosted Zapier/Make alternative: visual workflows, webhooks, and integrations. For
anything beyond a toy it runs in **queue mode** — a main container (UI + webhook receiver), one or
more workers, a Postgres DB, and a Redis queue. Bind everything to `127.0.0.1`; it is not meant to
face the public internet directly.

## Reaching a localhost-bound UI

If the UI is on `127.0.0.1:5678`, forward it rather than exposing it:

```bash
ssh -L 5678:127.0.0.1:5678 <user>@<host>     # then open http://localhost:5678 (basic-auth on)
```

Or publish it to a private mesh (see `use-tailscale`) on a free port — never bind n8n to `0.0.0.0`.

## Operating the stack

```bash
cd <n8n-stack-dir>
docker compose up -d                        # start
docker compose ps                           # status
docker compose logs -f n8n                  # main logs
docker compose restart n8n n8n-worker       # restart app + worker
docker compose down                         # stop (data persists in volumes/bind-mounts)
docker compose pull && docker compose up -d # update
```

Health check: `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5678/healthz` → `200`.

## The two failure modes that actually bite

### 1. Never lose or change `N8N_ENCRYPTION_KEY`

n8n encrypts all stored credentials with the `N8N_ENCRYPTION_KEY` from its env. **If that key
changes or is lost, every saved credential becomes undecryptable — permanently.** Treat it as the
single most important secret in the stack: back it up, never regenerate it on a running instance,
never let a "fresh `.env`" step overwrite it.

### 2. Root-owned bind-mounts crash the container

n8n runs as user `node` (uid 1000), but Docker creates bind-mount directories as **root**, so the
process can't write and crashes with `EACCES: permission denied, open '/home/node/.n8n/config'`.
Fix the ownership without host sudo (works if your user is in the `docker` group) by chowning
through a throwaway container:

```bash
cd <n8n-stack-dir>
docker run --rm -v "$PWD/n8n-data:/d1" -v "$PWD/local-files:/d2" \
  alpine sh -c 'chown -R 1000:1000 /d1 /d2'
docker compose up -d
```

## Backup

```bash
tar -czf n8n-backup-$(date +%Y%m%d).tar.gz -C <n8n-stack-dir> n8n-data/   # data dir
docker exec n8n-postgres pg_dump -U n8n n8n > n8n-db-$(date +%Y%m%d).sql   # database
```

Always back up the DB **and** the encryption key together — the DB is useless without the key.

## Harmless log noise (don't chase these)

- *"Python task runner … Python 3 is missing"* — only affects Python code-nodes in internal mode;
  the JS runner still works. Deploy an external runner only if you need Python nodes in production.
- *Deprecation `OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS`* — in queue mode, set it to `true` in `.env`.
