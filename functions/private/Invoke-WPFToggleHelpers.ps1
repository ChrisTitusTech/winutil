function Test-WinUtilProcessBusy {
    if ($sync.ProcessRunning) {
        return $true
    }

    if ($sync.ActiveToggleJobs -and $sync.ActiveToggleJobs -gt 0) {
        return $true
    }

    if ($sync.ToggleExecution -and $sync.ToggleExecution.Count -gt 0) {
        return $true
    }

    return $false
}

function Test-WPFToggleActionAllowed {
    param(
        [bool]$ImportInProgress
    )

    if ($ImportInProgress) {
        return @{ Allowed = $false; Reason = 'ImportInProgress' }
    }

    if (Test-WinUtilProcessBusy) {
        return @{ Allowed = $false; Reason = 'ProcessBusy' }
    }

    return @{ Allowed = $true; Reason = $null }
}

function Initialize-WPFToggleExecution {
    if (-not $sync.ToggleExecution) {
        $sync.ToggleExecution = [Hashtable]::Synchronized(@{})
    }
}

function Test-WPFToggleExecutionLock {
    param(
        [Parameter(Mandatory)]
        [string]$ToggleName
    )

    Initialize-WPFToggleExecution

    if ($sync.ToggleExecution.ContainsKey($ToggleName)) {
        return $false
    }

    $sync.ToggleExecution[$ToggleName] = $true
    return $true
}

function Release-WPFToggleExecutionLock {
    param(
        [Parameter(Mandatory)]
        [string]$ToggleName
    )

    if ($sync.ToggleExecution) {
        $sync.ToggleExecution.Remove($ToggleName) | Out-Null
    }
}

function Set-WPFToggleCheckedState {
    param(
        [Parameter(Mandatory)]
        [string]$ToggleName,
        [Parameter(Mandatory)]
        [bool]$IsChecked
    )

    if (-not $sync.$ToggleName) {
        return
    }

    $sync.SuppressToggleEvents = $true
    try {
        $sync.$ToggleName.IsChecked = $IsChecked
    } finally {
        $sync.SuppressToggleEvents = $false
    }
}

function Start-WPFToggleTweakJob {
    param(
        [Parameter(Mandatory)]
        [string]$ToggleName,
        [Parameter(Mandatory)]
        [bool]$Undo
    )

    if ($null -eq $sync.ActiveToggleJobs) {
        $sync.ActiveToggleJobs = 0
    }

    $sync.ActiveToggleJobs++

    $scriptBlock = if ($Undo) {
        {
            param($toggleName)
            try {
                Invoke-WinUtilTweaks $toggleName -undo $true
            } finally {
                Release-WPFToggleExecutionLock -ToggleName $toggleName
                $sync.ActiveToggleJobs--
            }
        }
    } else {
        {
            param($toggleName)
            try {
                Invoke-WinUtilTweaks $toggleName
            } finally {
                Release-WPFToggleExecutionLock -ToggleName $toggleName
                $sync.ActiveToggleJobs--
            }
        }
    }

    try {
        Invoke-WPFRunspace -ArgumentList $ToggleName -ScriptBlock $scriptBlock | Out-Null
    } catch {
        Release-WPFToggleExecutionLock -ToggleName $ToggleName
        $sync.ActiveToggleJobs--
        throw
    }
}