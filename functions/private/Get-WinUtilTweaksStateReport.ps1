function Get-WinUtilTweaksStateReport {
    <#
    .SYNOPSIS
        Groups every config/tweaks.json entry's live applied state by category, reusing the same
        detection Invoke-WPFGetInstalled uses to check the "Get Installed Tweaks" checkboxes.
    #>

    $categoryFieldNames = [ordered]@{
        "Essential Tweaks"                    = "essentialTweaks"
        "Customize Preferences"               = "customizePreferences"
        "z__Advanced Tweaks - CAUTION"         = "advancedTweaks"
        "Performance Plans - NOT FOR LAPTOPS" = "performancePlans"
    }

    $grouped = [ordered]@{}
    foreach ($fieldName in $categoryFieldNames.Values) {
        $grouped[$fieldName] = [ordered]@{}
    }
    $notEvaluable = [System.Collections.Generic.List[string]]::new()
    $collectionStatus = "collected"

    try {
        $appliedTweaks = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]@(Invoke-WinUtilCurrentSystem -CheckBox "tweaks" `
                -BypassToggleStatusCache -StopOnReadError)
        )

        foreach ($property in $sync.configs.tweaks.PSObject.Properties) {
            $tweakKey = $property.Name
            $entry = $property.Value
            $fieldName = $categoryFieldNames[[string]$entry.category]

            # Buttons embedded in the tweaks panel (e.g. the OOSU/Ultimate Performance launchers)
            # are actions, not stateful tweaks, so they're outside this report's scope entirely.
            if (-not $fieldName -or $entry.Type -eq "Button") {
                continue
            }

            # Combobox tweaks and script-only tweaks with no registry/service schema have no
            # detectable current state. List them so the report doesn't silently drop them.
            if ($entry.Type -eq "Combobox" -or (-not $entry.registry -and -not $entry.service)) {
                $notEvaluable.Add($tweakKey)
                continue
            }

            $grouped[$fieldName][$tweakKey] = $appliedTweaks.Contains($tweakKey)
        }
    } catch {
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message "Failed to collect tweaks/toggle state: $($_.Exception.Message)"
        $collectionStatus = "unavailable"
    }

    # Empty groups from a failed collection would otherwise be indistinguishable in the JSON from a
    # successful scan that found nothing notable, so record whether collection actually ran.
    $result = [ordered]@{ collectionStatus = $collectionStatus }
    foreach ($fieldName in $categoryFieldNames.Values) {
        $result[$fieldName] = [pscustomobject]$grouped[$fieldName]
    }
    $result.notEvaluable = @($notEvaluable)

    return [pscustomobject]$result
}
