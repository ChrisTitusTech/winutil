function Start-WinUtilNextQueuedJob {
    <#
        .SYNOPSIS
            Starts the oldest queued job if the slot is free

        .DESCRIPTION
            Runs on the interface thread, posted by Clear-WinUtilActiveJob when a job finishes
            whether it succeeded or not. Until the job it starts claims the slot, $sync.JobHandoff
            keeps new actions queueing behind it, and every way out of here clears the flag.
    #>
    if ($sync.ShuttingDown -or $sync.FinishInConsole) {
        Reset-WinUtilJobHandoff
        return
    }

    $next = $null
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        if (-not $sync.ActiveJob -and $sync.JobQueue.Count -gt 0) {
            $next = $sync.JobQueue[0]
            $sync.JobQueue.RemoveAt(0)
        } else {
            $sync.JobHandoff = $false
        }
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }

    if ($null -eq $next) {
        Update-WinUtilJobQueueUI
        return
    }

    Write-WinUtilLog -Component $next.Name -Message "Starting queued $($next.Name) job."
    # FromQueue clears the handoff in the same lock that claims the slot, or when it refuses
    Start-WinUtilJob -Name $next.Name -Description $next.Description -ScriptBlock ([scriptblock]::Create($next.ScriptBlock)) -Parameters $next.Parameters -DisableAppList:$next.DisableAppList -FromQueue
}

function Reset-WinUtilJobHandoff {
    <#
        .SYNOPSIS
            Lets new actions claim the slot again after a handoff that will not complete
    #>
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        $sync.JobHandoff = $false
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }
}

function Get-WinUtilQueuedJobIndex {
    <#
        .SYNOPSIS
            Finds a queued job by Id, or -1. The caller holds the SyncRoot lock.
    #>
    param([string]$Id)

    for ($index = 0; $index -lt $sync.JobQueue.Count; $index++) {
        if ($sync.JobQueue[$index].Id -eq $Id) {
            return $index
        }
    }
    return -1
}

function Move-WinUtilQueuedJob {
    <#
        .SYNOPSIS
            Moves a queued job one place earlier or later, doing nothing at either end

        .PARAMETER Id
            The Id of the queued job.

        .PARAMETER Direction
            Up runs it sooner, Down later.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [ValidateSet("Up", "Down")]
        [string]$Direction
    )

    $moved = $null
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        $index = Get-WinUtilQueuedJobIndex -Id $Id
        $target = if ($Direction -eq "Up") { $index - 1 } else { $index + 1 }
        if ($index -ge 0 -and $target -ge 0 -and $target -lt $sync.JobQueue.Count) {
            $moved = $sync.JobQueue[$index]
            $sync.JobQueue.RemoveAt($index)
            $sync.JobQueue.Insert($target, $moved)
        }
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }

    if ($moved) {
        Write-WinUtilLog -Component $moved.Name -Message "Moved queued $($moved.Name) job $($Direction.ToLower())."
        Update-WinUtilJobQueueUI
    }
}

function Remove-WinUtilQueuedJob {
    <#
        .SYNOPSIS
            Cancels a queued job before it starts

        .PARAMETER Id
            The Id of the queued job. A job that has already started is not in the queue.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    $removed = $null
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        $index = Get-WinUtilQueuedJobIndex -Id $Id
        if ($index -ge 0) {
            $removed = $sync.JobQueue[$index]
            $sync.JobQueue.RemoveAt($index)
        }
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }

    if ($removed) {
        Write-WinUtilLog -Component $removed.Name -Message "Cancelled queued $($removed.Name) job."
        Update-WinUtilJobQueueUI
    }
}

function Clear-WinUtilJobQueue {
    <#
        .SYNOPSIS
            Drops every queued job and returns how many were dropped

        .DESCRIPTION
            For the window closing: nothing queued may start once it is gone.
    #>
    $dropped = 0
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        $dropped = $sync.JobQueue.Count
        $sync.JobQueue.Clear()
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }

    if ($dropped -gt 0) {
        Write-WinUtilLog -Component "UI" -Message "Discarded $dropped queued job(s) because the window is closing."
    }
    return $dropped
}

function Update-WinUtilJobQueueUI {
    <#
        .SYNOPSIS
            Shows the queue button while anything runs or waits, and rebuilds the open dropdown

        .DESCRIPTION
            Interface thread only. Other threads post it through Invoke-WPFUIThread.
    #>
    if ($null -eq $sync.JobQueueButton) {
        return
    }

    # A copy, so the rows are built without holding the lock the workers need
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        $queued = $sync.JobQueue.ToArray()
        $running = $sync.ActiveJob
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }

    $busy = $running -or $queued.Count -gt 0
    $sync.JobQueueButton.Visibility = if ($busy) { "Visible" } else { "Collapsed" }
    $sync.JobQueueCount.Text = if ($queued.Count -gt 0) { [string]$queued.Count } else { "" }

    if (-not $busy) {
        $sync.JobQueuePopup.IsOpen = $false
    }
    if (-not $sync.JobQueuePopup.IsOpen) {
        return
    }

    $sync.JobQueueRunning.Text = if ($running) { "Running: $running" } else { "Nothing running" }
    $sync.JobQueueItems.Children.Clear()

    for ($index = 0; $index -lt $queued.Count; $index++) {
        $row = New-Object Windows.Controls.Grid
        $row.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width = "*"}))
        for ($column = 0; $column -lt 3; $column++) {
            $row.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width = "30"}))
        }

        # Trimmed with a tooltip because the dropdown has a fixed width
        $label = New-Object Windows.Controls.TextBlock
        $label.Text = $queued[$index].Name
        $label.ToolTip = $queued[$index].Name
        $label.TextTrimming = "CharacterEllipsis"
        $label.VerticalAlignment = "Center"
        $label.Margin = "5,0,5,0"
        $label.SetResourceReference([Windows.Controls.TextBlock]::FontSizeProperty, "ButtonFontSize")
        $label.SetResourceReference([Windows.Controls.TextBlock]::ForegroundProperty, "MainForegroundColor")
        $row.Children.Add($label) | Out-Null

        $column = 1
        foreach ($action in @(
            @{ Glyph = 0xE70E; Tip = "Run sooner"; Enabled = $index -gt 0; Click = { Move-WinUtilQueuedJob -Id $this.Tag -Direction Up } },
            @{ Glyph = 0xE70D; Tip = "Run later"; Enabled = $index -lt ($queued.Count - 1); Click = { Move-WinUtilQueuedJob -Id $this.Tag -Direction Down } },
            @{ Glyph = 0xE711; Tip = "Cancel"; Enabled = $true; Click = { Remove-WinUtilQueuedJob -Id $this.Tag } }
        )) {
            $button = New-Object Windows.Controls.Button
            $button.FontFamily = "Segoe MDL2 Assets"
            $button.Content = [string][char]$action.Glyph
            $button.ToolTip = $action.Tip
            $button.Tag = $queued[$index].Id
            $button.IsEnabled = $action.Enabled
            $button.Opacity = if ($action.Enabled) { 1 } else { 0.3 }
            $button.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, "MainForegroundColor")
            $button.SetResourceReference([Windows.Controls.Control]::StyleProperty, "HoverButtonStyle")
            $button.Add_Click($action.Click)
            [System.Windows.Controls.Grid]::SetColumn($button, $column++)
            $row.Children.Add($button) | Out-Null
        }

        $sync.JobQueueItems.Children.Add($row) | Out-Null
    }
}
