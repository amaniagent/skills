---
name: use-crawl4ai
description: Crawl and scrape the web into LLM-ready markdown or structured JSON from an agent, using crawl4ai — either the self-hosted REST service or the native crwl CLI. Covers plain crawls, BFS deep crawls, CSS extraction (no LLM, free) vs LLM extraction, JWT auth, and the container gotchas (shm size, timeouts). Use when an agent needs page content as clean markdown, when scraping structured fields from a site, or when feeding a crawl into a RAG pipeline. Triggers include "crawl this site", "scrape into markdown", "extract data from a webpage", "deep crawl the docs", "get page content for RAG".
---

# Use crawl4ai — the web as clean markdown or structured JSON

crawl4ai turns web pages into **LLM-ready markdown** or **structured data**, self-hosted so no
per-page SaaS cost. Two surfaces: the native `crwl` CLI (quick, local) and a REST service (shared,
authenticated, good for agents and pipelines). Prefer CSS extraction over LLM extraction whenever
the data is in the DOM — it's free and deterministic.

## Native CLI (`crwl`)

```bash
crwl https://example.com -o markdown                         # page → markdown (default for RAG)
crwl https://example.com -o json                             # structured JSON
crwl https://docs.example.com --deep-crawl bfs --max-pages 10 # follow links, breadth-first, capped
crwl https://example.com/products -q "Extract all prices"    # LLM extraction by question
crwl https://example.com --screenshot                        # render + capture
```

## REST service

```bash
curl http://localhost:11235/health                           # is it up?

curl -X POST http://localhost:11235/crawl \
  -H "Content-Type: application/json" \
  -d '{"urls": ["https://example.com"], "crawler_config": {"markdown": true}}'
```

With auth, add a bearer token:

```bash
curl -X POST http://localhost:11235/crawl \
  -H "Authorization: Bearer <JWT_TOKEN>" -H "Content-Type: application/json" \
  -d '{"urls": ["https://example.com"], "crawler_config": {"markdown": true}}'
```

Deep crawl via the API: put `deep_crawl_strategy: "bfs"` and `max_pages: <N>` in `crawler_config`.

## Extraction: CSS first, LLM only when needed

**CSS extraction (no LLM — free, fast, deterministic).** Use when the data lives in predictable
DOM nodes. You give a base selector and fields:

```json
{"urls": ["https://example.com"],
 "extraction_config": {"type": "css", "schema": {
   "name": "Articles", "baseSelector": "article",
   "fields": [{"name": "title", "selector": "h2", "type": "text"},
              {"name": "link", "selector": "a", "type": "attribute", "attribute": "href"}]}}}
```

**LLM extraction.** Reach for it only when the target is unstructured or the layout varies. You
supply a provider + a JSON schema of the fields to pull. It costs tokens per page — don't use it
where a CSS selector would do.

## Feeding a RAG pipeline

Markdown output is the natural input to chunking + indexing: crawl → markdown → chunk → index. For
a docs site, a capped BFS deep crawl (`--max-pages`) gives you a coherent corpus you can turn into
one small wiki (see `composable-wiki-rag`). Always cap `max-pages` — an uncapped deep crawl can
walk the whole internet.

## Container gotchas

| Symptom | Fix |
|---|---|
| `Connection refused` | Service down — `docker compose ps` |
| `401 Unauthorized` | Missing/expired JWT or API key in the header |
| `500 Browser error` | Give the container more shared memory: `shm_size: 1g` in compose; check host RAM |
| Timeouts | Raise the client `timeout`; limit concurrency; cap `max_pages` |
| `Playwright missing` (CLI) | Run `crawl4ai-setup` after `pip install -U crawl4ai` |

## Safety

Respect the target: cap pages, throttle concurrency, and honor robots/ToS. Uncapped deep crawls
and aggressive concurrency both hammer the target and can exhaust the crawler's own RAM.
