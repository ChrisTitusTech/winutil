function Remove-WinUtilAPPX {
    <#
    
        .DESCRIPTION
        This function will remove any of the provided APPX names

        .EXAMPLE

        Remove-WinUtilAPPX -Name "Microsoft.Microsoft3DViewer"
    
    #>
    param (
        $Name
    )

    Try{
        Write-Host "Removing $Name"
        Get-AppxPackage "*$Name*" | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$Name*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    Catch [System.Exception] {
        if($psitem.Exception.Message -like "*The requested operation requires elevation*"){
            Write-Warning "Unable to uninstall $name due to a Security Exception"
        }
        Else{
            Write-Warning "Unable to uninstall $name due to unhandled exception"
            Write-Warning $psitem.Exception.StackTrace 
        }
    }
    Catch{
        Write-Warning "Unable to uninstall $name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace 
    }
}