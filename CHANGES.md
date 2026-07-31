# WinUtil Audit Fixes — Technical Summary & Plain-Language Explanation

This document explains the changes in this commit. Part 1 is the technical explanation for developers.
Part 2 is a plain-language explanation for anyone without coding experience.

---

## Part 1 — Technical Explanation

All fixes were verified empirically: each bug was reproduced against the pristine `HEAD` version of the
file (`git show HEAD:<path>`), then the fix was demonstrated to change the behavior. Full suite:
**471 passed / 0 failed / 0 skipped** (Pester 5.8.0, `-CI`), `git diff --check` clean, and the
generated `winutil.ps1` (gitignored, CI-generated) compiles and parses under both the current parser
and Windows PowerShell 5.1.

### 1. `functions/public/Invoke-WPFInstall.ps1` — popup Install silently ignored the clicked app

- **Severity:** High (user-visible wrong behavior).
- **Root cause:** The function had no `param()` block. PowerShell functions without a `param()` block
  silently accept unknown named arguments into `$args` — they do **not** throw a binding error. The
  call site `Initialize-WPFUI.ps1:85` invokes `Invoke-WPFInstall -PackagesToInstall $appObject`;
  HEAD dropped that argument, and the body used `$sync.selectedApps` instead.
- **Reproduction (HEAD vs fixed, same `$sync`):**
  - Popup Install on VLC with Git also selected on the Install tab → HEAD queued **Git.Git** (wrong
    app); fixed queued **VideoLAN.VLC** (the clicked app).
  - Popup Install on VLC with nothing selected → HEAD showed "Please select the program(s)..." and
    queued nothing; fixed queued VLC.
  - Install tab button (no arguments) → identical behavior before/after (no regression).
- **Fix:** Added `param([Parameter(Mandatory = $false)][PSObject[]]$PackagesToInstall = $($sync.selectedApps | Foreach-Object { $sync.configs.applicationsHashtable.$_ }))`.
  The default expression is byte-identical to the old unconditional assignment, so the Install-tab
  path is unchanged. `[PSObject[]]` coerces the popup's single config object; `$null.Count -eq 0`
  keeps the empty-selection guard intact.
- **Note:** An earlier draft of this audit incorrectly described the failure as a "parameter cannot
  be found" binding error. Reproduction proved the mechanism is silent argument dropping, which is
  arguably worse (installs the wrong app instead of failing). The fix is correct either way.

### 2. Blank message-box titles — `Invoke-WPFInstall.ps1`, `Invoke-WPFUnInstall.ps1`

- **Severity:** Medium (cosmetic, user-visible).
- **Root cause:** The warning boxes referenced `$AppTitle`, which has **zero definitions** anywhere in
  the repository. Reproduced: the mock `Show-WinUtilMessage` captured `-Title` as empty string for
  both the "no packages selected" and "process running" boxes.
- **Fix:** Literal `"WinUtil"` in all four boxes, matching the XAML window title
  (`xaml/inputXML.xaml:14`) and the sibling dialogs (`Invoke-WPFOOSU.ps1`, `Invoke-WPFAppxInstall.ps1`,
  `Invoke-WPFAppxRemoval.ps1`). A repository-wide grep confirms no other `-Title $<var>` call uses an
  undefined variable.

### 3. `config/tweaks.json` — stray property in the `WPFToggleScrollbars` registry entry

- **Severity:** Medium (dead/corrupt data).
- **Root cause:** The registry entry contained a nested `"link"` property. Registry entries are
  consumed via `Path`, `Name`, `Value`, `Type`, `OriginalValue`, `DefaultState` only
  (`Get-WinUtilToggleStatus.ps1:26`, `Invoke-WinUtilCurrentSystem.ps1:85`); `registry[].link` is
  never read. HEAD entry: 7 properties; fixed: exactly the 6 consumed.
- **Fix:** Removed the nested `"link"` and its trailing comma (a bare removal would have left invalid
  JSON). The entry's top-level `link` is retained. Verified: JSON re-parses; `DefaultState: "false"`
  semantics unchanged (default → `OriginalValue` "1" → toggle unchecked).

### 4. `functions/public/Invoke-WPFPresets.ps1` — dead switch cases

- **Severity:** Low (latent).
- **Root cause:** The selection-list reset switch matches the literal `-checkboxfilterpattern`
  strings passed by callers (`Invoke-WPFButton.ps1:53-57,72` pass `"WPFTweak*"`, `"WPFInstall*"`,
  `"WPFAppx*"`). Cases `"WPFeatures"` and `"WPFToggle"` could never match any caller-supplied
  pattern, so `selectedFeatures`/`selectedToggles` were never cleared.
- **Reproduction:** `Invoke-WPFPresets -imported $true -checkboxfilterpattern 'WPFToggle*'` → HEAD
  left `selectedToggles` populated; fixed clears it (same for `WPFFeature*`). The `WPFTweak*` path
  still clears (regression-free).
- **Fix:** `"WPFFeature*"` and `"WPFToggle*"`, matching the canonical prefixes (see
  `Reset-WPFCheckBoxes.ps1:26` `-notlike "WPFToggle*"`).

### 5. `functions/public/Invoke-WPFUIElements.ps1` — radio-button group containers

- **Severity:** Low (latent/architectural).
- **Root cause:** The create branch of the RadioButton handler never stored the group StackPanel in
  `$radioButtonGroups`, making the reuse (`else`) branch provably unreachable; every radio button got
  its own container.
- **Runtime proof (live WPF, real XAML window + real `config/appnavigation.json`):** HEAD renders
  `WingetRadioButton` and `ChocoRadioButton` in **2 distinct parent StackPanels**; the fixed version
  renders them in **1 shared container**. Mutual exclusion is preserved in both (WPF `GroupName`
  grouping), so there is no user-visible change today — the fix restores the intended architecture
  and makes the `else` branch functional.
- **Fix:** one line, `$radioButtonGroups[$entryInfo.GroupName] = $groupStackPanel` (after the
  container creation). `$radioButtonGroups = @{}` is initialized at line 62 before the loop.

### 6. `pester/sanity.Tests.ps1` — Windows PowerShell parser check false positives

- **Severity:** High (test correctness).
- **Root cause:** The embedded parse script (which contains backtick escapes such as
  `` -split "`r?`n" `` and quoted strings) was passed to `powershell.exe -Command $parseScript`.
  Command-line quoting mangled the script, producing parse failures that do not exist in the files.
- **Reproduction (same script, same 86 files):**
  - OLD `-Command`: exit 1, errors "You must provide a value expression following the '-split'
    operator" and "Missing type name after '['" — transport artifacts, not file errors.
  - NEW `-EncodedCommand`: exit 0, all 86 files parse clean.
- **Fix:** `[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($parseScript))` +
  `-EncodedCommand`. `$LASTEXITCODE` handling and the env-var path round-trip are preserved.

### 7. `pester/install-workflow.Tests.ps1` — workaround removal + title assertions

- Removed the `$script:AppTitle = "Winutil"` workaround and the four orphaned
  `Remove-Variable -Name AppTitle` cleanup lines (remnants of the workaround).
- Updated the four `$Title -eq "Winutil"` assertions to `"WinUtil"` to match the corrected dialog
  titles. The "Are you sure?" assertions are untouched.

---

## Part 2 — Plain-Language Explanation

Here is what these changes do, without any coding jargon.

### 1. The right-click "Install" button now actually works
WinUtil can install apps two ways: tick boxes in the main list and press "Install", or right-click a
single app and use the small popup with Install / Uninstall buttons.
**The problem:** when you right-clicked an app and pressed Install, the program didn't understand
which app you clicked. It silently ignored your click and did something else — it installed whatever
was ticked in the main list (possibly the *wrong* app!), or told you "nothing selected" and did
nothing.
**The fix:** the popup now properly tells the installer "this specific app". Right-click VLC →
Install → VLC actually installs.

### 2. Warning boxes now have a proper title
Some warning popups ("Please select programs to install") had a **blank title bar** — the code
referred to a title that didn't exist. They now show "WinUtil", like every other dialog in the app.

### 3. Cleaned up a mislabelled setting
The "Scrollbars Always Visible" toggle had a stray line of text sitting inside its settings where it
didn't belong (like a label accidentally dropped into a drawer). It wasn't breaking anything, but it
was wrong data. Removed.

### 4. Fixed two switches that could never switch
WinUtil has preset buttons ("Standard", "Minimal", "Advanced") that reset the ticked options. Two of
the internal "clear the selection" switches had outdated/misspelled names, so they could never
trigger. The names now match how the options are actually named. No current button uses them yet, but
the mechanism is now correct.

### 5. Radio buttons now share their box
The Winget/Chocolatey choice in the sidebar are radio buttons (choose one). The code intended them to
sit together in one group box, but it forgot to keep the box — so each got its own. One missing line
added. No visible difference today, but the code now does what it was designed to do.

### 6. The "is the code valid?" check stopped crying wolf
This is a quality check that verifies all the code files are written correctly.
**The problem:** it handed the code to Windows PowerShell in a format that got garbled along the way,
so the check sometimes reported errors that **didn't actually exist** (false alarms).
**The fix:** the code is now passed in a tamper-proof format. The check now only reports real
problems.

### 7. Updated the tests to match
The automated tests that verify install/uninstall behavior had a temporary workaround in them (a
pretend title), only needed because of the bugs above. Removed the workaround and updated the tests
to expect the correct "WinUtil" title.

### How do we know it's actually fixed?
The bugs were reproduced by running the *old* buggy versions side by side with the *new* versions and
watching the difference (e.g., the old version installed the wrong app; the new one installs the app
you clicked). All 471 automated checks pass. The only honest caveat: verification was done at the
code level, not by clicking through a live window of the app.
