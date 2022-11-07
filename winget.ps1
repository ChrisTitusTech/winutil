Find-PackageProvider -Name 'Nuget' -ForceBootstrap -IncludeDependencies
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Script -Name winget-install -Force
winget-install.ps1
