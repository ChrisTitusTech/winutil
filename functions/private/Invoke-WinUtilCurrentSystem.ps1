Function Invoke-WinUtilCurrentSystem {

    <#

        .DESCRIPTION
        Function is meant to read existing system registry and check according configuration.

        Example: Is telemetry enabled? check the box.

        .EXAMPLE

        Get-WinUtilCheckBoxes "WPFInstall"

    #>

    param(
        $CheckBox,
        $undo = $false
    )

    if ($checkbox -eq "winget"){

        $originalEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
        $Sync.InstalledPrograms = winget list -s winget | Select-Object -skip 3 | ConvertFrom-String -PropertyNames "Name", "Id", "Version", "Available" -Delimiter '\s{2,}'
        [Console]::OutputEncoding = $originalEncoding

        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object {$psitem -like "WPFInstall*"}
        $sync.GetEnumerator() | Where-Object {$psitem.Key -in $filter} | ForEach-Object {
            if($sync.configs.applications.$($psitem.Key).winget -in $sync.InstalledPrograms.Id){
                Write-Output $psitem.name
            }
        }
    }
    if($CheckBox -eq "tweaks"){
        if($sync.configs.tweaks.$CheckBox.registry){
            $sync.configs.tweaks.$CheckBox.registry | ForEach-Object {
                Get-WinUtilRegistry -Name $psitem.Name -Path $psitem.Path -Type $psitem.Type -Value $psitem.$($values.registry)
                if ($psitem.$($values.registry) -eq $syscheckvalue) {
                    $sync.configs.tweaks.$CheckBox.$($values.registry) = $true
                }
                else {
                    $sync.configs.tweaks.$CheckBox.$($values.registry) = $false
                }
            }
        }
    }


}

