function Update-WinUtilSelections ($flatJson) {
    <#
        .SYNOPSIS
            Sorts imported entry names into the selection lists they belong to
    #>

    $unknown = New-Object System.Collections.Generic.List[string]

    foreach ($cbkey in $flatJson) {
        if ([string]::IsNullOrWhiteSpace($cbkey)) {
            continue
        }

        $listName = switch -Regex ($cbkey) {
            '^WPFInstall' { 'selectedApps' }
            '^WPFTweaks'  { 'selectedTweaks' }
            '^WPFToggle'  { 'selectedToggles' }
            '^WPFFeature' { 'selectedFeatures' }
            '^WPFAppx'    { 'selectedAppx' }
        }

        # A name from a hand written or outdated file matches nothing, and adding to the list
        # that is not there fails with an error that never names the entry that caused it
        if (-not $listName) {
            $unknown.Add([string]$cbkey)
            continue
        }

        if ($sync.$listName -notcontains $cbkey) {
            $sync.$listName.Add($cbkey)
        }
    }

    if ($unknown.Count -gt 0) {
        Write-WinUtilLog -Level "WARN" -Component "AutoRun" -Message "Ignored $($unknown.Count) entr(y/ies) that match no WinUtil item: $($unknown -join ', ')"
    }
}
