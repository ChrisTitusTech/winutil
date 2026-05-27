function Invoke-WinUtilInstallDevLauncher {
    <#
    .SYNOPSIS
        Installs the optional WinUtil development command launcher.
    .DESCRIPTION
        Creates a user-level 'winutil-dev' command launcher in LocalAppData\winutil\bin
        and appends this path to the current user's PATH environment variable.
    #>
    $binPath = Join-Path $env:LocalAppData "winutil\bin"

    Write-Host "Installing WinUtil Dev command launcher..."

    try {
        if (-not (Test-Path $binPath)) {
            $null = New-Item -Path $binPath -ItemType Directory -Force
        }

        $cmdFile = Join-Path $binPath "winutil-dev.cmd"
        $ps1File = Join-Path $binPath "winutil-dev-launcher.ps1"
        $legacyPs1File = Join-Path $binPath "winutil-dev.ps1"

        # Content of winutil-dev.cmd: resolves pwsh vs powershell and forwards arguments
        $cmdContent = @'
@echo off
setlocal
where pwsh >nul 2>nul
if %ERRORLEVEL% equ 0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0winutil-dev-launcher.ps1" %*
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0winutil-dev-launcher.ps1" %*
)
'@

        # Content of winutil-dev-launcher.ps1: downloads latest WinUtil Dev and passes args via @args
        $ps1Content = @'
$uri = "https://christitus.com/windev"
try {
    $scriptBlock = [ScriptBlock]::Create((Invoke-RestMethod -Uri $uri -TimeoutSec 15))
    & $scriptBlock @args
} catch {
    Write-Error "Failed to retrieve the latest WinUtil dev script from $uri. Please check your internet connection.`nError details: $_"
}
'@

        # Write command launcher scripts
        Set-Content -Path $cmdFile -Value $cmdContent -Encoding Ascii -Force
        Set-Content -Path $ps1File -Value $ps1Content -Encoding UTF8 -Force

        # Remove legacy ps1 script if it exists
        if (Test-Path $legacyPs1File) {
            Remove-Item -Path $legacyPs1File -Force -ErrorAction SilentlyContinue
        }

        # Update User environment PATH
        $registryKey = Get-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -ErrorAction SilentlyContinue
        $currentPath = if ($registryKey) { $registryKey.Path } else { "" }

        $targetPath = $binPath.TrimEnd('\')
        $pathNormalized = $targetPath.Replace('/', '\')
        $existingPaths = $currentPath -split ';' | ForEach-Object { $_.Trim().TrimEnd('\').Replace('/', '\') }

        if ($existingPaths -notcontains $pathNormalized) {
            $newPath = if ($currentPath) { "$currentPath;$targetPath" } else { $targetPath }
            [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
            Write-Host "Successfully added '$targetPath' to User PATH." -ForegroundColor Green
        } else {
            Write-Host "'$targetPath' is already in User PATH."
        }

        # Update current process PATH session
        $sessionPaths = $env:PATH -split ';' | ForEach-Object { $_.Trim().TrimEnd('\').Replace('/', '\') }
        if ($sessionPaths -notcontains $pathNormalized) {
            $env:PATH = "$env:PATH;$binPath"
        }

        # Update launcher registry key to keep state in sync
        $registryPath = "HKCU:\Software\WinUtil"
        if (-not (Test-Path $registryPath)) {
            $null = New-Item -Path $registryPath -Force
        }
        Set-ItemProperty -Path $registryPath -Name "DevCommandLauncher" -Value 1 -Type DWord

        Write-Host "WinUtil Dev command launcher installed successfully!" -ForegroundColor Green
        Write-Host "Please open a new terminal window to use the 'winutil-dev' command." -ForegroundColor Yellow
    } catch {
        Write-Error "Failed to install WinUtil Dev command launcher. Error: $_"
    }
}
