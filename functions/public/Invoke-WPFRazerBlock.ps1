function Invoke-WPFRazerBlock {
    <#
    .SYNOPSIS
        Blocks razer software automatic install.
    .DESCRIPTION
        It disables the automatic driver installation and denies write permission of razer folder to system which prevents the automatic install.
    #>
    $RazerPath = "C:\Windows\Installer\Razer"

    # Disable driver auto-install via registry
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer" -Name "DisableCoInstallers" -Type DWord -Value 1

    # Remove and lock install directory
    Remove-Item $RazerPath -Recurse -Force
    New-Item -Path "C:\Windows\Installer\" -Name "Razer" -ItemType "directory"
    $Acl = Get-Acl $RazerPath
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\SYSTEM", "Write", "ContainerInherit,ObjectInherit", "None", "Deny")

    $Acl.SetAccessRule($Ar)
    Set-Acl $RazerPath $Acl
}
