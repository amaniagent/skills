---
name: composable-wiki-rag
description: Build retrieval as many small, independent wikis instead of one monolithic index, then compose a RAG on demand from any subset of them. Covers per-wiki BM25 indexing, Reciprocal Rank Fusion across separate indexes, markdown-aware chunking, optional dense/graph layers, and sensitivity enforcement via the composition manifest. Use when designing a RAG over heterogeneous docs, when a single big index gives mushy results, or when different corpora need different trust levels. Triggers include "design a RAG", "retrieval is returning junk", "combine multiple knowledge bases", "hybrid search over docs", "compose a knowledge base".
---

# Composable Wiki-RAG — many small indexes, fused on demand

One giant index degrades: as a corpus grows and mixes topics, BM25 and vector recall both blur,
and you cannot scope trust per source. The alternative is to make **each coherent corpus its own
small wiki with its own index**, and treat a "RAG" as nothing more than a *list of wikis to
search right now*. Composition becomes a one-line manifest; indexes are never rebuilt together.

## The unit: a wiki

A wiki is a folder of markdown plus a tiny manifest:

```
my-wiki/
  index.md            # human entry point
  *.md                # the knowledge, one topic per file
  .wiki.yaml          # manifest: name, tags, sensitivity
  .index/bm25/        # per-wiki BM25 index, rebuilt on change (seconds)
```

Design rules that make wikis good retrieval units:
- **Small and single-topic.** A wiki should be about one thing. Retrieval quality is highest
  when the index is coherent; split before it sprawls.
- **Fast to create and immediately useful.** A folder of markdown is already a usable wiki (read
  it) and a usable RAG source (index it). No pipeline ceremony to start.
- **The index lives beside the source, never inside it.** Keep source folders read-only from the
  indexer's perspective — write indexes to a separate `.index/` (or a sibling `indexes/<wiki>/`).

## The composition: a RAG is just a YAML list

```yaml
# rag-food.yaml
name: food
wikis: [recipes, nutrition, food-safety]
```

Query time: run BM25 in **each** listed wiki independently, then fuse the ranked hit lists.
Adding or removing a source is editing one line — no re-indexing, no coupling between wikis.

## Fuse with Reciprocal Rank Fusion, not score-merge

**Do not merge raw BM25 scores across separate indexes.** Scores from different indexes are not
comparable — each index has its own IDF statistics, so a "5.0" in a small wiki and a "5.0" in a
large one mean different things. Merging them silently biases results toward whichever index
happens to produce larger numbers.

Use **Reciprocal Rank Fusion (RRF)**, which operates only on *ranks*:

```
score(doc) = Σ over wikis  1 / (k + rank_in_that_wiki)      # k ≈ 60
```

Because RRF only needs each wiki's ordered hit list, the wikis stay completely independent and
composition is trivial. A hit ranked #1 in any wiki contributes strongly regardless of that
wiki's score scale.

## Chunking

Chunk markdown before indexing so a hit points at a passage, not a whole file:
- Strip YAML frontmatter before chunking — it is metadata, not retrievable knowledge.
- Skip meta files (e.g. `_REPORT.md`, `index.md`) that describe the wiki rather than hold its
  knowledge; a leading-underscore convention makes this a one-line filter.
- Use a markdown-aware/recursive chunker (paragraph → sentence fallback) with a modest chunk
  size (~512 tokens). Drop tiny fragments (< ~40 chars) — they add noise, not signal.
- Keep each chunk's source file and offset in the index metadata so a hit is traceable back to
  its exact location.

## Layer up only where a wiki needs it

Start BM25-only — it costs zero tokens, no GPU, and runs anywhere. Add heavier layers *per wiki*,
only where the wiki actually needs them:

1. **BM25 per wiki** — always present. Lexical, cheap, ARM-friendly, instant to rebuild.
2. **Dense layer (optional)** — embeddings in a vector store (e.g. Qdrant) for synonym/semantic
   recall. Add it only to wikis where lexical search misses paraphrases. Free/low-cost embedding
   endpoints keep this affordable; fuse dense hits into the same RRF.
3. **Graph layer (optional)** — a graph-RAG pass (e.g. LightRAG) over the fused top-N when a wiki
   needs multi-hop reasoning, not just passage lookup.

Hybrid = run whichever layers a wiki has, then RRF everything together. The fusion step is the
same regardless of how many layers contributed.

## Sensitivity enforcement comes for free

Because a RAG is an explicit list of wikis and each wiki declares a `sensitivity` in its
manifest, **the composition file is the access-control boundary**. A public-facing RAG manifest
simply cannot list an internal wiki; the storage location and manifest are the enforcement, not a
runtime filter that can be bypassed. Compose a RAG only from wikis at or below the caller's
allowed level.

## Minimal CLI shape

The whole thing is ~100 lines of Python (`bm25s` + a chunker + `pyyaml`):

```
wikirag build <wiki-name> <source-dir-or-glob> [--tag '#wiki/Topic']   # (re)build one wiki's index
wikirag query <rag.yaml> "<question>" [-k 5]                            # BM25 per wiki → RRF → top-k
```

`build` indexes one wiki in seconds; `query` reads the manifest, searches each named wiki, fuses
by RRF, and returns the top-k passages with their source file + offset.

## Why this shape wins

- **Retrieval quality:** small coherent indexes beat one mushy monolith.
- **Composability:** a RAG is a subset of wikis; assembling one is editing a list.
- **Independence:** wikis are never re-indexed together; changing one never touches another.
- **Cost:** BM25 is free; dense/graph are opt-in per wiki.
- **Trust:** sensitivity is a property of the composition, enforced by what you're allowed to list.
