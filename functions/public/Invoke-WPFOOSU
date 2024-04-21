function Invoke-WPFOOSU {
    <#
    .SYNOPSIS
        Downloads and runs OO Shutup 10 with or without config files
    .PARAMETER action
        Specifies how OOSU should be started
        customize:      Opens the OOSU GUI
        recommended:    Loads and applies the recommended OOSU policies silently
        undo:           Resets all policies to factory silently
    #>

    param (
        [ValidateSet("customize", "recommended", "undo")]
        [string]$action
    )

    $OOSU_filepath = "$ENV:temp\OOSU10.exe"

    $Initial_ProgressPreference = $ProgressPreference
    $ProgressPreference = "SilentlyContinue" # Disables the Progress Bar to drasticly speed up Invoke-WebRequest
    Invoke-WebRequest -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $OOSU_filepath

    switch ($action) 
    {
        "customize"{
            Write-Host "Starting OO Shutup 10 ..."
            Start-Process $OOSU_filepath
        }
        "recommended"{
            $oosu_config = "$ENV:temp\ooshutup10_recommended.cfg"
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/config/ooshutup10_recommended.cfg" -OutFile $oosu_config
            Write-Host "Applying recommended OO Shutup 10 Policies"
            Start-Process $OOSU_filepath -ArgumentList "$oosu_config /quiet" -Wait
        }
        "undo"{
            $oosu_config = "$ENV:temp\ooshutup10_factory.cfg"
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ChrisTitusTech/winutil/main/config/ooshutup10_factory.cfg" -OutFile $oosu_config
            Write-Host "Resetting all OO Shutup 10 Policies"
            Start-Process $OOSU_filepath -ArgumentList "$oosu_config /quiet" -Wait
        }
    }
    $ProgressPreference = $Initial_ProgressPreference
}
