Stop-Process -Name "msedge"
Stop-Process -Name "widgets"

#Creating a variable to the necessary file path
$filePath = "C:\Windows\System32\IntegratedServicesRegionPolicySet.json"

#Getting current ACL for the file path
$acl = Get-Acl -Path $filePath

# Defining the new permission rule
$permission = "Everyone", "FullControl", "Allow"

# Creating the new access rule
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission

# Add the new access rule to the ACL
$acl.AddAccessRule($accessRule)

# Apply the updated ACL to the file
Set-Acl -Path $filePath -AclObject $acl

# Read all lines from the file
$lines = Get-Content -Path $filePath
#Goes to line 8 of the json file and replaces disabled with enabled for Edge is uninstallable
$lines[7] = $lines[7] -replace 'disabled', 'enabled'


# Defining the registry path and value name
$registryPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
$valueName = "NoRemove"
Set-ItemProperty -Path $registryPath -Name $valueName -Value 0
Write-Output "The registry value '$valueName' has been updated from 1 to 0."


# Credit to Sander Holvoet (finding edge version folder to access setup.exe)
$EdgeVersion = (Get-AppxPackage "Microsoft.MicrosoftEdge.Stable" -AllUsers).Version
$EdgeSetupPath = ${env:ProgramFiles(x86)} + '\Microsoft\Edge\Application\' + $EdgeVersion + '\Installer\setup.exe'
& $EdgeSetupPath  --uninstall --msedge --channel=stable --system-level --verbose-logging