---
name: project-urm
description: URM Simulator project structure — two codebases, GitHub Pages web app in docs/
metadata:
  type: project
---

Two related projects in the same Dropbox folder:

1. **URM-Simulator** (has GitHub remote `github.com/glenzini/URM-Simulator`) — OCaml CLI simulator, built with Makefile. The `docs/` folder contains a pure-JS GitHub Pages version of the web app.

2. **URM-Server** (no confirmed GitHub remote) — OCaml Dream HTTP server + JS frontend (`public/`). Runs with `dune` on localhost:8080.

**Why:** The GitHub Pages version (docs/) was created by porting the entire OCaml backend to JavaScript (`docs/urm-engine.js`). Saves go to localStorage instead of the server; examples are fetched as static .txt files.

**How to apply:** When working on the GitHub Pages version, edit files in `docs/`. The OCaml server version is in `URM-Server/`. GitHub Actions workflow at `.github/workflows/pages.yml` auto-deploys on push to main.

**Activation:** GitHub Pages must be enabled in repo Settings → Pages → Source: GitHub Actions (one-time manual step).
