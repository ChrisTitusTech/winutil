Function Get-WinUtilToggleStatus {
    <#

    .SYNOPSIS
        Pulls the registry keys for the given toggle switch and checks whether the toggle should be checked or unchecked

    .PARAMETER ToggleSwitch
        The name of the toggle to check

    .OUTPUTS
        Boolean to set the toggle's status to

    #>

    Param($ToggleSwitch)

    $ToggleSwitchReg = $sync.configs.tweaks.$ToggleSwitch.registry

    if ($ToggleSwitchReg) {
        $count = 0

        foreach ($regentry in $ToggleSwitchReg) {
            $regstate = (Get-ItemProperty -path $($regentry.Path)).$($regentry.Name)
            if ($regstate -eq $regentry.Value) {
                $count += 1
            } else {
                write-debug "$($regentry.Name) is false (state: $regstate, value: $($regentry.Value), original: $($regentry.OriginalValue))"
            }
        }

        if ($count -eq $ToggleSwitchReg.Count) {
            write-debug "$($ToggleSwitchReg.Name) is true (count: $count)"
            return $true
        } else {
            write-debug "$($ToggleSwitchReg.Name) is false (count: $count)"
            return $false
        }
    } else {
        return $false
    }
}
