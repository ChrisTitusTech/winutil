Function Invoke-WinUtilWingetProgram {
    <#
    .SYNOPSIS
    Runs the designated action on the provided programs using Winget

    .PARAMETER Programs
    A list of programs to process

    .PARAMETER action
    The action to perform on the programs, can be either 'Install' or 'Uninstall'

    .NOTES
    The triple quotes are required any time you need a " in a normal script block.
    The winget Return codes are documented here: https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-actionr/winget/returnCodes.md
    #>

    param(
        [Parameter(Mandatory, Position=0)]
        $Programs,
        
        [Parameter(Mandatory, Position=1)]
        [ValidateSet("Install", "Uninstall")]
        [String]$Action
    )

    Function Invoke-Winget {
    <#
    .SYNOPSIS
    Invokes the winget.exe with the provided arguments and return the exit code

    .PARAMETER wingetId
    The Id of the Program that Winget should Install/Uninstall

    .PARAMETER scope
    Determines the installation mode. Can be "user" or "machine" (For more info look at the winget documentation)

    .PARAMETER credential
    The PSCredential Object of the user that should be used to run winget
    
    .NOTES
    Invoke Winget uses the public variable $Action defined outside the function to determine if a Program should be installed or removed
    #>
        param (
            [string]$wingetId,
            [string]$scope = "",
            [PScredential]$credential = $null
        )

        $commonArguments = "--id $wingetId --silent"
        $arguments = if ($Action -eq "Install"){
            "install $commonArguments --accept-source-agreements --accept-package-agreements $(if ($scope) {" --scope $scope"})" 
        }
        else {
            "uninstall $commonArguments"
        }

        $processParams = @{
            FilePath = "winget"
            ArgumentList = $arguments
            Wait = $true
            PassThru = $true
            NoNewWindow = $true
        }

        if ($credential) {
            $processParams.credential = $credential
        }
        
        return (Start-Process @processParams).ExitCode           
    }

    Function Invoke-Install {
    <#
    .SYNOPSIS
    Contains the Install Logic and return code handling from winget
    
    .PARAMETER Program
    The Winget ID of the Program that should be installed
    #>
        param (
            [string]$Program
        )
        $status = Invoke-Winget -wingetId $Program
        if ($status -eq 0) {
            Write-Host "$($Program) installed successfully."
            return $true
        } elseif ($status -eq -1978335189) {
            Write-Host "$($Program) No applicable update found"
            return $true
        }

        Write-Host "Attempt installation of $($Program) with User scope"
        $status = Invoke-Winget -wingetId $Program -scope "user"
        if ($status -eq 0) {
            Write-Host "$($Program) installed successfully with User scope."
            return $true
        } elseif ($status -eq -1978335189) {
            Write-Host "$($Program) No applicable update found"
            return $true
        }

        $userChoice = [System.Windows.MessageBox]::Show("Do you want to attempt $($Program) installation with specific user credentials? Select 'Yes' to proceed or 'No' to skip.", "User credential Prompt", [System.Windows.MessageBoxButton]::YesNo)
        if ($userChoice -eq 'Yes') {
            $getcreds = Get-Credential
            $status = Invoke-Winget -wingetId $Program -credential $getcreds
            if ($status -eq 0) {
                Write-Host "$($Program) installed successfully with User prompt."
                return $true
            }
        } else {
            Write-Host "Skipping installation with specific user credentials."
        }

        Write-Host "Failed to install $($Program)."
        return $false
    }

    Function Invoke-Uninstall {
        <#
        .SYNOPSIS
        Contains the Uninstall Logic and return code handling from winget
        
        .PARAMETER Program
        The Winget ID of the Program that should be uninstalled
        #>
        param (
            [psobject]$Program
        )
        
        try {
            $status = Invoke-Winget -wingetId $Program
            if ($status -eq 0) {
                Write-Host "$($Program) uninstalled successfully."
                return $true
            } else {
                Write-Host "Failed to uninstall $($Program)."
                return $false
            }
        } catch {
            Write-Host "Failed to uninstall $($Program) due to an error: $_"
            return $false
        }
    }

    $count = $Programs.Count
    $failedPackages = @()
    
    Write-Host "==========================================="
    Write-Host "--    Configuring winget packages       ---"
    Write-Host "==========================================="
    
    for ($i = 0; $i -lt $count; $i++) {
        $Program = $Programs[$i]
        $result = $false
        Set-WinUtilProgressBar -label "$Action $($Program)" -percent ($i / $count * 100)
        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($i / $count)})
        
        $result = switch ($Action) {
            "Install" {Invoke-Install -Program $Program}
            "Uninstall" {Invoke-Uninstall -Program $Program}
            default {throw "[Install-WinUtilProgramWinget] Invalid action: $Action"}    
        }

        if (-not $result) {
            $failedPackages += $Program
        }
    }

    Set-WinUtilProgressBar -label "$($Action)ation done" -percent 100
    return $failedPackages
}
