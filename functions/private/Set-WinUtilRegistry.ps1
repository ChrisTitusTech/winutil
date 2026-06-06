function Set-WinUtilRegistry {
    <#

    .SYNOPSIS
        Modifies the registry based on the given inputs

    .PARAMETER Name
        The name of the key to modify

    .PARAMETER Path
        The path to the key

    .PARAMETER Type
        The type of value to set the key to

    .PARAMETER Value
        The value to set the key to

    .EXAMPLE
        Set-WinUtilRegistry -Name "PublishUserActivities" -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Type "DWord" -Value "0"

    #>
    param (
        $Name,
        $Path,
        $Type,
        $Value
    )

    try {
        if(!(Test-Path 'HKU:\')) {New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS}

        If (!(Test-Path $Path)) {
            Write-Host "$Path was not found. Creating..."
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }

        if ($Value -ne "<RemoveEntry>") {
            $resolvedValue = switch ($Type) {
                'DWord' { ConvertTo-WinUtilRegistryNumericValue -Value $Value -NumericType 'DWord' }
                'QWord' { ConvertTo-WinUtilRegistryNumericValue -Value $Value -NumericType 'QWord' }
                default { $Value }
            }

            $currentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
            if (Test-WinUtilRegistryValueMatch -CurrentValue $currentValue -ExpectedValue $resolvedValue -Type $Type) {
                Write-Host "Skip $Path\$Name - already set to $resolvedValue"
                return
            }

            Write-Host "Set $Path\$Name to $resolvedValue"
            Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $resolvedValue -Force -ErrorAction Stop | Out-Null
        }
        else {
            Write-Host "Remove $Path\$Name"
            if (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop | Out-Null
            } else {
                Write-Host "$Path\$Name does not exist, skipping remove."
            }
        }
    } catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception."
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    } catch [System.UnauthorizedAccessException] {
       Write-Warning $psitem.Exception.Message
    } catch {
        Write-Warning "Unable to set $Name due to unhandled exception."
        Write-Warning $psitem.Exception.Message
    }
}
