Get-ChildItem @(
    "C:\Windows\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package*.mum",
    "C:\Windows\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package*.mum"
) | ForEach-Object { dism.exe /online /norestart /add-package:"$_" }