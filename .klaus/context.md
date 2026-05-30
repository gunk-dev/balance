# Repository context

## Purpose
Balance is a personal health and wellness tracking PWA. The user is probed throughout the day for metrics (mood, stress, energy, etc.); tapping a value records it, skipping leaves it unrecorded. It is the check-ins / tracking surface of a three-app wellness toolset (siblings: `gunk-dev/flux` workouts, `gunk-dev/vibe` meditation) driven by an AI coach (see `CLAUDE.md`). Currently targets Android via PWA install (`README.md`, `client/vite.config.ts`).

## Tech stack
- **TypeScript** (strict mode per `CLAUDE.md`), Node 22 (`flake.nix`, `.github/workflows/ci.yml`).
- **Client:** React 18 + Vite 5 (`client/package.json`), Tailwind CSS v4 via `@tailwindcss/vite`, `lucide-react` for icons, `idb` for IndexedDB, `vite-plugin-pwa` for service worker/manifest.
- **Server:** Fastify 5 + `@fastify/static` (`server/package.json`), run with `tsx` in dev.
- **Testing:** Playwright e2e (`@playwright/test`, `client/e2e/`, `client/playwright.config.ts`).
- **Tooling:** ESLint + Prettier (root `package.json`), Nix flake dev shell (`flake.nix`), direnv (`.envrc`).
- **Workspaces:** npm workspaces with `client` and `server` (root `package.json`).

## Entry points
- `client/src/main.tsx` — React root; mounts `<App />` from `client/src/App.tsx`.
- `client/src/App.tsx` — top-level UI; consumes `useAppStore` from `client/src/store.ts`.
- `client/src/store.ts` — IndexedDB-backed app state, sync wiring, default metrics list.
- `server/src/index.ts` — Fastify server: `GET /api/health`, serves the built client from `client/dist`, SPA fallback to `index.html`. Listens on `PORT` (default `3001`).
- `client/src/sync/google-sheets.ts` — Google Sheets sync backend (implements `SyncBackend` from `client/src/sync/interface.ts`).
- `client/src/sync/google-auth.ts` — Google OAuth helpers used by the sheets backend.

## Layout
- `client/` — React PWA (Vite). `src/` holds app code, `e2e/` Playwright specs, `public/` static assets.
- `client/src/components/` — `MetricSlider.tsx`, `FoodLogger.tsx`.
- `client/src/sync/` — sync backend `interface.ts`, `google-sheets.ts`, `google-auth.ts`.
- `server/` — Fastify server that serves the built client and `/api/*`.
- `.github/workflows/` — `ci.yml` (lint, build, e2e, nix checks, zizmor), `staging.yml` (dispatches `balance-staging` to `gunk-dev/infra` on `main` push), `preview.yml` (dispatches `balance-preview` / cleanup for PRs).
- `docs/` — `PLAN.md` and `screenshot.png`.
- `.claude/` — Claude Code settings.

## Build, test, run
Prerequisites: Node 22 (or `nix develop` for the flake dev shell). Run from repo root unless noted.

- Install: `npm install`
- Dev (client + server concurrently): `npm run dev` — client at `http://localhost:5173`, server at `http://localhost:3001`. Vite proxies `/api` to the server (`client/vite.config.ts`).
- Build everything: `npm run build` (runs `build` in `client` then `server`).
- Lint: `npm run lint` (ESLint on `.ts`/`.tsx`).
- Format: `npm run format` / check: `npm run format:check`.
- E2E tests: `npm run test:e2e` (Playwright, defined in `client/package.json`).
- Server preview after build: `npm start -w server` (runs `node dist/index.js`).
- Nix: `nix develop` enters the dev shell; `nix build` builds the `balance` package; `nix build .#oci-image` builds a layered Docker image (`flake.nix`).

## Conventions
- **TypeScript strict mode** everywhere; **named exports preferred** over default exports (`CLAUDE.md`, see `App.tsx` exporting `function App`).
- **Prettier:** double quotes, semicolons, trailing commas (`.prettierrc`, `CLAUDE.md`).
- **Styling:** Tailwind v4 utilities preferred over custom CSS. Custom theme colors (`sage`, `cream`, `sand`, `forest`, `mint`) are declared in `client/src/index.css` via `@theme` (per `CLAUDE.md`).
- **React:** function components with hooks only.
- **Persistence:** IndexedDB via `idb`; all access goes through `client/src/store.ts` (DB name `balance`, version `1`).
- **Data model:** defined in `client/src/types.ts` (`Metric`, `LogEntry`, deferred `FoodLogEntry`).
- **Interaction:** tap-to-record, no save button; skip means don't record (`CLAUDE.md`, `README.md`).
- **Git:** never commit to `main`; use PR branches (`CLAUDE.md`).
- **API surface:** server routes go under `/api/` (`CLAUDE.md`, see `/api/health` in `server/src/index.ts`).

## Gotchas
- `client/vite.config.ts` sets `base: "/balance/"` only when `command === "build" && process.env.GITHUB_ACTIONS` — local builds and the server-served build use `/`.
- `server/src/index.ts` resolves the client dist as `../../client/dist` relative to its own compiled location, so the server expects the client to be built first; `npm run build` does this in order.
- `flake.nix` pins `npmDepsHash`; changing `package-lock.json` requires updating that hash for `nix build` to succeed.
- Staging and preview deploys are not done in this repo — workflows only emit `repository_dispatch` events to `gunk-dev/infra` (`.github/workflows/staging.yml`, `preview.yml`).
- Preview workflow is fork-guarded: it only runs when `pull_request.head.repo.full_name == github.repository` (`.github/workflows/preview.yml`).

## External dependencies
- **Google Sheets API** and **Google Drive API** at runtime when the user enables sync — `client/src/sync/google-sheets.ts` reads/writes a `Balance Data` spreadsheet under `gunk.dev/balance/` in Drive, authenticated via `client/src/sync/google-auth.ts`.
- **`gunk-dev/infra` repo** for staging and PR-preview deploys (triggered via `repository_dispatch` from `.github/workflows/staging.yml` and `preview.yml`; requires `INFRA_DISPATCH_TOKEN`).
- **GitHub Pages** hosts the public build at `balance.patflynn.github.io` (`README.md`).
