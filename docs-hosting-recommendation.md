# Building & Serving the Docs

This repo's markdown docs are built into a searchable site with [MkDocs](https://www.mkdocs.org/) and the [Material theme](https://squidfunk.github.io/mkdocs-material/). This file covers how to build/serve locally and what the CI check does. (For the original discussion of hosting-platform options — MkDocs vs. Docusaurus vs. Mintlify/ReadMe/GitBook, and the docs.openbridge.com question — see git history on this file.)

## Prerequisites

```
pip install -r requirements-docs.txt
```

Installs `mkdocs`, `mkdocs-material`, and `mkdocs-llmstxt-md` (pinned in `requirements-docs.txt`).

## Local development

```
mkdocs serve
```

Starts a live-reloading dev server — edits to any `.md` file under `api-usage-docs/`, `tutorials/`, or `products/` refresh automatically. Because `site_url` is set to `https://docs.openbridge.com/api/` (a placeholder — see **GitHub Actions** below), mkdocs serves locally under that same path prefix: `http://127.0.0.1:8000/api/`, not the bare root.

```
mkdocs build
```

Builds the static site into `site/` (gitignored — regenerated on every build, never committed).

```
mkdocs build --strict
```

Same as above, but treats broken internal links/anchors as errors instead of warnings. This is also what CI runs.

## Project layout

| Path | What it is |
|---|---|
| `mkdocs.yml` | Site config: theme, nav structure, markdown extensions |
| `docs/index.md` | Hand-written landing page |
| `docs/api-usage-docs`, `docs/tutorials`, `docs/products` | Symlinks to the existing top-level content directories — edit content in `api-usage-docs/`, `tutorials/`, `products/` directly, not under `docs/` |
| `site/` | Generated build output — gitignored |
| `requirements-docs.txt` | Pinned Python deps for building the site |

`api-usage-docs/data-model.md` is intentionally excluded from the build (`exclude_docs` in `mkdocs.yml`) since it's gitignored/internal and shouldn't be published even unlinked. Verified this exclusion also holds for the raw-markdown/llms.txt output below — it doesn't leak in either.

## Raw markdown for AI/LLM consumption

`SKILL.md` in this repo already lets local tools (Claude Code, etc.) read the source `.md` files directly from a git checkout — that's unaffected by any of this. The gap this closes is for AI agents/tools that only have **web access** to the deployed site and would otherwise have to scrape rendered HTML.

The `mkdocs-llmstxt-md` plugin adds three things, generated automatically on every build:

- **Per-page raw markdown**: every rendered page `<path>/index.html` gets a sibling `<path>/index.md` with the original source. E.g. `/api/api-usage-docs/getting-started/index.html` → `/api/api-usage-docs/getting-started/index.md`.
  - Note: this is `<path>/index.md`, not the bare `<path>.md` sibling that fastmcp/Mintlify use — MkDocs' default directory-URL layout (`<path>/index.html`) makes a same-directory `index.md` the natural fit, and a bare `<path>.md` file would collide with the `<path>/` directory on most web servers. Functionally equivalent for AI consumption; just a different URL shape.
- **`/llms.txt`** — a page index (title + link per doc) at the site root, pointing at the working `index.md` URLs above.
- **`/llms-full.txt`** — the entire doc set concatenated into one file.

No config was needed beyond adding `- llmstxt-md` to `plugins:` in `mkdocs.yml` — all three are on by default. Verified locally: builds cleanly through the `docs/api-usage-docs`, `docs/tutorials`, `docs/products` symlinks, respects `exclude_docs`, and serves the expected content/content-type (`text/markdown`) at runtime.

## GitHub Actions

`.github/workflows/docs.yml` runs on push to `main` and on pull requests that touch docs-related paths (`mkdocs.yml`, `requirements-docs.txt`, `docs/**`, `api-usage-docs/**`, `tutorials/**`, `products/**`). It installs `requirements-docs.txt` and runs `mkdocs build --strict` to confirm the site builds cleanly with no broken internal links or anchors.

This is a **build-validation check only** — it does not deploy anywhere. The final hosting target (GitHub Pages vs. folding into docs.openbridge.com vs. something else) is still an open decision. Once that's picked, the workflow needs a deploy step added (e.g. `mkdocs gh-deploy` or `actions/deploy-pages` for GitHub Pages, or a step that ships the built `site/` output to wherever docs.openbridge.com is served from) — and `site_url` in `mkdocs.yml` (currently `https://docs.openbridge.com/api/` as a placeholder, needed for the llms.txt plugin below) needs to be updated to match wherever it actually ends up.

## Content fixes already made

A round of pre-existing broken links and anchors (not caused by the MkDocs setup — these were always broken on GitHub too, just never validated) were fixed to get `--strict` passing:

- Relative links that didn't resolve, e.g. `./account-api.md` → `account-user-api.md`, `../products/storages.md` → `destinations.md`, and several `service-api.md` references from `products/` and `tutorials/` files that needed either a corrected path or a redirect to the specific per-service doc (`service-amazon-advertising-api.md`, `service-facebook-api.md`, `service-google-api.md`, `service-shopify-api.md`) where that content now actually lives.
- Anchor mismatches in `product-overview.md` (added a missing `## Mixed Amazon Seller and Vendor Products` header the table of contents already pointed at) and `identity-configuration.md` (TOC anchor updated to match a since-renamed header).
