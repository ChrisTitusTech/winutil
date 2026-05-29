function Set-WinUtilRegistry ($Name, $Path, $Type, $Value {
    if (-not (Get-PSDrive -Name HKU)) {
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
    }

    if (-not (Test-Path $Path)) {
        Write-Host "$Path was not found. Creating..."
        New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
    }

    if ($Value -ne "<RemoveEntry>") {
        Write-Host "Set $Path\$Name to $Value"
        Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -Force -ErrorAction Stop | Out-Null
    } else {
        Write-Host "Remove $Path\$Name"
        Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop | Out-Null
    }
}
