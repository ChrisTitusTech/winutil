<#
.SYNOPSIS
    Compiles winutil.ps1 and builds a Windows installer (WinUtil-Setup-<version>.exe).

.DESCRIPTION
    1. Runs Compile.ps1 to bundle all functions + configs into winutil.ps1.
    2. Locates Inno Setup 6 (ISCC.exe) — installs it via winget if missing.
    3. Invokes ISCC.exe with winutil.iss to produce the installer under .\installer\.

.EXAMPLE
    .\build-installer.ps1
    .\build-installer.ps1 -SkipCompile     # reuse an existing winutil.ps1
    .\build-installer.ps1 -Version "26.06.05"
#>

param (
    [switch]$SkipCompile,
    [string]$Version = (Get-Date -Format 'yy.MM.dd')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot

function Find-ISCC {
    $candidates = @(
        'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
        'C:\Program Files\Inno Setup 6\ISCC.exe',
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
        (Get-Command iscc -ErrorAction SilentlyContinue)?.Source
    ) | Where-Object { $_ -and (Test-Path $_) }
    return $candidates | Select-Object -First 1
}

# ── Step 1: Compile ──────────────────────────────────────────────────────────
if (-not $SkipCompile) {
    Write-Host "Compiling winutil.ps1..." -ForegroundColor Cyan
    & "$projectRoot\Compile.ps1"
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Compile.ps1 failed (exit $LASTEXITCODE)."
    }
    Write-Host "Compile succeeded." -ForegroundColor Green
} else {
    Write-Host "Skipping compile (-SkipCompile)." -ForegroundColor Yellow
}

$winutilPs1 = Join-Path $projectRoot 'winutil.ps1'
if (-not (Test-Path $winutilPs1)) {
    throw "winutil.ps1 not found at '$winutilPs1'. Run without -SkipCompile first."
}

# ── Step 2: Locate / install Inno Setup ──────────────────────────────────────
$iscc = Find-ISCC
if (-not $iscc) {
    Write-Host "Inno Setup 6 not found. Attempting install via winget..." -ForegroundColor Yellow
    winget install --id JRSoftware.InnoSetup --silent --accept-source-agreements --accept-package-agreements
    $iscc = Find-ISCC
}

if (-not $iscc) {
    Write-Error @"
Inno Setup 6 (ISCC.exe) was not found and could not be installed automatically.

Please install it manually from:
    https://jrsoftware.org/isdl.php

Then re-run this script.
"@
    exit 1
}

Write-Host "Using ISCC: $iscc" -ForegroundColor Cyan

# ── Step 3: Create output directory ─────────────────────────────────────────
$installerDir = Join-Path $projectRoot 'installer'
if (-not (Test-Path $installerDir)) {
    New-Item -ItemType Directory -Path $installerDir | Out-Null
}

# ── Step 4: Build installer ──────────────────────────────────────────────────
$issFile = Join-Path $projectRoot 'winutil.iss'
Write-Host "Building installer (version $Version)..." -ForegroundColor Cyan

& $iscc "/DMyAppVersion=$Version" $issFile

if ($LASTEXITCODE -ne 0) {
    throw "ISCC.exe failed (exit $LASTEXITCODE)."
}

$outputExe = Join-Path $installerDir "WinUtil-Setup-$Version.exe"
if (Test-Path $outputExe) {
    Write-Host "`nInstaller ready: $outputExe" -ForegroundColor Green
} else {
    Write-Warning "Build reported success but '$outputExe' was not found. Check ISCC output above."
}
