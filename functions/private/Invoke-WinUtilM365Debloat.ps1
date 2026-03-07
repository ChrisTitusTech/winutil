function Invoke-WinUtilSimpleM365 {
    <#
    .SYNOPSIS
        Performs a surgical installation of Microsoft 365, leaving only Word, Excel, and PowerPoint.
    .DESCRIPTION
        Wraps the transformation logic in a WPF-compatible runspace via Invoke-WPFRunspace.
        The ODT download URL is resolved dynamically at runtime from Microsoft's redirect service.
    #>

    $ScriptBlock = {
        param($sync)

        $ErrorActionPreference = "Continue"
        Add-Type -AssemblyName PresentationFramework

        Write-Host "--- Simple M365 Transformation Start ---" -ForegroundColor Cyan

        # ── Helper: popup notice (WPF dispatcher-aware) ──────────────────
        function Show-Notice {
            param([string]$Message, [string]$Title = "Simple M365")
            if ($sync -and $sync.form -and $sync.form.Dispatcher) {
                $null = $sync.form.Dispatcher.Invoke([Action]{
                    [System.Windows.MessageBox]::Show(
                        $Message, $Title,
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Information
                    )
                })
            } elseif ($Host.Name -match "ConsoleHost") {
                Read-Host "Press Enter to continue"
            }
        }

        # ── Helper: resolve ODT URL via fwlink redirect (no scraping) ────────
        function Resolve-OdtDownloadUrl {
            try {
                $fwlink = "https://go.microsoft.com/fwlink/p/?LinkID=626065"
                $req = [System.Net.HttpWebRequest]::Create($fwlink)
                $req.Method          = "HEAD"
                $req.AllowAutoRedirect = $false
                $req.UserAgent       = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
                $req.Timeout         = 10000

                $resp     = $req.GetResponse()
                $location = $resp.Headers["Location"]
                $resp.Close()

                if ($location) {
                    Write-Host "   Resolved ODT URL: $location" -ForegroundColor Gray
                    return $location
                }
                Write-Warning "fwlink redirect returned no Location header."
            }
            catch {
                Write-Warning "URL resolution failed: $($_.Exception.Message)"
            }
            return $null
        }

        # ── Helper: locate winget.exe ─────────────────────────────────────
        function Get-WingetPath {
            $cmd = Get-Command winget -ErrorAction SilentlyContinue
            if ($cmd -and $cmd.Source) { return $cmd.Source }

            $patterns = @(
                "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller*_x64__8wekyb3d8bbwe\winget.exe",
                "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller*_x86__8wekyb3d8bbwe\winget.exe",
                "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
            )

            foreach ($pattern in $patterns) {
                $hit = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue |
                       Sort-Object LastWriteTime -Descending |
                       Select-Object -First 1
                if ($hit) { return $hit.FullName }
            }
            return $null
        }

        # ── 1. Registry detection ─────────────────────────────────────────
        $regPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
        if (-not (Test-Path $regPath)) {
            Write-Warning "Microsoft 365 Click-to-Run not found in registry."
            Show-Notice "Microsoft 365 Click-to-Run configuration was not found in the registry."
            return
        }

        $officeConfig = Get-ItemProperty $regPath
        $arch = if ($officeConfig.Platform -eq "x86") { "32" } else { "64" }
        $prodId = $null

        $releaseIds = [string]$officeConfig.ProductReleaseIds
        if (-not [string]::IsNullOrWhiteSpace($releaseIds)) {
            $prodId = $releaseIds.Split(',')[0].Trim()
        } else {
            @(
                "O365ProPlusRetail","O365BusinessRetail",
                "ProPlus2019Retail","ProPlus2021Retail","ProPlus2024Volume"
            ) | Where-Object {
                $officeConfig.PSObject.Properties.Name -contains $_ -or
                $officeConfig.PSObject.Properties.Name -contains "$_.ExcludedApps"
            } | Select-Object -First 1 | ForEach-Object { $prodId = $_ }
        }

        if ([string]::IsNullOrWhiteSpace($prodId)) {
            Write-Warning "Unable to determine Product ID."
            Show-Notice "Unable to determine Product ID from Click-to-Run configuration."
            return
        }

        Write-Host "Detected: $prodId | $arch-bit" -ForegroundColor Gray

        # ── 2. Prepare working directory ──────────────────────────────────
        $odtDir          = Join-Path $env:TEMP "SimpleM365"
        $odtSetupPath    = Join-Path $odtDir "setup.exe"
        $odtInstallerPath = Join-Path $odtDir "odt_installer.exe"
        $xmlPath         = Join-Path $odtDir "simple.xml"

        if (Test-Path $odtDir) { Remove-Item $odtDir -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item -Path $odtDir -ItemType Directory -Force | Out-Null

        # ── 3. Kill stale Office processes & reset service ────────────────
        Write-Host "-> Stopping stale Office processes..." -ForegroundColor Yellow
        @("setup","OfficeClickToRun","OfficeC2RClient","AppVShNotify") | ForEach-Object {
            if (Get-Process $_ -ErrorAction SilentlyContinue) {
                Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
                Write-Host "   Stopped: $_" -ForegroundColor Gray
            }
        }
        Restart-Service "ClickToRunSvc" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3

        # ── 4. Resolve & download ODT (no hardcoded version URLs) ─────────
        Write-Host "-> Resolving ODT download URL..." -ForegroundColor Yellow
        $odtUrl = Resolve-OdtDownloadUrl

        $downloadSucceeded = $false

        if ($odtUrl) {
            try {
                Write-Host "-> Downloading ODT from: $odtUrl" -ForegroundColor Gray
                Invoke-WebRequest -Uri $odtUrl -OutFile $odtInstallerPath `
                    -UseBasicParsing -UserAgent "Mozilla/5.0" -ErrorAction Stop

                $f = Get-Item $odtInstallerPath -ErrorAction SilentlyContinue
                if ($f -and $f.Length -ge 1MB) { $downloadSucceeded = $true }
                else { Write-Warning "Downloaded file too small or missing." }
            }
            catch { Write-Warning "Download failed: $($_.Exception.Message)" }
        }

        # Winget fallback (also dynamic – winget resolves the version itself)
        if (-not $downloadSucceeded) {
            $wingetPath = Get-WingetPath
            if ($wingetPath) {
                Write-Host "-> Trying winget fallback..." -ForegroundColor Yellow
                try {
                    & $wingetPath download `
                        --id Microsoft.OfficeDeploymentTool --exact `
                        --source winget --download-directory $odtDir `
                        --accept-source-agreements --accept-package-agreements | Out-Null

                    $hit = Get-ChildItem $odtDir -Filter "*.exe" -ErrorAction SilentlyContinue |
                           Where-Object { $_.Name -ne "setup.exe" } |
                           Sort-Object LastWriteTime -Descending |
                           Select-Object -First 1

                    if ($hit) {
                        Copy-Item $hit.FullName $odtInstallerPath -Force
                        $downloadSucceeded = $true
                    } else { throw "winget produced no installer." }
                }
                catch { Write-Warning "winget fallback failed: $($_.Exception.Message)" }
            }
        }

        if (-not $downloadSucceeded) {
            Show-Notice "Failed to download the Office Deployment Tool. Check your network connection."
            return
        }

        # ── 5. Extract setup.exe ──────────────────────────────────────────
        Write-Host "-> Extracting setup.exe..." -ForegroundColor Gray
        try {
            Start-Process -FilePath $odtInstallerPath `
                -ArgumentList "/extract:`"$odtDir`" /quiet" -Wait -ErrorAction Stop
        }
        catch {
            Show-Notice "Extraction failed. The ODT installer may be blocked by antivirus."
            return
        }

        if (-not (Test-Path $odtSetupPath)) {
            Show-Notice "setup.exe was not extracted. Check $odtDir for details."
            return
        }

        # ── 6. Generate XML ───────────────────────────────────────────────
        $xmlContent = @"
<Configuration>
  <Remove All="TRUE" />
  <Add OfficeClientEdition="$arch" Channel="Current" MigrateArch="TRUE">
    <Product ID="$prodId">
      <Language ID="MatchOS" />
      <ExcludeApp ID="Access" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneDrive" />
      <ExcludeApp ID="OneNote" />
      <ExcludeApp ID="Outlook" />
      <ExcludeApp ID="Publisher" />
      <ExcludeApp ID="Teams" />
      <ExcludeApp ID="Bing" />
    </Product>
  </Add>
  <Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
"@

        Write-Host "-> Writing XML configuration..." -ForegroundColor Gray
        [System.IO.File]::WriteAllText($xmlPath, $xmlContent, [System.Text.Encoding]::ASCII)

        # ── 7. Run ODT ────────────────────────────────────────────────────
        Write-Host "-> Running ODT configure pass..." -ForegroundColor Green
        try {
            $p = Start-Process -FilePath $odtSetupPath `
                     -ArgumentList "/configure `"$xmlPath`"" `
                     -PassThru -WindowStyle Normal
            Write-Host "   ODT PID: $($p.Id) — waiting..." -ForegroundColor Gray
            $p.WaitForExit()
            Write-Host "   Exit code: $($p.ExitCode)" -ForegroundColor Cyan

            if ($p.ExitCode -eq 0) {
                Write-Host "Success! Clean Word + Excel + PowerPoint installed." -ForegroundColor Green
            } else {
                Write-Warning "ODT failed (exit $($p.ExitCode)). Inspect $odtDir."
            }
        }
        catch { Write-Warning "Critical error: $($_.Exception.Message)" }

        Write-Host "`n--- Done. Files remain in $odtDir ---" -ForegroundColor Cyan
        Show-Notice "Simple M365 finished. Files are in $odtDir"
    }

    # ── Kick off in a WPF-compatible runspace ─────────────────────────────
    Invoke-WPFRunspace -ScriptBlock $ScriptBlock -ParameterList @(
        ,@("sync", $sync)
    )
}

function Invoke-WinUtilM365Debloat {
    Invoke-WinUtilSimpleM365
}
