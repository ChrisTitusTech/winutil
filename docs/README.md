# WinUtil Docs

[![Built with Starlight](https://astro.badg.es/v2/built-with-starlight/tiny.svg)](https://starlight.astro.build)

Documentation site for [WinUtil](https://github.com/ChrisTitusTech/winutil), built with [Astro](https://astro.build) and [Starlight](https://starlight.astro.build). Served at [winutil.christitus.com](https://winutil.christitus.com/).

## 🚀 Project Structure

```
.
├── public/
├── src/
│   ├── assets/
│   ├── components/
│   ├── content/
│   │   └── docs/
│   ├── styles/
│   └── content.config.ts
├── astro.config.mjs
├── docker-compose.yml
├── Dockerfile
├── package.json
└── tsconfig.json
```

Starlight looks for `.md` or `.mdx` files in the `src/content/docs/` directory. Each file is exposed as a route based on its file name.

Images can be added to `src/assets/` and embedded in Markdown with a relative link.

Static assets, like favicons, can be placed in the `public/` directory.

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
| `docker compose down`                              | Stop and remove the dev container                |

Source files are bind-mounted into the container, so edits on the host are picked up immediately by the dev server — no rebuild needed for normal content or code changes. After changing `package.json`, `package-lock.json`, or the `Dockerfile`, rebuild the image *and* drop the `node_modules` volume, since Docker only seeds a named volume from the image the first time it's created — a plain rebuild leaves the old `node_modules` in place:

```sh
docker compose build
docker compose down -v
docker compose up winutil-astro
```

The first `docker compose up` (or any command before an image exists) builds the image and runs `npm install` from scratch, which can take a few minutes. Subsequent runs reuse the cached image and start almost immediately.

## 👀 Want to learn more?

Check out [Starlight's docs](https://starlight.astro.build/), read [the Astro documentation](https://docs.astro.build), or jump into the [Astro Discord server](https://astro.build/chat).
