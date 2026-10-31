# WinUtil Docs

[![Built with Starlight](https://astro.badg.es/v2/built-with-starlight/tiny.svg)](https://starlight.astro.build)

Documentation site for [WinUtil](https://github.com/ChrisTitusTech/winutil), built with [Astro](https://astro.build), [Starlight](https://starlight.astro.build), and [React](https://react.dev). Served at [winutil.christitus.com](https://winutil.christitus.com/).

Starlight handles routing, Markdown rendering, and the search index. The site's own UI is plugged in through Starlight's component overrides: static parts (sidebar, page titles, pagination) are Astro components, and interactive parts (search, menus, table of contents, theme toggle) are React islands.

## 🚀 Project Structure

```
.
├── public/                  # Static files served as-is (favicon, robots.txt, social preview)
├── src/
│   ├── assets/              # Images used by pages (optimized at build time); icons/ holds the docs UI icons
│   ├── components/
│   │   ├── config-builder/  # Config Builder page component and styles
│   │   ├── docs/            # Docs UI: React islands (search, menus, table of contents, theme toggle) and the sidebar list
│   │   ├── landing/         # Landing-page-only components (stats, cards, motion wrapper)
│   │   ├── overrides/       # Starlight component overrides (thin .astro wrappers, registered in astro.config.mjs)
│   │   ├── react-bits/      # Vendored React Bits components (see react-bits/LICENSE.md)
│   │   ├── tweak-explorer/  # Tweak Explorer page component and styles
│   │   └── YouTubeEmbed.astro
│   ├── content/
│   │   └── docs/            # Pages (.md/.mdx); code-reference/tweaks and /features are generated
│   ├── hooks/               # React hooks
│   ├── lib/                 # Shared code (site links, release config loader, config links)
│   ├── scripts/             # Client-side scripts (landing-page GSAP + Lenis motion)
│   ├── styles/              # Global CSS: theme, fonts, docs UI
│   └── content.config.ts
├── astro.config.mjs
├── docker-compose.yml
├── Dockerfile
├── package.json
└── tsconfig.json
```

Each `.md` or `.mdx` file in `src/content/docs/` becomes a route based on its file path. Don't hand-edit `src/content/docs/code-reference/tweaks/` or `.../features/`; they're generated from `config/tweaks.json` and `config/feature.json` by `tools/devdocs-generator.ps1`.

Images can be added to `src/assets/` and embedded in Markdown with a relative link.

Static assets, like favicons, can be placed in the `public/` directory.

## 🧰 Tools Pages

The Config Builder (`/config-builder/`) and Tweak Explorer (`/tweak-explorer/`) load `config/*.json` in the browser from the latest stable WinUtil release, through `src/lib/winutil-release.js`. They don't use the copy in this repo, because `-Config` runs the stable release and rejects any key it doesn't know.

New apps, tweaks, toggles, features, AppX packages, and categories appear in the next browser session after a release is marked Latest. No docs rebuild is needed, and pre-releases are ignored. A few things are hard-coded and need updating here when WinUtil changes them:

- Preset names (`Standard`, `Minimal`, `Advanced`, `AppxDefault`), in `ConfigBuilder.jsx` and `TweakExplorer.jsx`.
- The key prefixes WinUtil can import (`WPFInstall`, `WPFTweaks`, `WPFToggle`, `WPFFeature`, `WPFAppx`), in `ConfigBuilder.jsx`. These mirror `Update-WinUtilSelections`.
- The tweak fields the explorer shows (`registry`, `service`, `InvokeScript`, `UndoScript`, `appx`, and registry `Values` mappings for `Combobox` entries), in `TweakExplorer.jsx`. These mirror `Invoke-WinUtilTweaks` and `Set-WinUtilRegistryComboState`.

Config Builder links carry the selected keys in the URL hash, e.g. `/config-builder/#WPFInstall7zip,WPFTweaksTelemetry`. `src/lib/config-link.js` builds and reads them for both pages. People post these links on Discord and the forums, so keep reading the existing format if you ever change it.

## 📚 Resources Pages

`resources/free-dev-services.mdx` is hand-written. It points at [free-for.dev](https://free-for.dev/) for developer services with free tiers, and deliberately links rather than reproducing that list, which carries no licence. Its deep links go to section anchors of the upstream README, so check them if you reorganise the page.

`resources/microsoft-downloads.mdx` is hand-written. It links Microsoft's official download pages for Windows media, Office / Microsoft 365, and developer tools (microsoft.com only) — installation media, not activation tooling. If a Microsoft URL moves, update it here.

`resources/certification-toolkits.mdx` is hand-written. It maps certifications to Install-tab tools by name, so it has to be re-checked whenever `config/applications.json` entries are renamed or removed.

If you add another tool page, or anything else that has to be kept in sync by hand, list it here and in SPEC.md's Docs Site section.

## 🧞 Commands

All commands run in a Docker container — there's no need to install Node or npm dependencies on your host. This is deliberate, not just convenience: npm/pnpm/yarn have seen a steady stream of supply-chain attacks (malicious `postinstall`/`preinstall` scripts, credential-stealing packages), so `npm install` and friends never run directly on a contributor's machine here. Note the container still has read-write access to this `docs/` directory (it's bind-mounted for live reload), so this only contains a compromised package to the project folder plus the container itself — it doesn't reach the rest of your host (SSH keys, other repos, cloud credentials elsewhere on disk). Don't keep real secrets in `docs/` as a result.

[Docker](https://www.docker.com/) (with Compose) is required — install Docker Desktop (or Docker Engine + the `docker compose` plugin on Linux) and make sure the daemon is running before using any of the commands below.

All commands are run from the `docs/` directory, from a terminal:

| Command                                          | Action                                           |
| :------------------------------------------------ | :----------------------------------------------- |
| `docker compose build`                             | Builds the dev image (needed after Dockerfile or dependency changes) |
| `docker compose up winutil-astro`                                | Starts local dev server at `localhost:4321`      |
| `docker compose run --rm winutil-astro npm run build`   | Build the production site to `./dist/`           |
| `docker compose run --rm --service-ports winutil-astro npm run preview -- --host 0.0.0.0` | Preview the build locally, before deploying      |
| `docker compose run --rm winutil-astro npm run astro ...` | Run CLI commands like `astro add`, `astro check` |
| `docker compose run --rm winutil-astro npx --no-install playwright ...` | Run Playwright against Chromium, Firefox, or WebKit |
| `docker compose down`                              | Stop and remove the dev container                |

Source files are bind-mounted into the container, so edits on the host are picked up immediately by the dev server — no rebuild needed for normal content or code changes. After changing `package.json`, `package-lock.json`, or the `Dockerfile`, rebuild the image *and* drop the `node_modules` volume, since Docker only seeds a named volume from the image the first time it's created — a plain rebuild leaves the old `node_modules` in place:

```sh
docker compose build
docker compose down -v
docker compose up winutil-astro
```

The image also installs Playwright's browsers for the `@playwright/test` version pinned in `package.json`, so bumping that version needs the same rebuild to fetch matching browsers.

The first `docker compose up` (or any command before an image exists) builds the image and runs `npm ci` from scratch, which can take a few minutes. Subsequent runs reuse the cached image and start almost immediately.

## 👀 Want to learn more?

Check out [Starlight's docs](https://starlight.astro.build/) (including its [component overrides guide](https://starlight.astro.build/guides/overriding-components/)), read [the Astro documentation](https://docs.astro.build), or jump into the [Astro Discord server](https://astro.build/chat).
