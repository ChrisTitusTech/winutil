Get-ChildItem @(
    "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package*.mum",
    "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package*.mum"
) | ForEach-Object { dism.exe /online /norestart /add-package:"$_" }
