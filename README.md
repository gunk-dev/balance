# Balance

A personal health and wellness tracker that's fast enough to actually use every day.

<p align="center">
  <img src="docs/screenshot.png" alt="Balance" width="300" />
</p>

Balance probes you throughout the day on health and wellness metrics. Tap a value to record, skip what feels baseline. The whole interaction takes 5 seconds.

## Features

- 12 default metrics (mood, stress, energy, anxiety, fatigue, tension, headache, brain fog, sleepiness, water, alcohol, caffeine)
- Tap-to-record interaction (no save button)
- Offline-first with IndexedDB persistence
- Installable PWA (Android)
- Customizable metrics

## Try it

[**balance.patflynn.github.io**](https://patflynn.github.io/balance/)

## Development

```bash
npm install
npm run dev
npm run test:e2e
```

## Checks

Every CI test is also an offline Nix flake check on x86_64 Linux:

```bash
nix build .#checks.x86_64-linux.e2e
```

- `build` — production build of client and server
- `lint` — ESLint
- `e2e` — Playwright tests in headless Chromium
- `nixfmt` — Nix formatting
- `zizmor` — GitHub Actions workflow audit

## Tech Stack

React, TypeScript, Vite, Tailwind CSS, IndexedDB, Playwright
