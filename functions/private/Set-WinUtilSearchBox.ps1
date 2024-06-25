function Set-WinUtilSearchBox {
    <#

    .SYNOPSIS
        Sets the Search Box to the type selected

    .PARAMETER SearchBox
        The Search Box Icon to set it to

    #>
    param($SearchBox)
    Try{
        if ($SearchBox -eq $Icon){
            Write-Host "Setting Search Box to an Icon"
            $value = 1
        }
        elseif ($SearchBox -eq $Hidden) {
            Write-Host "Setting Search Box to be Hidden"
            $value = 0
        }
        elseif ($SearchBox -eq $Box) {
            Write-Host "Setting Search Box to be a Box"
            $value = 2
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        Set-ItemProperty -Path $Path -Name SearchboxTaskbarMode -Value $value
    }
    Catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    }
    Catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    }
    Catch{
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}
