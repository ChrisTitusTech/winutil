Function Uninstall-WinUtilEdgeBrowser {
    <#
    .SYNOPSIS
        Uninstall the Edge Browser (Chromium) from the system in an elegant way.
    .DESCRIPTION
        This will switch up the region to one of the EEA countries temporarily and uninstall the Edge Browser (Chromium).
    #>

    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("install", "uninstall")]
        [string]$action
    )

    function Uninstall-EdgeClient {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Key
        )

        $originalNation = [microsoft.win32.registry]::GetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', [Microsoft.Win32.RegistryValueKind]::String)

        # Set Nation to any of the EEA regions temporarily
        # Refer: https://learn.microsoft.com/en-us/windows/win32/intl/table-of-geographical-locations
        $tmpNation = 68 # Ireland
        [microsoft.win32.registry]::SetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', $tmpNation, [Microsoft.Win32.RegistryValueKind]::String) | Out-Null

        $baseKey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'
        $registryPath = $baseKey + '\ClientState\' + $Key

        if (!(Test-Path -Path $registryPath)) {
            Write-Host "[$Mode] Registry key not found: $registryPath"
            return
        }

        # Remove the status flag
        Remove-ItemProperty -Path $baseKey -Name "IsEdgeStableUninstalled" -ErrorAction SilentlyContinue | Out-Null

        Remove-ItemProperty -Path $registryPath -Name "experiment_control_labels" -ErrorAction SilentlyContinue | Out-Null

        $uninstallString = (Get-ItemProperty -Path $registryPath).UninstallString
        $uninstallArguments = (Get-ItemProperty -Path $registryPath).UninstallArguments

        if ([string]::IsNullOrEmpty($uninstallString) -or [string]::IsNullOrEmpty($uninstallArguments)) {
            Write-Host "[$Mode] Cannot find uninstall methods for $Mode"
            return
        }

        # Extra arguments to nuke it
        $uninstallArguments += " --force-uninstall --delete-profile"

        # $uninstallCommand = "`"$uninstallString`"" + $uninstallArguments
        if (!(Test-Path -Path $uninstallString)) {
            Write-Host "[$Mode] setup.exe not found at: $uninstallString"
            return
        }
        Start-Process -FilePath $uninstallString -ArgumentList $uninstallArguments -Wait -NoNewWindow -Verbose

        # Restore Nation back to the original
        [microsoft.win32.registry]::SetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', $originalNation, [Microsoft.Win32.RegistryValueKind]::String) | Out-Null

        # might not exist in some cases
        if ((Get-ItemProperty -Path $baseKey).IsEdgeStableUninstalled -eq 1) {
            Write-Host "[$Mode] Edge Stable has been successfully uninstalled"
        }
    }

    function Uninstall-Edge {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null

        [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdateDev", "AllowUninstall", 1, [Microsoft.Win32.RegistryValueKind]::DWord) | Out-Null

        Uninstall-EdgeClient -Key '{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'

        Remove-Item -Path "Computer\\HKEY_CLASSES_ROOT\\MSEdgePDF" -ErrorAction SilentlyContinue | Out-Null
        Remove-Item -Path "Computer\\HKEY_CLASSES_ROOT\\MSEdgeHTM" -ErrorAction SilentlyContinue | Out-Null
        Remove-Item -Path "Computer\\HKEY_CLASSES_ROOT\\MSEdgeMHT" -ErrorAction SilentlyContinue | Out-Null

        # Remove Edge Polocy reg keys
        Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Recurse -ErrorAction SilentlyContinue | Out-Null

        # Remove Edge reg keys
        Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Edge" -Recurse -ErrorAction SilentlyContinue | Out-Null
    }

    function Uninstall-WebView {
        # FIXME: might not work on some systems

        Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null

        Uninstall-EdgeClient -Key '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
    }

    function Uninstall-EdgeUpdate {
        # FIXME: might not work on some systems

        Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null

        $registryPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'
        if (!(Test-Path -Path $registryPath)) {
            Write-Host "Registry key not found: $registryPath"
            return
        }
        $uninstallCmdLine = (Get-ItemProperty -Path $registryPath).UninstallCmdLine

        if ([string]::IsNullOrEmpty($uninstallCmdLine)) {
            Write-Host "Cannot find uninstall methods for $Mode"
            return
        }

        Start-Process cmd.exe "/c $uninstallCmdLine" -WindowStyle Hidden -Wait

        # Remove EdgeUpdate reg keys
        Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate" -Recurse -ErrorAction SilentlyContinue | Out-Null
    }

    function Install-Edge {
        $tempEdgePath = "$env:TEMP\MicrosoftEdgeSetup.exe"

        try {
            write-host "Installing Edge ..."
            Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2109047&Channel=Stable&language=en&consent=1" -OutFile $tempEdgePath
            Start-Process -FilePath $tempEdgePath -ArgumentList "/silent /install" -Wait
            Remove-item $tempEdgePath
            write-host "Edge Installed Successfully"
        } catch {
            write-host "Failed to install Edge"
        }
    }

    if ($action -eq "Install") {
        Install-Edge
    } elseif ($action -eq "Uninstall") {
        Uninstall-Edge
        Uninstall-EdgeUpdate
        # Uninstall-WebView - WebView is needed for Visual Studio and some MS Store Games like Forza
    }
}
