function Invoke-WinUtilBingSearch {
    <#

    .SYNOPSIS
        Disables/Enables Bing Search

    .PARAMETER Enabled
        Indicates whether to enable or disable Bing Search

    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Enabling Bing Search"
            $value = 1
        }
        else {
            Write-Host "Disabling Bing Search"
            $value = 0
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        Set-ItemProperty -Path $Path -Name BingSearchEnabled -Value $value
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