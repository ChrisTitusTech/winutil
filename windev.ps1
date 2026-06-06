# Runs winutil from local source (dev build)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $scriptRoot
try {
    & (Join-Path $scriptRoot 'Compile.ps1')
    & (Join-Path $scriptRoot 'winutil.ps1') @args
}
finally {
    Pop-Location
}