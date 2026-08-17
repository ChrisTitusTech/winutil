function Invoke-WPFToggleSelections {
    <#

    .SYNOPSIS
        Applies every selected toggle

    .DESCRIPTION
        In the window a toggle applies itself the moment it is switched, so nothing ever had to
        apply a list of them. An imported configuration carries toggles the same way it carries
        tweaks, and without this they would be read and then ignored.

    #>

    $toggles = @($sync.selectedToggles)

    if ($toggles.Count -eq 0) {
        Show-WinUtilMessage -Message "No toggles are selected." -Title "WinUtil" -Button "OK" -Icon "Warning" | Out-Null
        return
    }

    Write-WinUtilLog -Component "Toggles" -Message "Toggles requested: $($toggles.Count) selected."

    Start-WinUtilJob -Name "Toggles" -Description "Applying toggles" -Parameters @{
        Toggles = $toggles
    } -ScriptBlock {
        param($Toggles)

        $total = [Math]::Max(@($Toggles).Count, 1)
        $completed = 0

        foreach ($toggle in $Toggles) {
            Step-WinUtilJob -Status "Applying $toggle ($($completed + 1)/$total)" -Percent ([int](($completed / $total) * 100))
            Measure-WinUtilStep -Scope "Toggles" -Name $toggle -ScriptBlock {
                Invoke-WinUtilTweaks $toggle
            }
            $completed++
            Step-WinUtilJob -Percent ([int](($completed / $total) * 100))
        }
    }
}
