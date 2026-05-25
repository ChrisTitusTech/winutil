function Invoke-WinUtilISODrivers ($Index) {
    $wimPath = "Source\sources\install.wim"
    $esdPath = "Source\sources\install.esd"

    if (-not (Test-Path $wimPath)) {
        Export-WindowsImage -SourceImagePath $esdPath -SourceIndex $Index -DestinationImagePath $wimPath -CompressionType Fast
    }


    $exportPath = "$env:TEMP\drivers"

    if (Test-Path $exportPath) {
        Remove-Item $exportPath -Recurse -Force
    }

    Export-WindowsDriver -Online -Destination $exportPath

    $mount = "$env:TEMP\wim_$Index"

    if (Test-Path $mount) {
        Remove-Item $mount -Recurse -Force
    }

    Mount-WindowsImage -ImagePath $wimPath -Index $Index -Path $mount

    Add-WindowsDriver -Path $mount -Driver $exportPath -Recurse

    Dismount-WindowsImage -Path $mount -Save

    Remove-Item $mount -Recurse -Force
}
