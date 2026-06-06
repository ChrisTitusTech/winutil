function Test-WinUtilIsServiceNotFoundException {
    param(
        $Exception
    )

    if ($null -eq $Exception) {
        return $false
    }

    if ($Exception.GetType().FullName -eq 'System.ServiceProcess.ServiceNotFoundException') {
        return $true
    }

    if ($Exception.Message -match '(?i)cannot find any service|service .* was not found|service not found') {
        return $true
    }

    return $false
}