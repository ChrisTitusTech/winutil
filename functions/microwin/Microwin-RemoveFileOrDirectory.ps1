function Microwin-RemoveFileOrDirectory([string]$pathToDelete, [string]$mask = "", [switch]$Directory = $false) {
    if(([string]::IsNullOrEmpty($pathToDelete))) { return }
    if (-not (Test-Path -Path "$($pathToDelete)")) { return }

    $yesNo = Get-LocalizedYesNo
    Write-Host "[INFO] In Your local takeown expects '$($yesNo[0])' as a Yes answer."

    $itemsToDelete = [System.Collections.ArrayList]::new()

    if ($mask -eq "") {
        Write-Debug "Adding $($pathToDelete) to array."
        [void]$itemsToDelete.Add($pathToDelete)
    } else {
        Write-Debug "Adding $($pathToDelete) to array and mask is $($mask)"
        if ($Directory) { $itemsToDelete = Get-ChildItem $pathToDelete -Include $mask -Recurse -Directory } else { $itemsToDelete = Get-ChildItem $pathToDelete -Include $mask -Recurse }
    }

    foreach($itemToDelete in $itemsToDelete) {
        $status = "Deleting $($itemToDelete)"
        Write-Progress -Activity "Removing Items" -Status $status -PercentComplete ($counter++/$itemsToDelete.Count*100)

        if (Test-Path -Path "$($itemToDelete)" -PathType Container) {
            $status = "Deleting directory: $($itemToDelete)"

            takeown /r /d $yesNo[0] /a /f "$($itemToDelete)"
            icacls "$($itemToDelete)" /q /c /t /reset
            icacls $itemToDelete /setowner "*S-1-5-32-544"
            icacls $itemToDelete /grant "*S-1-5-32-544:(OI)(CI)F" /t /c /q
            Remove-Item -Force -Recurse "$($itemToDelete)"
        }
        elseif (Test-Path -Path "$($itemToDelete)" -PathType Leaf) {
            $status = "Deleting file: $($itemToDelete)"

            takeown /a /f "$($itemToDelete)"
            icacls "$($itemToDelete)" /q /c /t /reset
            icacls "$($itemToDelete)" /setowner "*S-1-5-32-544"
            icacls "$($itemToDelete)" /grant "*S-1-5-32-544:(OI)(CI)F" /t /c /q
            Remove-Item -Force "$($itemToDelete)"
        }
    }
    Write-Progress -Activity "Removing Items" -Status "Ready" -Completed
}
