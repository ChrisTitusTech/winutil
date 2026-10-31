# SPEC.md

Project contract for WinUtil — what the project is, how it's built, and how it runs. Written for anyone, human or AI, who needs to understand the project itself.

`AGENTS.md` in the repository root points here for these facts, and separately covers how an agent should behave while working in this repo. This file does not change based on who's reading it.

## Project Context

WinUtil is a Windows PowerShell utility with a WPF interface. The repository is maintained as modular source, but the distributed artifact is one compiled PowerShell script.

### Stack

- Language: Windows PowerShell / PowerShell.
- UI: WPF via `xaml/inputXML.xaml`.
- Configuration: JSON files under `config/`.
- Tests: Pester tests under `pester/`.
- Lint: PowerShell Script Analyzer with settings in `lint/PSScriptAnalyser.ps1`.
- Docs: Astro + Starlight site under `docs/`, built independently of `Compile.ps1` (its own `package.json`/`node_modules`).
- Release artifact: generated root `winutil.ps1`.

### Repository Layout

- `Compile.ps1`: build script that creates `winutil.ps1`.
- `scripts/start.ps1`: startup/bootstrap segment used at the beginning of the compiled script.
- `scripts/main.ps1`: main entrypoint appended at the end of the compiled script.
- `functions/public/`: public/UI-facing PowerShell functions.
- `functions/private/`: internal helper PowerShell functions.
- `config/`: JSON configuration consumed at compile time and embedded into `$sync.configs`.
- `xaml/inputXML.xaml`: WPF UI markup embedded into the compiled script.
- `tools/autounattend.xml`: unattended setup XML embedded for Windows ISO workflows.
- `pester/`: Pester tests for config and function checks.
- `lint/PSScriptAnalyser.ps1`: PowerShell Script Analyzer settings.
- `tools/title-screen/`: uv project that captures WinUtil's Light and Dark themes and generates the title-screen composite.
- `docs/`: Astro + Starlight documentation site, with its own `package.json` and build independent of `Compile.ps1`.
- `winutil.ps1`: ignored generated build artifact.

## Goals

- Provide a single-script Windows utility that can be launched from PowerShell.
- Keep development modular enough for contributors to work on functions, config, UI, docs, and tooling independently.
- Make install, tweak, feature, repair, update, and ISO workflows discoverable from the WPF UI.
- Keep common lists and options declarative in JSON config where possible.
- Preserve a repeatable compile process so local builds and GitHub Actions builds produce the distributable script from the same inputs.

## Non-Goals

- `winutil.ps1` is not hand-maintained.
- The project is not structured as a PowerShell module at runtime.
- The GUI is not a separate packaged desktop application in this repository's normal release path.
- Generated files should not be reviewed as source changes.

## Build Model

`Compile.ps1` combines the repository sources into `winutil.ps1` in this order:

1. Read `scripts/start.ps1` and replace `#{replaceme}` with `-Version`, which defaults to the current `yy.MM.dd` build date. A release cut from a tag that is not that date (a second release on one day, say) passes the tag, because the About dialog links `releases/tag/<version>`. `-Release` marks the output as published rather than local, as a CI build is, which that link and the debug-logging gate both read from `$sync.IsLocalCompile`.
2. Append every file under `functions/` recursively.
3. Convert each `config/*.json` file into embedded `$sync.configs` objects.
4. Special-case `config/applications.json` so keys receive the `WPFInstall` prefix in compiled config.
5. Embed `xaml/inputXML.xaml` into `$inputXML`.
6. Embed `tools/autounattend.xml` into `$WinUtilAutounattendXml`.
7. Append `scripts/main.ps1`.
8. Write the result to root `winutil.ps1`.

Because the final script is concatenated, code cannot rely on runtime module imports or source-relative dot-sourcing unless the compiled script will also contain the required code/data.

## Runtime Model

- WinUtil runs in PowerShell on Windows and uses WPF for the UI.
- Shared mutable state is stored in `$sync`, including configs, UI element references, runspace state, selections, and progress.
- Long-running operations use runspaces or existing async patterns so the UI remains responsive.
- UI updates from background work are dispatched back to the WPF UI thread.
- Every runspace logs to the timestamped `%LocalAppData%\winutil\logs` session file through `Write-WinUtilLog`, which shares one writer through `$sync`. Job output and the UI runspace's warnings, errors and `Write-Host` output are collected into it; console-only output such as banners and progress uses `Write-WinUtilHost`.
- Declarative features such as apps, tweaks, presets, DNS providers, and navigation stay in `config/*.json` unless code is required.

## UI And Event Contract

- UI layout lives in `xaml/inputXML.xaml`.
- Named WPF controls are discovered and stored in `$sync`.
- Button/action wiring follows a naming convention: an element named like `WPFThingButton` maps to a function named like `Invoke-WPFThingButton`.

## Configuration Contract

- Config files must remain valid JSON and compile cleanly through `ConvertFrom-Json`.
- `config/dns.json` opts unfiltered providers into Fastest selection with `BenchmarkEligible: true`; missing or false values exclude a provider from the TCP latency benchmark.
- `config/applications.json` defines installable applications; each entry includes the fields expected by tests and UI code, such as package manager IDs, category, display content, description, and link. Optional `license` (the License field of the package's WinGet manifest, copied as published) and `verified` (`yyyy-MM-dd` date it was checked) travel together; the license is shown in the app's tooltip. Pester checks package ID formats, case-insensitive duplicate keys and WinGet IDs, and the license/date pairing.
- `config/tweaks.json` defines Windows tweaks; registry and service changes include original values or original states when applicable so undo workflows can restore user systems.
- Preset and navigation files reference valid config keys. Renaming a config key requires updating all presets, UI references, docs, and code paths together.
- Adding or renaming a preset, adding a selection key prefix, or adding a new kind of tweak change also requires updating the docs Tools pages (see Docs Site).

## Safety Requirements

- Registry, service, package manager, Windows Update, AppX removal, and ISO operations affect the host system and are treated as high-risk.
- Tweak changes include undo metadata when the schema supports it, so changes stay reversible.
- ISO workflows never modify the user's original ISO file; they work on copied/mounted content.

## Docs Site (Astro)

- `docs/` is an Astro + Starlight site, independent of `Compile.ps1`'s build (its own `package.json`/`node_modules`, deployed via the `docs.yaml` GitHub Actions workflow to GitHub Pages).
- Pages live under `docs/src/content/docs/` (`.mdx`), organized into `guides/`, `code-reference/`, plus top-level pages like `faq.mdx`, `knownissues.mdx`, `contributing.mdx`, `index.mdx`.
- `docs/src/content/docs/code-reference/tweaks/` and `.../features/` are auto-generated by `tools/devdocs-generator.ps1` from `config/tweaks.json`/`config/feature.json` and the relevant PowerShell function files. Other pages under `code-reference/` (e.g. `architecture.mdx`) are hand-written and untouched by the generator.
- Sidebar entries in `docs/astro.config.mjs` must match actual page slugs under `docs/src/content/docs/`.
- The site's UI is plugged into Starlight through component overrides in `docs/src/components/overrides/` (Header, Sidebar, MobileMenuToggle, TableOfContents, MobileTableOfContents, PageTitle, Pagination, ThemeSelect), registered in `docs/astro.config.mjs`. Static parts are Astro components; interactive parts (search, menus, table of contents, theme toggle) are React islands in `docs/src/components/docs/`. Starlight still owns routing, Markdown rendering, the Pagefind search index, and the generated reference pages. The landing page (`index.mdx`) adds React Bits components (`docs/src/components/react-bits/`, MIT + Commons Clause; see its `LICENSE.md`) and GSAP + Lenis motion (`docs/src/scripts/landing-motion.js`, with landing-only components in `docs/src/components/landing/`). That motion is skipped entirely for visitors who prefer reduced motion.
- The Tools pages, Config Builder (`config-builder.mdx`, `docs/src/components/config-builder/`) and Tweak Explorer (`tweak-explorer.mdx`, `docs/src/components/tweak-explorer/`), fetch `config/*.json` in the browser from the latest stable release tag through `docs/src/lib/winutil-release.js` rather than bundling the repo's copy, because `-Config` runs the stable release and rejects the whole import on any key it does not know.
  - New or removed apps, tweaks, toggles, features, AppX packages, and categories show up in the next browser session after a release is marked Latest, with no docs rebuild. Pre-releases are not picked up. The Tweak Explorer shows a reference link only when the latest stable release's config contains that link, and its page exists once the pre-release docs-update PR is merged and the docs are redeployed.
  - Three things are hard-coded and must be updated by hand when WinUtil changes them: preset names (`Standard`, `Minimal`, `Advanced`, `AppxDefault`) in `ConfigBuilder.jsx` and `TweakExplorer.jsx`; the importable key prefixes (`WPFInstall`, `WPFTweaks`, `WPFToggle`, `WPFFeature`, `WPFAppx`) in `ConfigBuilder.jsx`, which mirror `Update-WinUtilSelections`; and the tweak change fields (`registry`, `service`, `InvokeScript`, `UndoScript`, `appx`, and registry `Values` mappings for `Combobox` entries) read by `TweakExplorer.jsx`, which mirror `Invoke-WinUtilTweaks` and `Set-WinUtilRegistryComboState`.
  - Config Builder share links, including the Tweak Explorer's hand-off, put the selected keys in the URL hash as a comma-separated list, built and read by `docs/src/lib/config-link.js`. Links are posted publicly, so the builder must keep reading that format.
- `docs/src/content/docs/resources/free-dev-services.mdx` is a hand-written page pointing at free-for.dev for developer services with free tiers. It links out rather than reproducing that list, which has no licence, and its sidebar group (`Resources`) is registered in `docs/astro.config.mjs`.
- `docs/src/content/docs/resources/microsoft-downloads.mdx` is a hand-written page linking Microsoft's official Windows installation media, Office / Microsoft 365 installers, and developer tools (microsoft.com only). It is media-only and links no activation tooling; it lives in the `Resources` sidebar group in `docs/astro.config.mjs`.
- `docs/public/` is tracked source for static assets (favicons, etc.), not generated output. Generated/ignored paths are listed in `docs/.gitignore` (`dist/`, `.astro/`, `node_modules/`, local env files).
- `docs/src/assets/branding/title-screen.png` is a tracked generated image used by the repository README and docs homepage. Its raw Light and Dark captures are temporary.
- `docs/Dockerfile` and `docs/docker-compose.yml` (service `winutil-astro`) containerize the site's npm tooling, including Playwright and its browsers (version pinned in `docs/package.json`); see AGENTS.md's Dependency Installs, Builds, And Dev Servers for why and how agents must use them instead of running npm on the host.

## Testing And CI

- `.\Compile.ps1` verifies the compiler can generate `winutil.ps1`.
- `.\Compile.ps1 -Run` compiles and launches the generated utility for manual GUI verification.
- Pester 5.8.0 runs the suite under `pester/*.Tests.ps1`. GitHub Actions (`unittests.yaml`) installs Pester 5.8.0 fresh and runs with `-CI`, which produces `testResults.xml` and exits non-zero on failure.
- GitHub Actions also runs PowerShell Script Analyzer with `lint/PSScriptAnalyser.ps1` on every push.
- The generated `winutil.ps1` may appear locally after compile. It remains ignored build output (see root `.gitignore`) and must not be committed.
- The manually triggered title-screen workflow compiles WinUtil from `main` and opens an image-only pull request when the generated composite changes. These pull requests require manual review. Failed runs retain diagnostics for 14 days.

## Release Artifact

GitHub Actions is responsible for producing the release `winutil.ps1` from repository sources. A release is considered valid only if the generated script came from the compile process, not from direct manual edits to `winutil.ps1`.
