Function Invoke-WinUtilCurrentSystem {

    <#

        .DESCRIPTION
        Function is meant to read existing system registry and check according configuration.

        Example: Is telemetry enabled? check the box.

        .EXAMPLE

        Get-WinUtilCheckBoxes "WPFInstall"

    #>

    param(
        $CheckBox
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

        if(!(Test-Path 'HKU:\')){New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS}

        $sync.configs.tweaks | Get-Member -MemberType NoteProperty | ForEach-Object {

            $registryKeys = $sync.configs.tweaks.$($psitem.name).registry
        
            Foreach ($tweaks in $registryKeys){
                $Values = @()
                Foreach($tweak in $tweaks){
        
                    if(test-path $tweak.Path){
                        $actualValue = Get-ItemProperty -Name $tweak.Name -Path $tweak.Path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $($tweak.Name)
                        $expectedValue = $tweak.Value
                        if ($expectedValue -ne $actualValue){
                            $values += $False
                        }
                    }
                }
            }
            if($values -notcontains $false){
                Write-Output $psitem.Name
            }
        }
    }
}

