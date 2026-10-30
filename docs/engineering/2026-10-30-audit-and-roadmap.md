# WinUtil Pro — Technical Audit and Roadmap (2026-10-30)

This file is engineering notes, not part of the Astro site (it lives outside `docs/src/content/`).
Everything marked **Verified** was read in source or produced by a command run on 2026-10-30
on Windows 11 Pro 10.0.26300 with Windows PowerShell 5.1. Nothing here has been run under PowerShell 7.

## 1. Repository state

| Item | Value |
|---|---|
| Fork | `origin` → `https://github.com/6t9xstar/winutil-pro.git` |
| Upstream | `upstream` → `https://github.com/ChrisTitusTech/winutil.git` |
| Base commit | `b521c90` (same commit as `feature/modern-ui`) |
| Working branch | `claude/winutil-pro-audit-modernize-6b8b11` (worktree). `feature/modern-ui` is checked out in the main folder, and Git does not allow one branch in two worktrees; it can be fast-forwarded to this branch. |

## 2. Architecture (Verified)

- **Stack:** Windows PowerShell 5.1 / PowerShell 7, WPF (`xaml/inputXML.xaml`, 2,276 lines), JSON config under `config/`, Pester 5.8 tests, Astro + Starlight docs under `docs/`.
- **Build:** `Compile.ps1` (48 lines) concatenates `scripts/start.ps1`, every file under `functions/` (83 private + 35 public), all `config/*.json` as `$sync.configs`, the XAML, `tools/autounattend.xml`, and `scripts/main.ps1` into one `winutil.ps1` (1,092,416 bytes, 5.7 s compile).
- **Startup:** `start.ps1` checks elevation and relaunches elevated with a base64-serialized parameter payload (user values are deserialized and splatted, never interpolated into code). `main.ps1` builds the window, discovers named controls into `$sync`, and wires `WPF*` buttons to `Invoke-WPF*` handlers through `Invoke-WPFButton`.
- **Concurrency:** a shared runspace pool. Every function is copied into each runspace via `New-WinUtilSessionState`. Long work goes through `Start-WinUtilJob` / `Step-WinUtilJob`, and UI updates are dispatched back to the WPF thread.
- **Install/uninstall:** WinGet (`Install-WinUtilProgramWinget`) or Chocolatey (`Install-WinUtilProgramChoco`), selected by radio buttons in `config/appnavigation.json`.
- **Catalog:** `config/applications.json` with fields `category, choco, content, description, link, winget, foss`. Before this work it had 239 entries in 10 categories, with no duplicate WinGet IDs and no entry lacking both package IDs.

**Assessment:** the architecture is sound and already modular, with a job layer, a logging layer, and declarative config. A rewrite (React/Tauri/C#) or an MVVM migration is **not** justified by anything found; the cost would be losing upstream merge compatibility with no measured benefit. Recommended changes are incremental (section 6).

## 3. Baseline quality (Verified)

| Check | Result |
|---|---|
| `.\Compile.ps1` | Pass |
| Pester 5.8.0, full suite | 1015 total, 1001 passed, **13 failed**, 1 skipped |
| Script Analyzer (project settings) | 656 findings, 0 errors (392 `PSReviewUnusedParameter`, 88 `ShouldProcess`, 80 global vars; mostly accepted conventions per AGENTS.md) |

All 13 failures are **Windows PowerShell 5.1 test-harness issues, not product bugs**. CI runs the suite under `pwsh`:
- 11 × `pester/winoneshot-compat.Tests.ps1`: uses `ConvertFrom-Json -NoEnumerate`, which exists only in PowerShell 7.
- `pester/onedrive-removal.Tests.ps1` "restores permissions…": the fixture adds a `ProcessName` note property to an unstarted `Process`. In 5.1, `Where-Object` reads the adapted .NET property, which throws, so the mocked `Stop-Process` is never reached. Real processes are unaffected.
- `pester/oosu.Tests.ps1` "falls back to the plain percentage…": fails the same way with and without this pass's changes. The root cause was not investigated.

## 4. Findings

| # | Finding | Evidence | Severity | Status |
|---|---|---|---|---|
| F1 | O&O ShutUp10++ is downloaded and launched with no publisher or signature check | `functions/public/Invoke-WPFOOSU.ps1` | High | **Fixed** |
| F2 | Sysinternals Autologon is downloaded and launched with no signature check, timeout, or `-UseBasicParsing` | `functions/public/Invoke-WPFPanelAutologin.ps1` | High | **Fixed** |
| F3 | "Adobe URL Block List" appends an unvalidated third-party GitHub file to the system `hosts` file; a compromised list could redirect any domain | `config/tweaks.json` → `WPFTweaksBlockAdobeNet` | High | **Fixed** |
| F4 | The Adobe block undo deletes everything after `#New Ver`, including any lines the user added later | same tweak, `UndoScript` | Medium | Open (behavior change; needs a decision) |
| F5 | The Chocolatey bootstrap runs `community.chocolatey.org/install.ps1` with no integrity check | `functions/private/Install-WinUtilChoco.ps1:17` | Medium | Open. This is the vendor-documented install path, and Chocolatey publishes no stable hash to pin. Option: verify the downloaded nupkg signature instead. |
| F6 | The PowerShell-profile feature runs `irm …/powershell-profile/raw/main/setup.ps1 \| iex` from a mutable branch | `functions/private/Invoke-WinUtilInstallPSProfile.ps1:46` | Medium | Open. Pin to a commit or release, or show the user the source before running it. |
| F7 | The non-local relaunch path re-downloads upstream `ChrisTitusTech/winutil` instead of the fork's release | `scripts/start.ps1:172` | Medium (product) | **Fixed** (commit 808dddf): the relaunch downloads the WinUtil Pro release. Release 26.10.30 is published, and `irm 6t9xstar.github.io/win \| iex` runs it through the `6t9xstar/win` launcher. |
| F8 | `Invoke-WinUtilSponsors` scrapes the GitHub sponsors HTML with regex | `functions/private/Invoke-WinUtilSponsors.ps1` | Low | Open (fragile, not a security issue) |
| F9 | 13 tests cannot pass on Windows PowerShell 5.1 (section 3) | `pester/` | Low | Open. Local runs need PS7 to match CI. |
| F10 | The PowerShell MSI upgrade already verifies SHA-256 and the Microsoft Authenticode signature | `functions/private/Install-WinUtilProgramWinget.ps1:98-113` | — | Good pattern; F1/F2 now follow it |

## 5. Changes made in this pass

1. **New `Assert-WinUtilFileSignature`** (`functions/private/`). It requires an Authenticode status of `Valid` and an exact signer common name. On failure it deletes the file and throws, so the job layer reports the error and nothing is launched.
   - OOSU requires `CN=O&O Software GmbH`; Autologon requires `CN=Microsoft Corporation`. Both signers were checked on 2026-10-30 by downloading each binary to an isolated temp folder and reading its signature only (both `Valid`). The binaries were then deleted.
2. **Adobe hosts list validation.** The tweak refuses to write unless every non-comment line is a `0.0.0.0 <host>` entry and the `#New Ver` marker that undo depends on is present. The real upstream list (974 lines, 948 entries) still passes.
3. **10 catalog entries added.** Each WinGet ID was confirmed with `winget show --id <id> -e` and each Chocolatey ID with `choco search --exact` on 2026-10-30.

| Key | WinGet | Choco | Category | FOSS |
|---|---|---|---|---|
| opera | Opera.Opera | opera | Browsers | no |
| gitkraken | Axosoft.GitKraken | gitkraken | Development | no |
| podmandesktop | RedHat.Podman-Desktop | podman-desktop | Development | yes (Apache-2.0) |
| bun | Oven-sh.Bun | bun | Development | yes (MIT) |
| mongodbcompass | MongoDB.Compass.Full | mongodb-compass | Development | no |
| dbeaver | DBeaver.DBeaver.Community | dbeaver | Development | yes (Apache-2.0) |
| pgadmin | PostgreSQL.pgAdmin | pgadmin4 | Development | yes (PostgreSQL) |
| redisinsight | RedisInsight.RedisInsight | na (none found) | Development | no |
| burpsuitecommunity | PortSwigger.BurpSuite.Community | na (Choco package stuck at 2022.12) | Pro Tools | no |
| zap | ZAP.ZAP | zap | Pro Tools | yes (Apache-2.0) |

   Deliberately **not** added:
   - iPerf3 (`ar51an.iPerf3`) and ExifTool (`OliverBetz.ExifTool`): third-party builds, not vendor releases.
   - Insomnia and Typora: no WinGet package found under the expected IDs.

4. **Tests:** `pester/file-signature.Tests.ps1` (7 cases), `pester/adobe-hosts.Tests.ps1` (3), and new cases in `oosu.Tests.ps1` and `system-helpers.Tests.ps1`.

**After these changes:** compile passes; Pester shows 1031 total, 1017 passed, the same 13 pre-existing 5.1 failures, and 1 skipped; Script Analyzer reports no new findings beyond the accepted stub-parameter pattern.

**Not verified:** a GUI run (`.\Compile.ps1 -Run`), a real install of any new catalog entry, the full suite under PowerShell 7, and the WinOneShot catalog contract test for the new entries (it only runs under PS7).

## 6. Roadmap

Ordered by value and risk. Each item should land as its own reviewable change.

**Phase A — security follow-ups (small, high value)**
- F6: pin the profile setup script to a commit SHA.
- F4: make the Adobe undo remove only the block it added (wrap it in begin/end markers).
- F7: decide the release source for WinUtil Pro, then point the relaunch and docs at it.
- Run the suite under PowerShell 7 locally (`winget install Microsoft.PowerShell`) so local results match CI.

**Phase B — catalog data model (prerequisite for recommendations and new sections)**
- Extend the `applications.json` schema with optional fields such as `license`, `pricing` (free/freemium/paid/subscription), `subcategory`, `tags`, and `verified` (date). Optional fields keep the WinOneShot contract and the docs Config Builder working, but `pester/winoneshot-compat.Tests.ps1` and SPEC.md's Configuration Contract must be updated in the same change.
- Add a Pester test that fails on malformed WinGet/Choco IDs and duplicate keys (duplicates are already checked).
- Keep adding apps only with per-ID verification as done above.

**Phase C — UI (needs design decisions; see questions below)**
- The Install tab already has search, category chips, and selection; the remaining gaps are an installed-only filter, favorites, and a details pane. These fit the existing `Initialize-InstallAppEntry` rendering and should be built there rather than as a new screen.
- A system-info dashboard can reuse `Get-WinUtilEnvironmentReport`, which already collects OS, CPU, RAM, and disk data.

**Phase D — new sections (each needs a scope decision first)**
- *Cybersecurity tools:* the safest fit is a `Security` category in `applications.json` (Wireshark, Nmap, Burp, ZAP are already there under Pro Tools) plus an authorization notice. WinUtil only installs these tools; it never runs them.
- *Free Dev Tools (free-for-dev):* this is a list of web services, not installable software. It belongs in the docs site as a curated, attributed page, not in the WPF installer. Its license must be checked before any content is copied.
- *Engineering Skills (mattpocock/skills):* agent prompt files, not Windows apps. If it is wanted, it fits as a separate opt-in feature that copies into a user-chosen `.agents` folder, backs up any existing files, and is gated on the upstream license.
- *Recommendation engine:* depends on Phase B metadata. Recommendations must be marked as editorial and must not include invented benchmarks or ratings.

## 6a. Phase B, first pass — catalog metadata (done)

- Two new optional fields in `config/applications.json`:
  - `license`: copied verbatim from the `License:` line of `winget show --id <id> -e`.
  - `verified`: the date it was checked (`yyyy-MM-dd`).
- Filled for 247 of 249 entries on 2026-10-30. `chatgpt` and `whatsapp` use `msstore:` IDs, which the lookup did not cover.
- Licenses are **not normalized**; values such as `GPLv3` and `GPL-3.0` appear exactly as each manifest publishes them.
- The license is shown in the Install-tab tooltip (`Get-WinUtilEntryToolTip -License`).
- New Pester checks in `configs.Tests.ps1`: WinGet/Choco ID format, case-insensitive duplicate keys and WinGet IDs, `license` requires `verified`, and `verified` is a valid date that is not in the future.
- **Open data question:** the WinGet license disagrees with the existing `foss` flag for `protonmail`, `protondrive` (foss=true, Proprietary), and for `tailscale`, `nilesoftShell`, `everything` (foss=false, open-source license). These were left unchanged for a maintainer to decide.
- Not yet added: a `pricing` field (free/freemium/paid). WinGet has no reliable source for it, so each value needs a per-app check of the vendor's site.

## 7. Reproduce

```powershell
.\Compile.ps1
Import-Module Pester -RequiredVersion 5.8.0 -Force
Invoke-Pester -Path 'pester/*.Tests.ps1' -Output Detailed -CI
Remove-Item .\winutil.ps1 -ErrorAction SilentlyContinue
Invoke-ScriptAnalyzer -Path . -Settings .\lint\PSScriptAnalyser.ps1 -Recurse
```
