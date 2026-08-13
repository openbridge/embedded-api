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

Same as above, but treats broken internal links/anchors as errors instead of warnings. Currently fails — see **Known issues** below.

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

`.github/workflows/docs.yml` runs on push to `main` and on pull requests that touch docs-related paths (`mkdocs.yml`, `requirements-docs.txt`, `docs/**`, `api-usage-docs/**`, `tutorials/**`, `products/**`). It installs `requirements-docs.txt` and runs `mkdocs build` to confirm the site builds cleanly.

This is a **build-validation check only** — it does not deploy anywhere. The final hosting target (GitHub Pages vs. folding into docs.openbridge.com vs. something else) is still an open decision. Once that's picked, the workflow needs a deploy step added (e.g. `mkdocs gh-deploy` or `actions/deploy-pages` for GitHub Pages, or a step that ships the built `site/` output to wherever docs.openbridge.com is served from).

The workflow deliberately runs `mkdocs build` rather than `mkdocs build --strict` for now — see below.

## Known issues (pre-existing content, not caused by the MkDocs setup)

Running `mkdocs build --strict` currently surfaces:

- **Broken relative links**, e.g. `./account-api.md` (likely meant `account-user-api.md`), `../products/storages.md` (renamed to `destinations.md` per git history), and several `service-api.md` references from `products/` and `tutorials/` files using paths that don't resolve from those subdirectories.
- **A handful of anchor mismatches** in `product-overview.md` and `identity-configuration.md` — links pointing at headers that don't exist under that exact slug.

These links have always been broken on GitHub too (GitHub doesn't validate markdown links), so this isn't a regression — just now visible. Fixing them and switching the CI workflow to `--strict` is a reasonable follow-up once someone has time for it.
