# Building & Serving the Docs

This repo's markdown docs are built into a searchable site with [MkDocs](https://www.mkdocs.org/) and the [Material theme](https://squidfunk.github.io/mkdocs-material/). This file covers how to build/serve locally and what the CI check does. (For the original discussion of hosting-platform options — MkDocs vs. Docusaurus vs. Mintlify/ReadMe/GitBook, and the docs.openbridge.com question — see git history on this file.)

## Prerequisites

```
pip install -r requirements-docs.txt
```

Installs `mkdocs` and `mkdocs-material` (pinned in `requirements-docs.txt`).

## Local development

```
mkdocs serve
```

Starts a live-reloading dev server at `http://127.0.0.1:8000/` — edits to any `.md` file under `api-usage-docs/`, `tutorials/`, or `products/` refresh automatically.

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

`api-usage-docs/data-model.md` is intentionally excluded from the build (`exclude_docs` in `mkdocs.yml`) since it's gitignored/internal and shouldn't be published even unlinked.

## GitHub Actions

`.github/workflows/docs.yml` runs on push to `main` and on pull requests that touch docs-related paths (`mkdocs.yml`, `requirements-docs.txt`, `docs/**`, `api-usage-docs/**`, `tutorials/**`, `products/**`). It installs `requirements-docs.txt` and runs `mkdocs build --strict` to confirm the site builds cleanly with no broken internal links or anchors.

This is a **build-validation check only** — it does not deploy anywhere. The final hosting target (GitHub Pages vs. folding into docs.openbridge.com vs. something else) is still an open decision. Once that's picked, the workflow needs a deploy step added (e.g. `mkdocs gh-deploy` or `actions/deploy-pages` for GitHub Pages, or a step that ships the built `site/` output to wherever docs.openbridge.com is served from).

## Content fixes already made

A round of pre-existing broken links and anchors (not caused by the MkDocs setup — these were always broken on GitHub too, just never validated) were fixed to get `--strict` passing:

- Relative links that didn't resolve, e.g. `./account-api.md` → `account-user-api.md`, `../products/storages.md` → `destinations.md`, and several `service-api.md` references from `products/` and `tutorials/` files that needed either a corrected path or a redirect to the specific per-service doc (`service-amazon-advertising-api.md`, `service-facebook-api.md`, `service-google-api.md`, `service-shopify-api.md`) where that content now actually lives.
- Anchor mismatches in `product-overview.md` (added a missing `## Mixed Amazon Seller and Vendor Products` header the table of contents already pointed at) and `identity-configuration.md` (TOC anchor updated to match a since-renamed header).
