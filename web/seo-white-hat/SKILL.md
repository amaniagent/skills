---
name: seo-white-hat
description: Improve a site's organic search performance the durable, guideline-compliant way — technical SEO (Core Web Vitals with the current INP metric, crawlability, sitemaps/robots, structured data), content built for user intent and E-E-A-T, and legitimate off-page signals. Explicitly white-hat: no cloaking, link buying, or algorithm gaming. Honest that exact ranking effects are opaque and thresholds shift, so it points at the authoritative live sources (Search Console, PageSpeed Insights, Google Search Central) rather than promising rankings. Use when auditing or improving a website's SEO, diagnosing why pages don't rank, adding structured data, or planning content/link strategy. Triggers include "improve SEO", "Core Web Vitals", "why isn't my site ranking", "structured data / schema markup", "sitemap robots.txt", "E-E-A-T", "backlink strategy".
---

# White-hat SEO — durable, guideline-compliant search performance

White-hat SEO earns rankings by making a site genuinely better for users and easier for search
engines to understand — it follows the search engines' own guidelines and compounds over time,
rather than exploiting loopholes that get penalized in the next update.

> ⚠️ **Rankings are never guaranteed and the algorithm is opaque.** No one outside Google knows the
> exact weightings, and thresholds/metrics change. This skill gives the durable fundamentals and
> points at the **authoritative live sources** — treat those, not this text, as the current truth:
> Google Search Central docs, Search Console, and PageSpeed Insights / CrUX.

## Technical SEO

**Core Web Vitals** — real-user experience metrics; "good" targets (verify current values in
PageSpeed Insights, they do shift):

| Metric | Measures | "Good" (approx) |
|---|---|---|
| **LCP** (Largest Contentful Paint) | loading — main content visible | ≤ 2.5s |
| **INP** (Interaction to Next Paint) | responsiveness | ≤ 200ms |
| **CLS** (Cumulative Layout Shift) | visual stability | ≤ 0.1 |

> **INP replaced FID** as a Core Web Vital in **March 2024** — if a guide still cites First Input
> Delay, it's out of date. INP measures responsiveness across *all* interactions, not just the first.

**Crawlability & indexing basics:**

- **`sitemap.xml`** — list your important, canonical URLs; keep it current; reference it in
  `robots.txt` and submit it in Search Console.
- **`robots.txt`** — controls *crawling*, not indexing. Don't use it to hide pages from results (use
  `noindex` for that); a disallowed page can still be indexed via external links.
- **Canonical tags** — one canonical URL per piece of content to avoid duplicate dilution.
- **Structured data (Schema.org)** — JSON-LD markup (Article, Product, FAQPage, HowTo, Event, …)
  helps engines understand content and can enable rich results. It aids *understanding/eligibility*;
  it is **not** a direct ranking boost. Validate with the Rich Results Test.
- **Mobile-first, HTTPS, clean URLs, fast server response** — table stakes.

## Content & E-E-A-T

- **E-E-A-T** — Experience, Expertise, Authoritativeness, Trustworthiness. It's a quality *framework*
  raters use, especially for **YMYL** (Your Money or Your Life) topics — not a single score. Show
  real authorship, credentials, sources, and up-to-date accuracy.
- Write for **user intent**, not keyword density — answer the question the searcher actually has,
  comprehensively. Match the intent type (informational / navigational / transactional).
- **Original, useful, current** content wins; thin or duplicated pages lose. Update, don't just add.
- **Internal linking** builds topical authority and site structure — link related pages with
  descriptive anchors.
- Accessibility and readability (clear language, good contrast, semantic HTML) help users *and*
  crawlers.

## Off-page (legitimate only)

- Earn backlinks by making things worth linking to — original research, thorough guides, tools,
  data. Links you *earn* are the ones that hold up.
- Genuine relationships, relevant guest contributions, and brand mentions in your niche.
- **Avoid**: bought links, link exchanges, PBNs, comment/forum spam — all violate spam policies and
  invite manual actions or algorithmic demotion.
- Monitor your backlink profile; use the **Disavow tool only with real caution** — it's a foot-gun,
  most sites should never touch it.

## Audit workflow

1. **Search Console** — coverage/indexing errors, which queries you already rank for, manual actions.
2. **PageSpeed Insights / CrUX** — real Core Web Vitals (field data beats lab data).
3. **Crawl** the site (any SEO crawler) — broken links, redirect chains, missing/duplicate titles &
   meta descriptions, orphan pages, thin content.
4. **Structured data** — validate with the Rich Results Test; fix errors/warnings.
5. **Content gaps** — map top queries to pages; find intent you don't yet answer.
6. **Fix highest-impact first** — indexing blockers > CWV failures > content gaps > link building.

## Verify

- Re-check Core Web Vitals in **field data** (CrUX/Search Console), not just a one-off lab run — lab
  and real-user numbers differ.
- Confirm new/changed pages are **indexed** (Search Console URL Inspection), not just published.
- Watch trends over **weeks**, not days — SEO effects lag; don't chase daily noise.

## Honest limits

- Exact ranking factors and weights are **not public**; anyone claiming precise cause-and-effect is
  guessing. This skill is fundamentals + where to look, not a ranking formula.
- Thresholds and even *which* metrics count change — **always verify against the live tools/docs**.
- White-hat SEO is **slow**; results compound over months. Anything promising fast rankings is
  usually black-hat and penalizable.
- Structured data / rich results **eligibility** ≠ guaranteed display; Google decides per query.
